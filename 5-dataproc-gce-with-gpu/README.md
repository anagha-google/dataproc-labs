# About

This lab showcases Spark application acceleration with Spark-RAPIDS on Dataproc on GCE. This lab uses the environment from the prior labs-
Specifically - [2-dataproc-gce-with-terraform](../2-dataproc-gce-with-terraform)


## 1. Declare variables

Paste in Cloud Shell-
```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`

CLUSTER_NAME=dpgce-cluster-static-gpu-${PROJECT_NBR}
DPGCE_LOG_BUCKET=dpgce-cluster-static-gpu-${PROJECT_NBR}-logs
VPC_NM=VPC=dpgce-vpc-$PROJECT_NBR
SPARK_SUBNET=spark-snet
PERSISTENT_HISTORY_SERVER_NM=dpgce-sphs-${PROJECT_NBR}
UMSA_FQN=dpgce-lab-sa@$PROJECT_ID.iam.gserviceaccount.com
REGION=us-central1
ZONE=us-central1-a
NUM_GPUS=1
NUM_WORKERS=4
```

## 2. Create a bucket for Dataproc logs

Paste in Cloud Shell-
```
gcloud storage buckets create gs://$DPGCE_LOG_BUCKET --project=$PROJECT_ID --location=$REGION
```

## 3. Create a DPGCE cluster with GPUs

Paste in Cloud Shell-

```


gcloud dataproc clusters create $CLUSTER_NAME  \
    --region $REGION \
    --zone $ZONE \
    --image-version=2.0-ubuntu18 \
    --master-machine-type=n1-standard-4 \
    --num-workers=$NUM_WORKERS \
    --worker-accelerator=type=nvidia-tesla-t4,count=$NUM_GPUS \
    --worker-machine-type=n1-standard-8 \
    --num-worker-local-ssds=1 \
    --initialization-actions=gs://goog-dataproc-initialization-actions-${REGION}/spark-rapids/spark-rapids.sh \
    --optional-components=JUPYTER,ZEPPELIN \
    --metadata gpu-driver-provider="NVIDIA",rapids-runtime="SPARK" \
    --bucket $DPGCE_LOG_BUCKET \
    --subnet=$SPARK_SUBNET \
    --enable-component-gateway
    
```


## 4. 
