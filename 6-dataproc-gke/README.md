# About

This lab demonstrates running Spark on Dataproc on GKE. It reuses the foundational setup from Lab 2 - Dataproc on GCE.

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

### 1.2. Install required plugins
kubectl and other Kubernetes clients require an authentication plugin, gke-gcloud-auth-plugin, which uses the Client-go Credential Plugins framework to provide authentication tokens to communicate with GKE clusters.

```
gke-gcloud-auth-plugin --version
```

### 1.3. Create an account for Docker if you dont have one already, and sign-in to Docker on Cloud Shell
Get an account-
https://docs.docker.com/get-docker/

Sign-in to Docker from the command line-
```
docker login --username <your docker-username>
```

### 1.4. Enable APIs

```
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### 1.5. Create a base GKE cluster

Paste in Cloud Shell-
```
# Set variables.
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
GKE_CLUSTER_NAME=gke-base-${PROJECT_NBR}
VPC_NM=dpgce-vpc-$PROJECT_NBR
SPARK_SUBNET=spark-snet
PERSISTENT_HISTORY_SERVER_NM=dpgce-sphs-${PROJECT_NBR}
UMSA_FQN=dpgce-lab-sa@$PROJECT_ID.iam.gserviceaccount.com
REGION=us-central1
ZONE=us-central1-a
GSA="${PROJECT_NBR}-compute@developer.gserviceaccount.com"

# Create a GKE cluster
gcloud container clusters create \
  --project "${PROJECT_ID}" \
  --region "${REGION}" \
  "${GKE_CLUSTER_NAME}" \
  --autoscaling-profile optimize-utilization \
  --workload-pool "${PROJECT_ID}.svc.id.goog" \
  --enable-autoscaling \
  --enable-image-streaming \
  --network $VPC_NM \
  --subnetwork $SPARK_SUBNET \
  --num-nodes 2 \
  --min-nodes 0 \
  --max-nodes 3
```

### 1.6. Get credentials to connect to the GKE cluster

Paste in Cloud Shell-
```
gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --region $REGION
```

### 1.7. Connect to the cluster

```
kubectl get namespaces
```

### 1.8. 

```
gcloud projects add-iam-policy-binding \
  --role roles/container.admin \
  --member "serviceAccount:service-${PROJECT_NBR}@dataproc-accounts.iam.gserviceaccount.com" \
  "${PROJECT_ID}"
```

```
GMSA="${PROJECT_NBR}-compute@developer.gserviceaccount.com"

gcloud projects add-iam-policy-binding \
  --role roles/storage.objectAdmin \
  --role roles/bigquery.dataEditor \
  --member "serviceAccount:${GMSA}" \
  "${PROJECT_ID}"

```

## 2. Create Dataproc Virtual Cluster on GKE

```
# Set the following variables from the USER variable.
DP_CLUSTER_NAME="dpgke-$PROJECT_NBR"
DPGKE_NAMESPACE="dpgke"
DPGKE_POOLNAME="dpgke-pool"
DPGKE_LOG_BUCKET=dpgke-dataproc-bucket-${PROJECT_NBR}-logs

gcloud storage buckets create gs://$DPGKE_LOG_BUCKET --project=$PROJECT_ID --location=$REGION

gcloud dataproc clusters gke create ${DP_CLUSTER_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --gke-cluster=${GKE_CLUSTER_NAME} \
  --spark-engine-version='latest' \
  --staging-bucket=${DPGKE_LOG_BUCKET} \
  --pools="name=${DP_POOLNAME},roles=default,machineType=n2-standard-8" \
  --setup-workload-identity
```

## 3. Submit the SparkPi job on the cluster

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
