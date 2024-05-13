variable "project_id" {
  type        = string
  description = "project id required"
}

variable "userone" {
  description = "userone username"
}

variable "usertwo" {
  description = "usertwo username"
}

variable "serviceone" {
  description = "serviceone username"
}

variable "servicetwo" {
  description = "servicetwo username"
}

variable "org_name" {
  description = "organization id"
}

variable "location" {
 description = "Location/region to be used"
 default = "us-central1"
}

variable "zone" {
  description = "default zone"
  default = "us-central1-a"
}

variable "ip_range" {
 description = "IP Range used for the network for this demo"
 default = "10.6.0.0/24"
}

variable "network_name" {
  description = "default network"
  default = "default"
}

variable "subnetwork_name" {
  description = "default subnetwork"
  default = "default"
}

variable "bucket_name" {
  description = "default bucket"
  default = "dataproc_mt_bucket"
}


