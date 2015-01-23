# ![Hortonworks Data Platform](http://hortonworks.com/wp-content/themes/hortonworks/images/layout/header/hortonworks-logo.png) + ![Google Cloud Platform](https://cloud.google.com/_static/images/gcp-logo.png)

Hortonworks Data Platform (HDP) on Google Cloud Platform
========================================================

Deploying Hadoop clusters with **Google's bdutil & Apache Ambari**.

Resources
---------

* [Google documentation](https://cloud.google.com/hadoop/) for bdutil & Hadoop on Google Cloud Platform.
* [Latest source on Github](https://github.com/GoogleCloudPlatform/bdutil). Use & improve.

Video Tutorial
--------------

[<img src="http://img.youtube.com/vi/raCtS84Vb6w/0.jpg" width="320px" />](http://www.youtube.com/watch?v=raCtS84Vb6w)

Before you start
----------------

#### Create a Google Cloud Platform account

  - open https://console.developers.google.com/
  - sign-in or create an account
  - The "free trial" [may be used](#questions)
  

#### Create a Google Cloud Project

* Open https://console.developers.google.com/
* Open 'Create Project' and fill in the details.
  - As an example, this document uses 'hdp-00'
- Within the project, open 'APIs & auth -> APIs'. Then enable:
  - Google Compute Engine
  - Google Cloud Storage
  - Google Cloud Storage JSON API

#### Configure Google Cloud SDK & Google Cloud Storage

* Install [Google Cloud SDK](https://cloud.google.com/sdk/) locally
* Configure the SDK:

  ```
  gcloud auth login                   ## authenticate to Google cloud
  gcloud config set project hdp-00    ## set the default project
  gsutil mb -p hdp-00 gs://hdp-00     ## create a cloud storage bucket
  ```

#### Download bdutil

  * Latest packaged: https://cloud.google.com/hadoop/
  * Latest sorce from GitHub: `git clone https://github.com/GoogleCloudPlatform/bdutil; cd bdutil`

Quick start
-----------

1. Set your project & bucket from above in `bdutil_env.sh`

1. Deploy or Delete the cluster: __see './bdutil --help' for more details__

* Deploy: `./bdutil -e platforms/hdp/ambari_env.sh deploy`
* Delete: `./bdutil -e platforms/hdp/ambari_env.sh delete`
  * when deleting, ensure to use the same switches/configuration as the deploy

Configuration
-------------

* You can deploy without setting any configuration, but you should have a look at `platforms/hdp/ambari.conf`

Here are some of the defaults to consider:

  ```
  GCE_ZONE='us-central1-a'           ## the zone/region to deploy in
  NUM_WORKERS=4                      ## the number of worker nodes. Total
                                     ##     is NUM_WORKERS + 1 master
  GCE_MACHINE_TYPE='n1-standard-4'   ## the machine type
  WORKER_ATTACHED_PDS_SIZE_GB=1500   ## 1500GB attached to each worker
  MASTER_ATTACHED_PD_SIZE_GB=1500    ## 1500GB attached to master

  ## The Hortonworks Data Platform services which will be installed.
  ##   This is nearly the entire stack
  AMBARI_SERVICES='FALCON FLUME GANGLIA HBASE HDFS HIVE KAFKA KERBEROS
        MAPREDUCE2 NAGIOS OOZIE PIG SLIDER SQOOP STORM TEZ YARN ZOOKEEPER'

  AMBARI_PUBLIC=false                ## Services listed on internal
                                     ##   hostname not public IP. Need
                                     ##   a socks proxy or tunnel to access
  ```

Use the cluster
---------------

### SSH

* You'll have immediate SSH access with: `./bdutil shell`
* Or update your SSH config with: `gcloud compute-config-ssh`

#### Access Ambari & other services

a. With a local socks proxy:

  ```
  ./bdutil socksproxy             # opens a socks proxy to the cluster at localhost:1080

  # I use the Chrome extension 'Proxy SwitchySharp' to automatically detect when connecting to Google Compute
  open http://hadoop-m:8080/      # My Google Chrome has an extension which automatically uses the proxy
  ```

b. Or a local SSH tunnel

  ```
  gcloud compute config-ssh                  # updates our SSH config for direct SSH access to all nodes
  ssh -L 8080:127.0.0.1:8080 hadoop-m  <TAB> # quick tunnel to Apache Ambari
  open http://localhost:8080/                # open Ambari in your browser
  ```

c. Or open a firewall rule from the Google Cloud Platform control panel

#### Use the cluster

You now have a full HDP cluster. If you are new to Hadoop check the tutorials at http://hortonworks.com/.

For command-line based jobs, 'bdutil' gives methods for passing through commands: https://cloud.google.com/hadoop/running-a-mapreduce-job

For example: `./bdutil shell < ./extensions/google/gcs-validate-setup.sh`

Questions
---------

### What are the built-in storage options?

By default, HDFS is on **attached disks** _('pd-standard' or 'pd-ssd')_.
- the size and type can be set in `ambari.conf`
 
The rest of the system resides on the **local boot disk**, unless configured otherwise.
 
**Google Cloud Storage** is also available with **`gs://`**. It can be used anywhere that `hdfs://` is available, such as but not limited to mapreduce & `hadoop fs` operations.

  - Note: Adding an additional slash (`gs:///`) will allow you to use the default bucket (defined at cluster build) without needing to specific it.

### Use with the Google _Free Trial_

You may use bdutil with HDP by lowering the machine type & count below the recommended specifications. To use the default configuration, upgrade the account from a free trial.

  * In 'platforms/hdp/ambari.conf':
    * `GCE_MACHINE_TYPE='n1-standard-2'`
    * `WORKERS=3 # or less`
  * Or at the command-line provide these switches to the 'deploy' & 'delete':
    * Deploy cluster: `-n 3 -m n1-standard-2`


<!-- TO BE UNCOMMENTED AFTER RESOLUTION OF: https://github.com/seanorama/bdutil/issues/5

### Can attached persistent disks & data be kept when deleting the machiens in a cluster, and then re-used when the machines are redeployed?

- Yes, if the number of instances matches across deployments.
- More documentation is needed, but until the redemployment test in [TEST.md](./TEST.md) shows the process.
- Essentially you set these variables at the right time:

By setting a few variables at the appropriate times, you can keep attached storage online when deleting the machines, and then redeploy the machines at a later time.
- This needs to be documented further, 

Another option would be to use gs:// instead of hdfs://, or to offload to gs:// before deleting the cluster.
-->


Known Issues
------------

### Re-use of attached persistent disks across deployments

`bdutil` supports keeping attached persistent disks _(aka `ATTACHED_PDS`)_ online when deleting machines. It can then deploy machines using the same attached storage and data.

When reploying HDP in this fashion, the NameNode will fail to format. More details in [this issue](https://github.com/seanorama/bdutil/issues/5).

Feedback & Issues
-----------------

 - <http://github.com/seanorama/bdutil/>
 - <http://twitter.com/seano>

