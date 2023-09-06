# BYO Jupyter infrastructure with Dataproc for Spark compute

## A. About the lab

### A.1. Abstract
This lab demonstrates how to use the Dataproc Jupyter plugin for bring your own Jupyter infrastructure with Dataproc Spark on GCE or Dataproc Spark Serverless with a minimum viable sample.

<br>

<hr>

### A.2. Duration 
It takes ~1.5 hours to complete and is fully scrpited, including with Terraform for provisioning.


<hr>

### A.3. Resources provisioned

TODO


<hr>

### A.4. Prerequisites

- A pre-created project
- You need to have organization admin rights, and project owner privileges or work with privileged users to complete provisioning.


<hr>

### A.5. Lab format

- Includes Terraform for provisioning automation
- Is fully scripted - the entire solution is provided, and with instructions
- Is self-paced/self-service


<hr>

### A.6. Audience

- A quick read for architects
- Targeted for hands on practitioners, especially data scientists and data engineers


<hr>

### A.7. Features covered

| Functionality | Feature | 
| -- | :--- | 
| Spark platform |  Spark on Dataproc on GCE |
| Spark platform |  Spark on Dataproc Serverless |
| BYO Jupyter infrastructure |  Jupyter plugin for Dataproc cluster/serverless |
| Data Lake File System |  Google Cloud Storage |
| Provisioning Automation | Terraform |


<hr>

### A.8. Lab Architecture


![README](./images/lab-07-04.png)   
<br><br>

<hr>

### A.9. Lab Flow

![README](images/lab-07-01.png)   
<br><br>

<hr>

# B. THE LAB

<hr>

## B.1. Infrastructure provisioning

### B.1.1. Clone this repo in Cloud Shell

```
git clone https://github.com/anagha-google/dataproc-labs.git
```

<hr>

### B.1.2. Foundational provisioning automation with Terraform 
The Terraform in this section updates organization policies and enables Google APIs.<br>

1. Paste this in Cloud Shell
```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
cd ~/dataproc-labs/7-dataproc-jupyter-plugin/provisioning-automation/foundations-tf
```

2. Run the Terraform for organization policy edits and enabling Google APIs
```
terraform init
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -auto-approve >> dataproc-jupyter-plugin-foundations-tf.output
```

**Note:** Wait till the provisioning completes (~10 minutes) before moving to the next section.



<hr>

### B.1.3. Lab resources provisioning automation with Terraform 

#### B.1.3.1. Resources provisioned
In this section, we will provision-
1. Network, subnet, firewall rule
2. Storage buckets for code/data/logs 
3. Dataproc on GCE cluster
4. User Managed Service Account
5. Requisite IAM permissions
6. Copy of code, data, etc into buckets


#### B.1.3.2. Run the terraform scripts

1. Paste this in Cloud Shell after editing the GCP region variable to match your nearest region-

```
cd ~/dataproc-labs/7-dataproc-jupyter-plugin/provisioning-automation/core-tf/terraform
```

```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
PROJECT_NAME=`gcloud projects describe ${PROJECT_ID} | grep name | cut -d':' -f2 | xargs`
YOUR_GCP_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
YOUR_GCP_ORG_ID=`gcloud organizations list --format="value(name)"`
GCP_REGION="us-central1"
```

2. Run the Terraform for provisioning the rest of the environment
```
terraform init
terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -var="project_name=${PROJECT_NAME}" \
  -var="project_number=${PROJECT_NBR}" \
  -var="org_id=${ORG_ID}" \
  -var="gcp_region=${GCP_REGION}" \
  -auto-approve >> dataproc-jupyter-plugin-core-tf.output
```

**Note:** Takes ~10 minutes to complete.

<br>

<hr>

### B.2. Explore the resources provisioned

### B.2.1. Dataproc on GCE cluster (DPGCE)

- Validate the creation of the Dataproc on GCE cluster from the Cloud Console, Dataproc UI -> Clusters
- The DPGCE has a name prefix - "	dpgce-cluster-static-"
- Click on all the tables of the cluster details and review the configuration
- Under configuration, check for the metastore configuration
- And check for the Spark History Server bucket configuration


<br>

<hr>



