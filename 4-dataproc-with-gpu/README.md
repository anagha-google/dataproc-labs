# About

This lab showcases Spark application acceleration with Spark-RAPIDS on Dataproc on GCE & Dataproc Serverless Spark - powered by GPUs. 

The lab is an adaptation of the lab from Nvidia in the Google Cloud Platform Data Lake Modernization repo that has been simplified to provide a quickstart experience with the addition of Terraform for automation and Airflow DAGs to demonstrate automation across both Dataproc on GCE clusters and dataproc Spark Serverless. 

To leverage the RAPIDS accelerator for Apache Spark with Dataproc on GCE as well as Dataproc Serverless, GCP and NVIDIA maintain (init action) scripts and the lab, includes the same scripts directly (Dataproc GCE cluster creation) and implicitly (Dataproc Serverless abstracts out). 

<hr>

## Lab

| # | About | 
| -- | :--- |  
| [01](Lab-Module-01.md) |  Foundational infrastructure provisioning for the lab with Terraform | 
| [02](Lab-Module-02.md) |  Spark on Dataproc GCE cluster form factor with GPU acceletation | 
| [03](Lab-Module-03.md) |  Spark on Dataproc Serverless form factor with GPU acceletation | 


<hr>
