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
3. Visit the Spark History Server to review the execution DAG to review stages that benefited from GPU acceleration.

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

1. From the Cloud Console, search for Dataproc and from there, click on clusters. 
2. The cluster having a "phs" prefix is the persistent history server we just provisioned.
3. Below are the steps to navigate to the Spark History Server

![README](./images/m3-04.png)   
<br><br>

![README](./images/m3-05.png)   
<br><br>

![README](./images/m3-06.png)   
<br><br>

![README](./images/m3-07.png)   
<br><br>

![README](./images/m3-08.png)   
<br><br>

![README](./images/m3-09.png)   
<br><br>

<hr>
<hr>

## 3. Run the ETL job from module 2, to establish the CPU performance baseline

### 3.1. Execute the job


### 3.2. Note the execution time


### 3.3. Review the execution plan


<hr>
<hr>


## 4. Run the same ETL job with GPUs

### 4.1. Execute the job


### 4.2. Note the execution time


### 4.3. Review the execution plan


<hr>
<hr>

## 5. Optimization summary



## 6. In closing


Dataproc and Nvidia GPUs can majorly accelerate ETL and Data Science worklads that use Spark SQL and Spark dataframes and can fall back to CPU based execution when a Spark stage/feature is unsupported by spark-rapids.

<br><br>
This concludes the lab. **DONT FORGET** to Shut down the project to avoid billing.

<hr>
<hr>


