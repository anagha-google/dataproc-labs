/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

data "google_project" "project" {
  project_id = var.project_id
}

locals {
  _project_number = data.google_project.project.number
}


locals {
  dpgce_spark_sphs_nm         = "dpgce-sphs-${local._project_number}"
  dpgce_cluster_nm            = "dpgce-cluster-static-${local._project_number}"
  umsa_sphs                   = "dpsphs-lab-sa"
  umsa_sphs_fqn               = "${local.umsa}@${var.project_id}.iam.gserviceaccount.com"
  umsa                        = "dpgce-lab-sa"
  umsa_fqn                    = "${local.umsa}@${var.project_id}.iam.gserviceaccount.com"
  dpgce_spark_bucket          = "dpgce-spark-bucket-${local._project_number}"
  dpgce_spark_bucket_fqn      = "gs://dpgce-spark-${local._project_number}"
  dpgce_spark_sphs_bucket     = "dpgce-sphs-${local._project_number}"
  dpgce_spark_sphs_bucket_fqn = "gs://dpgce-sphs-${local._project_number}"
}

###################################################################################
# Resource for Network Creation                                                    #
# The project was not created with the default network.                            #
# This creates just the network/subnets we need...                                 #
####################################################################################
resource "google_compute_network" "default_network" {
  project                 = var.project_id
  name                    = var.network_name
  description             = "Default network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

####################################################################################
# Resource for Subnet                                                              #
#This creates just the subnets we need                                             #
####################################################################################

resource "google_compute_subnetwork" "dataproc_subnet" {
  project       = var.project_id
  name          =  var.subnetwork_name
  ip_cidr_range = var.ip_range
  region        = var.location
  network       = google_compute_network.default_network.id
  depends_on = [
    google_compute_network.default_network
  ]
}

####################################################################################
# Resource for Firewall rule                                                       #
####################################################################################

resource "google_compute_firewall" "allow_intra_snet_ingress_to_any" {
  project   = var.project_id 
  name      = "allow-intra-snet-ingress-to-any"
  network = google_compute_network.default_network.id
  direction = "INGRESS"
  source_ranges = [var.ip_range]
  allow {
    protocol = "all"
  }
  description        = "Creates firewall rule to allow ingress from within Spark subnet on all ports, all protocols"
  depends_on = [
    google_compute_subnetwork.dataproc_subnet
  ]
}

resource "time_sleep" "sleep_after_network_and_firewall_creation" {
  create_duration = "120s"
  depends_on = [
    google_compute_firewall.allow_intra_snet_ingress_to_any
  ]
}


#####################################################################
#RESOURCE FOR SERVICE_ACCOUNT CREATION                              #
#ALLOWS MANAGEMENT OF A GOOGLE CLOUD SERVICE ACCOUNT.               #
#####################################################################

resource "google_service_account" "serviceone_service_account" {
  project      = var.project_id
  account_id   = var.serviceone
  display_name = "Service One User Service Account"
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation
  ]
}

resource "google_service_account" "servicetwo_service_account" {
  project      = var.project_id
  account_id   = var.servicetwo
  display_name = "Service Two User Service Account"
  depends_on = [
      time_sleep.sleep_after_network_and_firewall_creation
  ]
}

###########################################################
#Creates a Bucket in cloud storage in project             #
# and set's permissions for only the service one account  #
###########################################################

resource "google_storage_bucket" "storage_bucket_name" {
  project                     = var.project_id
  name                        = format("%s-%s", var.bucket_name, local._project_number)
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "bucket_iam" {
  bucket = format("%s-%s", var.bucket_name, local._project_number)
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.serviceone}@${var.project_id}.iam.gserviceaccount.com"
  depends_on = [
    google_storage_bucket.storage_bucket_name,
    google_service_account.serviceone_service_account
  ]
}

###########################################################
#Create IAM rules for impersonation                      #
###########################################################

resource "google_service_account_iam_member" "serviceone_account_impersonation" {
  service_account_id ="projects/${var.project_id}/serviceAccounts/${var.serviceone}@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:${var.userone}@${var.org_name}"
  depends_on         = [ google_service_account.serviceone_service_account ]
}

resource "google_service_account_iam_member" "servicetwo_account_impersonation" {
  service_account_id ="projects/${var.project_id}/serviceAccounts/${var.servicetwo}@${var.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:${var.usertwo}@${var.org_name}"
  depends_on         = [ google_service_account.servicetwo_service_account ]
}

###########################################################
#Set roles for users and service accounts                 #
###########################################################

resource "google_project_iam_member" "userone_privs" {
  for_each = toset([
    "roles/editor",
    "roles/dataproc.worker"
  ])
  project  = var.project_id
  role     = each.key
  member   = "user:${var.userone}@${var.org_name}"
  depends_on = [
    google_service_account_iam_member.serviceone_account_impersonation  ]
}

resource "google_project_iam_member" "usertwo_privs" {
  for_each = toset([
    "roles/editor",
    "roles/dataproc.worker"
  ])
  project  = var.project_id
  role     = each.key
  member   = "user:${var.usertwo}@${var.org_name}"
  depends_on = [
    google_service_account_iam_member.serviceone_account_impersonation  ]
}

resource "google_project_iam_member" "serviceone_privs" {
  for_each = toset([
"roles/dataproc.editor",
  ])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${var.serviceone}@${var.project_id}.iam.gserviceaccount.com"
  depends_on = [
    google_service_account.serviceone_service_account  ]
}

resource "google_project_iam_member" "servicetwo_privs" {
  for_each = toset([
"roles/dataproc.editor",
  ])
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${var.servicetwo}@${var.project_id}.iam.gserviceaccount.com"
  depends_on = [
    google_service_account.servicetwo_service_account
  ]
}

###########################################################
#Create a user managed service account for Dataproc       #
#  and assign necessary roles.                            #
###########################################################


module "umsa_creation" {
  source     = "terraform-google-modules/service-accounts/google"
  project_id = var.project_id
  names      = ["${local.umsa}"]
  display_name = "User Managed Service Account"
  description  = "User Managed Service Account for Spark History Server"

}

module "umsa_role_grants" {
  source                  = "terraform-google-modules/iam/google//modules/member_iam"
  service_account_address = "${local.umsa_fqn}"
  prefix                  = "serviceAccount"
  project_id              = var.project_id
  project_roles = [
    
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/storage.objectViewer",
    "roles/storage.admin",
    "roles/dataproc.worker",
    "roles/dataproc.admin"
  ]
  depends_on = [
    module.umsa_creation
  ]
}

###########################################################
#Create Dataproc Spark History Server and Bucket          #
###########################################################

resource "google_storage_bucket" "dpgce_spark_sphs_bucket" {
  project                     = var.project_id
  name                        = local.dpgce_spark_sphs_bucket
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "bucket_iam_sphs_bucket" {
  bucket = local.dpgce_spark_sphs_bucket
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${var.serviceone}@${var.project_id}.iam.gserviceaccount.com",
    "serviceAccount:${var.servicetwo}@${var.project_id}.iam.gserviceaccount.com"
    ]
  depends_on = [
    google_storage_bucket.dpgce_spark_sphs_bucket,
    google_service_account.serviceone_service_account,
    google_service_account.servicetwo_service_account
  ]
}

resource "google_dataproc_cluster" "sphs_creation" {
  provider = google-beta
  name     = local.dpgce_spark_sphs_nm
  region   = var.location

  cluster_config {
    
    endpoint_config {
        enable_http_port_access = true
    }

    staging_bucket = local.dpgce_spark_bucket
    
    # Override or set some custom properties
    software_config {
      image_version = "2.0"
      override_properties = {
        "dataproc:dataproc.allow.zero.workers"=true
        "dataproc:job.history.to-gcs.enabled"=true
        "spark:spark.history.fs.logDirectory"="${local.dpgce_spark_sphs_bucket_fqn}/*/spark-job-history"
        "spark:spark.eventLog.dir"="${local.dpgce_spark_sphs_bucket_fqn}/events/spark-job-history"
        "mapred:mapreduce.jobhistory.read-only.dir-pattern"="${local.dpgce_spark_sphs_bucket_fqn}/*/mapreduce-job-history/done"
        "mapred:mapreduce.jobhistory.done-dir"="${local.dpgce_spark_sphs_bucket_fqn}/events/mapreduce-job-history/done"
        "mapred:mapreduce.jobhistory.intermediate-done-dir"="${local.dpgce_spark_sphs_bucket_fqn}/events/mapreduce-job-history/intermediate-done"
        "yarn:yarn.nodemanager.remote-app-log-dir"="${local.dpgce_spark_sphs_bucket_fqn}/yarn-logs"
      }      
    }
    gce_cluster_config {
      subnetwork =  google_compute_subnetwork.dataproc_subnet.id
      service_account = local.umsa_sphs_fqn
      service_account_scopes = [
        "cloud-platform"
      ]
    }
  }
  depends_on = [
    time_sleep.sleep_after_network_and_firewall_creation,
    module.umsa_role_grants,
    google_storage_bucket_iam_binding.bucket_iam_sphs_bucket
  ]  
}

###########################################################
#Create Dataproc Multi-Tenancy Cluster and Bucket         #
#  gcloud is used for creating the cluster as creating    #
#  a multi-tenancy dataproc cluster with terraform is     #
#  not supported at present.                              #
 ##########################################################

resource "google_storage_bucket" "dpgce_spark_bucket" {
  project                     = var.project_id
  name                        = local.dpgce_spark_bucket
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "bucket_iam_spark_bucket" {
  bucket = local.dpgce_spark_bucket
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${var.serviceone}@${var.project_id}.iam.gserviceaccount.com",
    "serviceAccount:${var.servicetwo}@${var.project_id}.iam.gserviceaccount.com"
  ]
  depends_on = [
    google_storage_bucket.dpgce_spark_bucket,
    google_service_account.serviceone_service_account,
    google_service_account.servicetwo_service_account
    ]
}

resource "null_resource" "dataproc_cluster_v2" {
  provisioner "local-exec" {
    command = <<-EOT
    gcloud dataproc clusters create ${local.dpgce_cluster_nm} \
      --region=us-central1 --project=${var.project_id}  \
      --image-version=2.1-debian11 --subnet=${var.subnetwork_name} \
      --service-account=${local.umsa_fqn} \
      --secure-multi-tenancy-user-mapping="${var.userone}@${var.org_name}:${var.serviceone}@${var.project_id}.iam.gserviceaccount.com,${var.usertwo}@${var.org_name}:${var.servicetwo}@${var.project_id}.iam.gserviceaccount.com" \
      --properties spark:spark.history.fs.logDirectory=${local.dpgce_spark_sphs_bucket_fqn}/*/spark-job-history \
      --properties spark:spark.eventLog.dir=${local.dpgce_spark_sphs_bucket_fqn}/events/spark-job-history \
      --properties mapred:mapreduce.jobhistory.read-only.dir-pattern=${local.dpgce_spark_sphs_bucket_fqn}/*/mapreduce-job-history/done \
      --properties mapred:mapreduce.jobhistory.done-dir=${local.dpgce_spark_sphs_bucket_fqn}/events/mapreduce-job-history/done \
      --properties mapred:mapreduce.jobhistory.intermediate-done-dir=${local.dpgce_spark_sphs_bucket_fqn}/events/mapreduce-job-history/intermediate-done \
      --properties yarn:yarn.nodemanager.remote-app-log-dir=${local.dpgce_spark_sphs_bucket_fqn}/yarn-logs \
      --properties dataproc:dataproc.logging.stackdriver.enable=true \
      --properties dataproc:dataproc.monitoring.stackdriver.enable=true \
      --properties yarn:yarn.log-aggregation.enabled=true \
      --properties dataproc:dataproc.logging.stackdriver.job.yarn.container.enable=true \
      --properties dataproc:jobs.file-backed-output.enable=true \
      --properties dataproc:dataproc.logging.stackdriver.job.driver.enable=true

EOT
}
  depends_on = [
    time_sleep.sleep_after_network_and_firewall_creation,
    module.umsa_role_grants,
    google_storage_bucket_iam_binding.bucket_iam_spark_bucket
    ]
}
