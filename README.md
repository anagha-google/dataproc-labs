# Dataproc Labs

This repo hosts minimum viable self-contained, end-to-end solutions that showcase Spark on GCP and its integration with other GCP services. They are intended to demystify our products and their integration.

| # | About | 
| -- | :--- |  
| [Lab-01](1-dataproc-serverless-with-terraform) |  Orchestration of Spark jobs on Dataproc Serverless with Airflow on Cloud Composer 2 | 
| [Lab-02](2-dataproc-gce-with-terraform) |  Orchestration of Spark jobs on Dataproc GCE cluster with Airflow on Cloud Composer 2 | 
| [Lab-03](3-dataproc-gke) |  Just enough Dataproc on GKE  | 
| [Lab-04](4-dataproc-gce-with-gpu) |  Just enough Dataproc on GCE with GPU acceleration  | 
| [Lab-05](5-dataproc-serverless-with-gpu) |  Just enough Dataproc Serverless Spark with GPU acceleration  | 
| [Lab-06](6-dataproc-jupyter-plugin) | BYO Jupyter for Dataproc GCE clusters and Dataproc Serverless with Dataproc Jupyter Plugin  | 
| [Lab-07](7-dataproc-workspaces) | Just enough Dataproc Workspaces for Data Scientists and Data Engineers | 
| [Lab-08](https://github.com/anagha-google/table-format-lab-delta) | Just enough Delta Lake on GCP | 
| [Lab-09](https://github.com/anagha-google/apache-hudi-gcp-lab) | Just enough Apache Hudi on GCP | 
| [Lab-10](https://github.com/anagha-google/s8s-spark-mlops-lab) | Scalable Machine Learning with Spark on GCP and Vertex AI | 
| [Lab-11](https://github.com/anagha-google/ts22-just-enough-terraform-for-da) | Just enough Terraform for Data Analytics on Google Cloud | 
| [Lab-12](https://github.com/anagha-google/spark-on-gcp-with-confluent-kafka) | Near Real Time processing with Spark on Google Cloud and Confluent Cloud |
| [Lab-13](https://github.com/anagha-google/techcon23-datalake-lab) | Code free integration with Dataproc Templates powered by Dataproc Serverless Spark |
| [Lab-14](https://github.com/GoogleCloudPlatform/dataplex-labs/tree/main/dataplex-quickstart-labs) | Data Governance on Google Cloud for OSS Analytics |
| [Lab-15](..) | Lineage for Dataproc Spark jobs|


## Scalable Infrastructure for Regulated Organizations

Google Cloud’s [Assured Workloads](https://cloud.google.com/security/products/assured-workloads?e=48754805&hl=en) helps ensure that regulated organizations across the public and private sector can accelerate AI innovation while meeting their compliance and security requirements. Assured Workloads provides control packages to support the creation of compliant boundaries in Google Cloud. A control package is a set of controls that, when combined together, supports the regulatory baseline for a compliance statute or regulation. These controls include mechanisms to enforce data residency, data sovereignty, personnel access, and more.

We encourage you to evaluate Assured Workloads' [control packages](https://cloud.google.com/assured-workloads/docs/control-packages) and decide whether a control package is required for your organization to meet their regulatory and compliance requirements. If so, we recommend you first deploy Assured Workloads using [this repository],(https://github.com/GoogleCloudPlatform/assured-workloads-terraform) allowing you to maintain your regulatory and compliance requirements, before running these labs.

Note that unsupported products are not recommended for use by Assured Workloads customers without due diligence and waivers from your regulatory agencies or divisions.


## Credits
| # | Google Cloud Collaborators | Contribution  | 
| -- | :--- | :--- |
| 1. | Anagha Khanolkar | Creator |
| 2. | Rick (Rugui) Chen | Support for GKE aspects for the lab on Dataproc on GKE |
| 3. | Dagang Wei | (Google Engineering) Support for Apache Hudi in Dataproc GCDE Optional Component - Hudi |



