# About

This lab showcases Spark application acceleration with Spark-RAPIDS on Dataproc on GCE powered by GPUs. This lab uses the environment from the prior labs-
Specifically - [2-dataproc-gce-with-terraform](../2-dataproc-gce-with-terraform)

To use RAPIDS accelerator For Apache Spark with Dataproc, GCP and NVIDIA maintain init action scripts and the cluster creation step in this lab, includes the init scripts. 


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

### 2.3. Create a bucket for the scripts & upload lab scripts to it

Paste in Cloud Shell-
```
gcloud storage buckets create gs://$CODE_BUCKET --project=$PROJECT_ID --location=$REGION
```

You would have already cloned the repo. Lets navigate to the lab directory and upload the data.

Paste in Cloud Shell-
```
cd ~/dataproc-labs/5-dataproc-gce-with-gpu/00-scripts/
gsutil cp * gs://$CODE_BUCKET/churn/
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


## 4. Review the lab dataset

The dataset is the famous Kaggle Telco Customer Churn dataset - small data. Review the same.

Paste in Cloud Shell-
```
head -10 ~/dataproc-labs/5-dataproc-gce-with-gpu/01-datasets/telco-customer-churn.csv
```


## 5. Create an archive with the requisite scripts

```
cd ~/dataproc-labs/5-dataproc-gce-with-gpu/00-scripts
zip data_generator_archive.zip -r churn_utils data_generator_util
```

## 6. Generate a larger dataset off of the base lab dataset

The script (generate_data.py) has been provided to us by Nvidia to create a larger dataset and is located as shown below. <br>

### 6.1. Review the script
```
cd ~/dataproc-labs/5-dataproc-gce-with-gpu/00-scripts/data_generator_util
cat generate_data.py
```

### 6.2. Declare variables

```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
SPARK_SERVERLESS_SUBNET=spark-snet
PERSISTENT_HISTORY_SERVER_NM=dpgce-sphs-${PROJECT_NBR}
UMSA_FQN=dpgce-lab-sa@$PROJECT_ID.iam.gserviceaccount.com
CODE_AND_DATA_BUCKET=dpgce_data_and_code_bucket-${PROJECT_NBR}
DPGCE_CLUSTER_NAME=dpgce-cluster-static-gpu-${PROJECT_NBR}


LOG_SECOND=`date +%s`
LOGFILE="logs/$0.txt.$LOG_SECOND"
mkdir -p logs

# This is used to define the size of the dataset that is generated
# 10000 will generate a dataset of roughly 25GB in size
SCALE=10

# Set this value to the total number of cores that you have across all
# your worker nodes. 
TOTAL_CORES=32
#
# Set this value to 1/4 the number of cores listed above. Generally,
# we have found that 4 cores per executor performs well.
NUM_EXECUTORS=8   # 1/4 the number of cores in the cluster
#
NUM_EXECUTOR_CORES=$((${TOTAL_CORES}/${NUM_EXECUTORS}))
#
# Set this to the total memory across all your worker nodes. e.g. RAM of each worker * number of worker nodes
TOTAL_MEMORY=120   # unit: GB
DRIVER_MEMORY=4    # unit: GB
#
# This takes the total memory and calculates the maximum amount of memory
# per executor
EXECUTOR_MEMORY=$(($((${TOTAL_MEMORY}-$((${DRIVER_MEMORY}*1000/1024))))/${NUM_EXECUTORS}))

# Source base data file to be bulked up
INPUT_FILE="gs://[YourBucket]/data/WA_Fn-UseC_-Telco-Customer-Churn-.csv"
# *****************************************************************
# Output prefix is where the data that is generated will be stored.
# This path is important as it is used for the INPUT_PREFIX for
# the cpu and gpu env files
# *****************************************************************
#
OUTPUT_PREFIX="hdfs:///data/10scale/"
```





