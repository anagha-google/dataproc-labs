# Module-03: GPU acceleration for Spark on Dataproc Serverless


<hr>

## 1. About the lab

### 1.1. Prerequisites
Successful completion of prior module

<hr>

### 1.2. What to expect
In this lab, we will-

1. Create a Dataproc Persistent Spark History Server
2. Learn how to submit Spark jobs on Dataproc Serverless with GPUs

<hr>

### 1.3. Lab flow

<hr>

### 1.4. Lab infrastructure



<hr>

### 1.5. Duration
~ 1 hour or less but does not require focus time.

<hr>
<hr>

## 2. Create a Persistent Spark History Server

This section should take 5 minutes to complete.

### 2.1. Provision the History Server
Paste the below in Cloud Shell-
```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
DATAPROC_PHS_NAME=phs-${PROJECT_NBR}
PHS_BUCKET=spark-event-log-bucket-s8s-${PROJECT_NBR}
VPC_NM=VPC=vpc-$PROJECT_NBR
SPARK_SUBNET=spark-snet
UMSA_FQN=lab-sa@$PROJECT_ID.iam.gserviceaccount.com
REGION=us-central1
ZONE=us-central1-a
DPGCE_CLUSTER_BUCKET=spark-cluster-bucket-${PROJECT_NBR}


gcloud dataproc clusters create ${DATAPROC_PHS_NAME} \
    --project=$PROJECT_ID \
    --region=$REGION \
    --zone $ZONE \
    --single-node \
    --enable-component-gateway \
    --subnet=$SPARK_SUBNET \
    --properties "spark:spark.history.fs.logDirectory=gs://${PHS_BUCKET}/*/spark-job-history,spark:spark.eventLog.dir=gs://${PHS_BUCKET}/events/spark-job-history" \
    --service-account $UMSA_FQN   \
    --bucket $DPGCE_CLUSTER_BUCKET 
```

<hr>

### 2.2. Navigating to the Spark History Server



<hr>
<hr>
