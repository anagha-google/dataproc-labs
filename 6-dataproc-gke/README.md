# About

This lab demonstrates running Spark on Dataproc on GKE. It reuses the setup from Lab 2 - Dataproc on GCE.

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

### 1.2. Create an account for Docker if you dont have one already, and sign-in to Docker on Cloud Shell
Get an account-
https://docs.docker.com/get-docker/

Sign-in to Docker from the command line-
```
docker login --username <your docker-username>
```

### 1.3. Enable APIs

```
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### 1.4. Create a GKE cluster

```
gcloud container clusters create bq-log-analytics-lab-gke --enable-autoupgrade \
    --enable-autoscaling --min-nodes=3 --max-nodes=10 --num-nodes=5 --zone=us-central1-a
```
