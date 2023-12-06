# Module-01: Infrastructure provisioning

In this module we will create the infrastructure for the lab with Terraform. <br>


<hr>

## 1. About 

### 1.1. Duration
It takes ~1.5 hours to complete and is fully scrpited, including with Terraform for provisioning.

### 1.2. Resources provisioned


### 1.3. Prerequisites
A pre-created project
You need to have organization admin rights, and project owner privileges or work with privileged users to complete provisioning.

### 1.4. Platform for provisioning

Your machine, or preferably Cloud Shell.


<hr>

## 2. Foundational resources provisioning with Terraform

In this section we will enable the requisite Google APIs and update organizational policies with Terraform.<br>
Takes approximately 5 minutes to complete.

### 2.1. Clone this repo in Cloud Shell

```
git clone https://github.com/anagha-google/dataproc-labs.git
```

### 2.2. Run Terraform

The Terraform in this section updates organization policies and enables Google APIs.

Paste this in Cloud Shell
```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`

cd ~/dataproc-labs/4-dataproc-with-gpu/provisioning-automation/foundations-tf
```

Run the Terraform for organization policy edits and enabling Google APIs
```
terraform init
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -auto-approve >> 4-dataproc-with-gpu-tf-foundations.output
```

Wait till the provisioning completes - ~5 minutes. <br>

In a separate cloud shell tab, you can tail the output file for execution state through completion-
```
tail -f  ~/dataproc-labs/4-dataproc-with-gpu/provisioning-automation/foundations-tf/4-dataproc-with-gpu-tf-foundations.output
```

<hr>

## 3. Core resources provisioning automation with Terraform

This section provisions all the requisite core data services for the lab, and their dependecies.

### 3.1. Resources provisioned
In this section, we will provision-

1. Network, subnet, firewall rule
2. Storage buckets for code, datasets, and for use with the services
3. Persistent Spark History Server
4. Cloud Composer 2
5. User Managed Service Account
6. Requisite IAM permissions
7. Copy of code, notebooks, data, etc into buckets
8. Import of Airflow DAG
9. Configuration of Airflow variables

### 3.2. Run the terraform scripts
Paste this in Cloud Shell after editing the GCP region variable to match your nearest region-

```
cd ~/dataproc-labs/4-dataproc-with-gpu/provisioning-automation/core-tf/terraform

PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
PROJECT_NAME=`gcloud projects describe ${PROJECT_ID} | grep name | cut -d':' -f2 | xargs`
GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
GCP_REGION="us-central1"
DEPLOYER_ACCOUNT_NAME=$GCP_ACCOUNT_NAME
ORG_ID=`gcloud organizations list --format="value(name)"`
CC2_IMAGE_VERSION="composer-2.0.11-airflow-2.2.3"

Run the Terraform for provisioning the rest of the environment
terraform init
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -var="project_name=${PROJECT_NAME}" \
  -var="project_number=${PROJECT_NBR}" \
  -var="gcp_account_name=${GCP_ACCOUNT_NAME}" \
  -var="deployment_service_account_name=${DEPLOYER_ACCOUNT_NAME}" \
  -var="org_id=${ORG_ID}" \
  -var="cloud_composer_image_version=${CC2_IMAGE_VERSION}" \
  -var="gcp_region=${GCP_REGION}" \
  -auto-approve >> 4-dataproc-with-gpu-tf-core.output
```
  
Takes ~50 minutes to complete.<br> 


In a separate cloud shell tab, you can tail the output file for execution state through completion-

```
tail -f ~/dataproc-labs/4-dataproc-with-gpu/provisioning-automation/core-tf/terraform/4-dataproc-with-gpu-tf-core.output
```

<hr>

## 1. Declare variables

Paste in Cloud Shell-
```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`

CLUSTER_NAME=dpgce-cluster-static-gpu-${PROJECT_NBR}
DPGCE_LOG_BUCKET=dpgce-cluster-static-gpu-${PROJECT_NBR}-logs
DATA_BUCKET=spark-rapids-lab-data-${PROJECT_NBR}
CODE_BUCKET=spark-rapids-lab-code-${PROJECT_NBR}
VPC_NM=VPC=dpgce-vpc-$PROJECT_NBR
SPARK_SUBNET=spark-snet
PERSISTENT_HISTORY_SERVER_NM=dpgce-sphs-${PROJECT_NBR}
UMSA_FQN=dpgce-lab-sa@$PROJECT_ID.iam.gserviceaccount.com
REGION=us-central1
ZONE=us-central1-a
NUM_GPUS=1
NUM_WORKERS=4

```

<hr>

## 2. Create Cloud Storage buckets & load upload dataset & scripts for the lab

### 2.1. Create a bucket for Dataproc logs

Paste in Cloud Shell-
```
gcloud storage buckets create gs://$DPGCE_LOG_BUCKET --project=$PROJECT_ID --location=$REGION
```

### 2.2. Create a bucket for the dataset & upload lab data to it

Paste in Cloud Shell-
```
gcloud storage buckets create gs://$DATA_BUCKET --project=$PROJECT_ID --location=$REGION
```

You would have already cloned the repo. Lets navigate to the lab directory and upload the data.

Paste in Cloud Shell-
```
cd ~/dataproc-labs/5-dataproc-gce-with-gpu/01-datasets/
gsutil cp *.csv gs://$DATA_BUCKET/churn/input/
```

## 2.3. Create an archive with the requisite scripts

Paste in Cloud Shell-
```
cd ~/dataproc-labs/5-dataproc-gce-with-gpu/00-scripts
rm -rf aux_etl_code_archive.zip
zip aux_etl_code_archive.zip -r churn_utils
```

### 2.4. Create a bucket for the scripts & upload lab scripts to it

Paste in Cloud Shell-
```
gcloud storage buckets create gs://$CODE_BUCKET --project=$PROJECT_ID --location=$REGION
```

You would have already cloned the repo. Lets navigate to the lab directory and upload the data.

Paste in Cloud Shell-
```
cd ~/dataproc-labs/5-dataproc-gce-with-gpu/00-scripts/
gsutil cp -r * gs://$CODE_BUCKET/churn/
```

<hr>


<hr>
