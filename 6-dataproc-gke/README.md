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
UMSA_FQN="${UMSA}@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud iam service-accounts create "$UMSA" \
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

#### 1.9.1. Namespaces

Paste in Cloud Shell-
```
kubectl get namespaces
```

Here is the author's output-
```
----INFORMATIONAL----
NAME              STATUS   AGE
default           Active   8h
kube-node-lease   Active   8h
kube-public       Active   8h
kube-system       Active   8h
----INFORMATIONAL----
```

#### 1.9.2. Node pools

After creation of the GKE cluster in our lab, there should only be one node pool.

Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool | grep -v GKE-NODEPOOL | awk '{print $6}' | sort | uniq -c | sort -r
```
Here is the author's output-
```
----INFORMATIONAL----
      1 default-pool
----INFORMATIONAL----
```

#### 1.9.3. Nodes

Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool
```
Here is the author's output-
```
----INFORMATIONAL----
NAME                                                  STATUS   ROLES    AGE   VERSION           GKE-NODEPOOL
gke-dataproc-gke-base-42-default-pool-aa627942-s50g   Ready    <none>   8h    v1.25.8-gke.500   default-pool
----INFORMATIONAL----
```


### 1.10. Grant requisite permissions to Dataproc agent

Paste in Cloud Shell-
```
gcloud projects add-iam-policy-binding \
  --role roles/container.admin \
  --member "serviceAccount:service-${PROJECT_NBR}@dataproc-accounts.iam.gserviceaccount.com" \
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
# Variables
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
GKE_CLUSTER_NAME=dataproc-gke-base-${PROJECT_NBR}
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

# Get credentials to the GKE cluster
gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --region $REGION

# Create the Dataproc on GKE cluster
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

Known issues and workarounds:
1. If the node pools dont exist, you may see an error with the creation of the second node pool. <br>
Workaround: 
```
# 1a. Delete namespace
kubectl delete namespace $DPGKE_NAMESPACE

# 1b. Delete Dataproc GKE cluster
gcloud dataproc clusters delete ${DP_CLUSTER_NAME}

# 1c. Rerun the command at section 2.1 - create a Dataproc GKE cluster
```

### 2.2. Review namespaces created

#### 2.2.1. Namespaces

Paste in Cloud Shell-
```
kubectl get namespaces
```

Here is the author's output-
```
----THIS IS INFORMATIONAL---
NAME                                STATUS   AGE
default                             Active   8h
dpgke-cluster-static-420530778089   Active   14m
kube-node-lease                     Active   8h
kube-public                         Active   8h
kube-system                         Active   8h
----INFORMATIONAL----
```
The dpgke* namespace is the Dataproc GKE cluster namespace

#### 2.2.2. Pods

Paste in Cloud Shell-
```
DPGKE_CLUSTER_NAMESPACE=`kubectl get namespaces | grep dpgke | cut -d' ' -f1`
kubectl get pods -n $DPGKE_CLUSTER_NAMESPACE
```
Here is the author's output-
```
----THIS IS INFORMATIONAL---
NAME                                                   READY   STATUS    RESTARTS   AGE
agent-6b6b69458f-4scmr                                 1/1     Running   0          30m
spark-engine-6577d5497f-mftx2                          1/1     Running   0          30m
----INFORMATIONAL----
```


#### 2.2.3. Node pools

After creation of the Dataproc GKE cluster in our lab, there should only be an extra node pool.

Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool | grep -v GKE-NODEPOOL | awk '{print $6}' | sort | uniq -c | sort -r
```
Here is the author's output-
```
----THIS IS INFORMATIONAL---
      1 dpgke-pool-default
      1 default-pool
----INFORMATIONAL----
```
dpgke-pool-default is the new one created for the Dataproc GKE cluster.


#### 2.2.4. Nodes with node pool name

Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool
```

Here is the author's output-
```
----THIS IS INFORMATIONAL---
NAME                                                  STATUS   ROLES    AGE     VERSION           GKE-NODEPOOL
gke-dataproc-gke-bas-dpgke-pool-defau-61a73f7d-xw5k   Ready    <none>   30m     v1.25.8-gke.500   dpgke-pool-default
gke-dataproc-gke-base-42-default-pool-aa627942-s50g   Ready    <none>   8h      v1.25.8-gke.500   default-pool
----INFORMATIONAL----
```

<hr>

## 3. Run a Spark job on the cluster

### 3.1. Submit the SparkPi job on the cluster

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

### 3.2. Node pools as the job runs

Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool | grep -v GKE-NODEPOOL | awk '{print $6}' | sort | uniq -c | sort -r
```
Here is the author's output-
```
----THIS IS INFORMATIONAL---
      1 dpgke-pool-executor
      1 dpgke-pool-driver
      1 dpgke-pool-default
      1 default-pool
----INFORMATIONAL----
```

### 3.3. Nodes as the job runs
Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool
```

Here is the author's output-
```
----THIS IS INFORMATIONAL---
NAME                                                  STATUS   ROLES    AGE     VERSION           GKE-NODEPOOL
gke-dataproc-gke-bas-dpgke-pool-defau-61a73f7d-xw5k   Ready    <none>   30m     v1.25.8-gke.500   dpgke-pool-default
gke-dataproc-gke-bas-dpgke-pool-drive-2d585a56-flgf   Ready    <none>   2m44s   v1.25.8-gke.500   dpgke-pool-driver
gke-dataproc-gke-bas-dpgke-pool-execu-ae26574b-fs2l   Ready    <none>   26s     v1.25.8-gke.500   dpgke-pool-executor
gke-dataproc-gke-base-42-default-pool-aa627942-s50g   Ready    <none>   8h      v1.25.8-gke.500   default-pool
----INFORMATIONAL----
```

Note that the executor and drive node pools show up

### 3.4. Pods

Paste in Cloud Shell-
```
DPGKE_CLUSTER_NAMESPACE=`kubectl get namespaces | grep dpgke | cut -d' ' -f1`
kubectl get pods -n $DPGKE_CLUSTER_NAMESPACE
```

Here is the author's output-
```
----THIS IS INFORMATIONAL---
# While running
NAME                                                   READY   STATUS    RESTARTS   AGE
agent-6b6b69458f-4scmr                                 1/1     Running   0          42m
dp-spark-c56d7f4c-18ae-3c96-9690-0ec23b44d3f0-driver   2/2     Running   0          2m20s
dp-spark-c56d7f4c-18ae-3c96-9690-0ec23b44d3f0-exec-1   0/1     Pending   0          15s
dp-spark-c56d7f4c-18ae-3c96-9690-0ec23b44d3f0-exec-2   0/1     Pending   0          15s
spark-engine-6577d5497f-mftx2                          1/1     Running   0          42m
-------------------------------------------------------------------------------------------
# After completion
NAME                                                   READY   STATUS      RESTARTS   AGE
agent-6b6b69458f-4scmr                                 1/1     Running     0          31m
dp-spark-79821ac2-26f5-3218-90fd-88f84cdc666e-driver   0/2     Completed   0          4m3s
spark-engine-6577d5497f-mftx2                          1/1     Running     0          31m
----INFORMATIONAL----
```

### 3.5. Driver logs in GKE

```
DRIVER=`kubectl get pods -n $DPGKE_CLUSTER_NAMESPACE | grep driver | cut -d' ' -f1`
kubectl logs $DRIVER -n $DPGKE_CLUSTER_NAMESPACE -f
```

### 3.6. Executor logs in GKE

Similar to the above. Identify the executor of your choice and run the ```kubectl logs``` command.

<hr>

## 4. BYO Peristent History Server & Hive Metastore

In Lab 2, we created a Persistent History Server and a Dataproc Metastore. To use the two, we just need to reference it during cluster creation.

```
----THIS IS INFORMATIONAL---
PERSISTENT_HISTORY_SERVER_NAME="dpgce-sphs-$PROJECT_NBR"

gcloud dataproc clusters gke create ${DP_CLUSTER_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --gke-cluster=${GKE_CLUSTER_NAME} \
  --history-server-cluster=${PERSISTENT_HISTORY_SERVER_NAME} \
  --properties="spark:spark.sql.catalogImplementation=hive,spark:spark.hive.metastore.uris=thrift://<METASTORE_HOST>:<PORT>,spark:spark.hive.metastore.warehouse.dir=<WAREHOUSE_DIR>"
  --spark-engine-version='latest' \
  --staging-bucket=${DPGKE_LOG_BUCKET} \
  --setup-workload-identity \
  --properties "dataproc:dataproc.gke.agent.google-service-account=${UMSA_FQN}" \
  --properties "dataproc:dataproc.gke.spark.driver.google-service-account=${UMSA_FQN}" \
  --properties "dataproc:dataproc.gke.spark.executor.google-service-account=${UMSA_FQN}" \
  --pools="name=${DPGKE_CONTROLLER_POOLNAME},roles=default,machineType=n1-standard-4,min=0,max=3,locations=${ZONE}" \
  --pools="name=${DPGKE_DRIVER_POOLNAME},roles=spark-driver,machineType=n1-standard-4,min=0,max=3,locations=${ZONE}" \
  --pools="name=${DPGKE_EXECUTOR_POOLNAME},roles=spark-executor,machineType=n1-standard-4,min=0,max=3,locations=${ZONE},localSsdCount=1" 
----THIS IS INFORMATIONAL---
```

As shown above, for History Server (Spark UI), include the line -
```
  --history-server-cluster=${PERSISTENT_HISTORY_SERVER_NAME} \
```
And for Dataproc Metastore/Hive Metastore-
```
--properties="spark:spark.sql.catalogImplementation=hive,spark:spark.hive.metastore.uris=thrift://<METASTORE_HOST>:<PORT>,spark:spark.hive.metastore.warehouse.dir=<WAREHOUSE_DIR>"
```

<hr>

## 5. Custom images

Documentation is below; Lab module to be added in the near future.
https://cloud.google.com/dataproc/docs/guides/dpgke/dataproc-gke-custom-images

<hr>

## 6. Spark UI
Is the Persistent Histroy Server covered in the section 4.

## 7. Logging

When a job is executing, go to the Dataproc cluster UI, click on the Dataproc on GKE cluster, and then and click on the job running. Click on "View logs". You will see the following filters-
```
----THIS IS INFORMATIONAL AND IS THE AUTHOR'S DETAILS---
resource.type="k8s_container"
resource.labels.cluster_name="dataproc-gke-base-420530778089"
resource.labels.namespace_name="dpgke-cluster-static-420530778089"
resource.labels.container_name="controller"
```

Navigate into the logs and search for drivers, executors by playing with the ```resource.labels.container_name``` filter value (```executor```, ```driver```).
<hr>

This concludes the lab. Dont forget to shut down the project.

<hr>
