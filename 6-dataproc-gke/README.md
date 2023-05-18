# About

This lab is primer intended to demystify running Spark on Dataproc on GKE with a minimum viable Spark application.<br> 
It reuses the foundational setup from Lab 2 - Dataproc on GCE. This includes the network, subnet, Dataproc Metatsore and Dataproc Persistent History Server.<br>
We will eventually make this a standalone lab with no dependency on other labs.<br>

In this lab-
1. We will first create a GKE cluster 
2. And then create a basic Dataproc on GKE cluster on it.
3. And run a basic Spark application on it
4. We will review logging
5. Monitoring for GKE clusters

## 1. Foundational setup

### 1.1. Install kubectl
In Cloud Shell, lets install kubectl-
```
sudo apt-get install kubectl
```

Then check the version-
```
kubectl version
```

### 1.2. Install required plugins/check version
kubectl and other Kubernetes clients require an authentication plugin, gke-gcloud-auth-plugin, which uses the Client-go Credential Plugins framework to provide authentication tokens to communicate with GKE clusters.

```
gke-gcloud-auth-plugin --version
```

### 1.3. Create an account for Docker if you dont have one already, and sign-in to Docker on Cloud Shell
This is helpful when creating custom images.

Get an account-
https://docs.docker.com/get-docker/

Sign-in to Docker from Cloud Shell--
```
docker login --username <your docker-username>
```

### 1.4. Enable APIs

Enable any APIs needed for this lab, over and above what was enabled as part of Lab 2.


Paste in Cloud Shell-
```
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### 1.5. Create a bucket for use by dataproc on GKE

Paste in Cloud Shell-
```
DPGKE_LOG_BUCKET=dpgke-dataproc-bucket-${PROJECT_NBR}-logs

gcloud storage buckets create gs://$DPGKE_LOG_BUCKET --project=$PROJECT_ID --location=$REGION
```

### 1.6. Create a User Managed Service Account and grant yourself impersonation privileges

#### 1.6.1. Create a User Managed Service Account 

Paste in Cloud Shell-
```
UMSA=dpgke-umsa
gcloud iam service-accounts create "$UMSA_FQN" \
    --description "UMSA for use with DPGKE for the lab 6+"
```
#### 1.6.2. Grant youself impersonation privileges to the service account

Paste in Cloud Shell-
```
UMSA_FQN="${UMSA}@${PROJECT_ID}.iam.gserviceaccount.com"
YOUR_USER_PRINICPAL_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`

gcloud iam service-accounts add-iam-policy-binding \
    ${UMSA_FQN} \
    --member="user:${YOUR_USER_PRINICPAL_NAME}" \
    --role="roles/iam.serviceAccountUser"

gcloud iam service-accounts add-iam-policy-binding \
    ${UMSA_FQN} \
    --member="user:${YOUR_USER_PRINICPAL_NAME}" \
    --role="roles/iam.serviceAccountTokenCreator"
```

### 1.7. Create a base GKE cluster

Paste in Cloud Shell-
```
# Set variables.
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
GKE_CLUSTER_NAME=dataproc-gke-base-${PROJECT_NBR}
VPC_NM=dpgce-vpc-$PROJECT_NBR
SPARK_SUBNET=spark-snet
PERSISTENT_HISTORY_SERVER_NM=dpgce-sphs-${PROJECT_NBR}
REGION=us-central1
ZONE=us-central1-a
GSA="${PROJECT_NBR}-compute@developer.gserviceaccount.com"
MACHINE_SKU="n2d-standard-4"
UMSA=dpgke-umsa
UMSA_FQN="${UMSA}@${PROJECT_ID}.iam.gserviceaccount.com"

# Create a GKE cluster
gcloud container clusters create \
  --project "${PROJECT_ID}" \
  --region "${REGION}" \
  "${GKE_CLUSTER_NAME}" \
  --autoscaling-profile optimize-utilization \
  --workload-pool "${PROJECT_ID}.svc.id.goog" \
  --machine-type "${MACHINE_SKU}" \
  --enable-autoscaling \
  --enable-image-streaming \
  --network $VPC_NM \
  --subnetwork $SPARK_SUBNET \
  --num-nodes 2 \
  --min-nodes 0 \
  --max-nodes 2 \
  --local-ssd-count 2 \
  --service-account ${UMSA_FQN}
```

### 1.8. Get credentials to connect to the GKE cluster

Paste in Cloud Shell-
```
gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --region $REGION
```

### 1.9. Connect to the cluster and list entities created


Paste in Cloud Shell-
```
kubectl get namespaces
```

### 1.10. Grant requisite permissions to Dataproc agent

Paste in Cloud Shell-
```
gcloud projects add-iam-policy-binding \
  --role roles/container.admin \
  --member "serviceAccount:service-${PROJECT_NBR}@dataproc-accounts.iam.gserviceaccount.com" \
  "${PROJECT_ID}"
```

# TODO - remove the below and test as 
```
GMSA="${PROJECT_NBR}-compute@developer.gserviceaccount.com"

gcloud projects add-iam-policy-binding \
  --role roles/storage.objectAdmin \
  --role roles/bigquery.dataEditor \
  --member "serviceAccount:${GMSA}" \
  "${PROJECT_ID}"

```

### 1.11. Grant permissions for the User Managed Service Account to work with GKE and Kubernetes SAs

Run the following commands to assign necessary Workload Identity permissions to the user managed service account. <br>

```
DPGKE_NAMESPACE="dpgke-$PROJECT_NBR" 

#1. Assign your User Managed Service Account the dataproc.worker role to allow it to act as agent
gcloud projects add-iam-policy-binding \
    --role=roles/dataproc.worker \
    --member="serviceAccount:${UMSA_FQN}" \
    "${PROJECT_ID}"

#2. Assign the "agent" Kubernetes Service Account the iam.workloadIdentityUser role to allow it to act as your User Managed Service Account
gcloud iam service-accounts add-iam-policy-binding \
    "${UMSA_FQN}" \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${DPGKE_NAMESPACE}/agent]" \
    --role=roles/iam.workloadIdentityUser 
    
#3. Grant the "spark-driver" Kubernetes Service Account the iam.workloadIdentityUser role to allow it to act as your User Managed Service Account
gcloud iam service-accounts add-iam-policy-binding \
     "${UMSA_FQN}" \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${DPGKE_NAMESPACE}/spark-driver]" \
    --role=roles/iam.workloadIdentityUser 

#4. Grant the "spark-executor" Kubernetes Service Account the iam.workloadIdentityUser role to allow it to act as your User Managed Service Account
gcloud iam service-accounts add-iam-policy-binding \
    "${UMSA_FQN}" \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${DPGKE_NAMESPACE}/spark-executor]" \
    --role=roles/iam.workloadIdentityUser 
```

<hr>

## 2. Create a basic Dataproc virtual cluster on GKE & submit a Spark job to it

### 2.1. Create a basic Dataproc virtual cluster on GKE
```
gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --region $REGION

# Set the following variables from the USER variable.
DP_CLUSTER_NAME="dpgke-cluster-static-$PROJECT_NBR"
DPGKE_NAMESPACE="dpgke-$PROJECT_NBR"
DPGKE_CONTROLLER_POOLNAME="dpgke-pool-default"
DPGKE_DRIVER_POOLNAME="dpgke-pool-driver"
DPGKE_EXECUTOR_POOLNAME="dpgke-pool-executor"
DPGKE_LOG_BUCKET=dpgke-dataproc-bucket-${PROJECT_NBR}-logs
UMSA=dpgke-umsa
UMSA_FQN="${UMSA}@${PROJECT_ID}.iam.gserviceaccount.com"
REGION="us-central1"
ZONE=${REGION}-a


gcloud dataproc clusters gke create ${DP_CLUSTER_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --gke-cluster=${GKE_CLUSTER_NAME} \
  --spark-engine-version='latest' \
  --staging-bucket=${DPGKE_LOG_BUCKET} \
  --setup-workload-identity \
  --properties "dataproc:dataproc.gke.agent.google-service-account=${UMSA_FQN}" \
  --properties "dataproc:dataproc.gke.spark.driver.google-service-account=${UMSA_FQN}" \
  --properties "dataproc:dataproc.gke.spark.executor.google-service-account=${UMSA_FQN}" \
  --pools="name=${DPGKE_CONTROLLER_POOLNAME},roles=default,machineType=n1-standard-4,min=0,max=3,locations=${ZONE}" \
  --pools="name=${DPGKE_DRIVER_POOLNAME},roles=spark-driver,machineType=n1-standard-4,min=0,max=3,locations=${ZONE}" \
  --pools="name=${DPGKE_EXECUTOR_POOLNAME},roles=spark-executor,machineType=n1-standard-4,min=0,max=3,locations=${ZONE},localSsdCount=1" 

```

### 2.2. Submit the SparkPi job on the cluster

```
gcloud dataproc jobs submit spark \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --id="dpgke-sparkpi-$RANDOM" \
  --cluster=${DP_CLUSTER_NAME} \
  --class=org.apache.spark.examples.SparkPi \
  --jars=local:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- 1000
```
