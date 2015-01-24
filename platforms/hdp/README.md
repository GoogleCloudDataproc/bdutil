# ![Hortonworks Data Platform](http://hortonworks.com/wp-content/themes/hortonworks/images/layout/header/hortonworks-logo.png) + ![Google Cloud Platform](https://cloud.google.com/_static/images/gcp-logo.png)

Hortonworks Data Platform (HDP) on Google Cloud Platform
========================================================

This extension, to Google's [bdutil](https://github.com/GoogleCloudPlatform/bdutil), provides support for deploying the [Hortonworks Data Platform](http://hortonworks.com/) with a single command. 

The extension utilizes Apache Ambari's Blueprint Recommendations to fully configure the cluster without the need for manual configuration.

Resources
---------

* [Google documentation](https://cloud.google.com/hadoop/) for bdutil & Hadoop on Google Cloud Platform.
* [Source on Github](https://github.com/GoogleCloudPlatform/bdutil). Open to the community and welcoming your collaboration.

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

### Can I set/override Hadoop configurations during deployment?

For adding/overriding Hadoop configurations, update `configuration.json` and then  use the extension as documented. And contribute back if you think the defaults should be changed.

### Can I deploy HDP manually using Ambari and/or use my own Ambari Blueprints?

Yes. Set `ambari_manual_env.sh` as your environment _(with the -e switch)_ instead of `ambari_env.sh`. That will configure Ambari across the cluster & handle all HDP prerequisites, but not trigger the Ambari Blueprints which install HDP.

Note that these steps will not be taken for you:

  - initialization of HDFS /user directories _(Check the function `initialize_hdfs_dirs` in `../../libexec/hadoop_helpers.sh`)_
  - installation of the GCS connector. _(Check `./install_gcs_connector_on_ambari.sh` & `./update_ambari_config.sh`)_

### Can I re-use the attached persistent disk(s) across deployments?

`bdutil` supports keeping persistent disks _(aka `ATTACHED_PDS`)_ online when deleting machines. It can then deploy a new cluster using the same disks without lose of data, **assuming the number of workers is the same**.

The basic commands are below. Find more detail in [TEST.md](./TEST.md).

```
## deploy the cluster & create disks
./bdutil -e platforms/hdp/ambari_env.sh deploy

## delete the cluster but don't delete the disks
export DELETE_ATTACHED_PDS_ON_DELETE=false
./bdutil -e platforms/hdp/ambari_env.sh delete

## create with existing disks
export CREATE_ATTACHED_PDS_ON_DEPLOY=false
./bdutil -e platforms/hdp/ambari_env.sh deploy
```

Another would be to use `gs://` _(Google Cloud Storage)_ instead of `hdfs://` in your Hadoop jobs, even setting it as the default. Or backup HDFS to Google Cloud Storage before cluster deletion.

**Note**: Hortonworks can't guarantee the safety of data throughout this process. You should always take care when manipulating disks and have backups where necessary.

### What are the built-in storage options?

By default, HDFS is on **attached disks** _('pd-standard' or 'pd-ssd')_.
- the size and type can be set in `ambari.conf`
 
The rest of the system resides on the **local boot disk**, unless configured otherwise.
 
**Google Cloud Storage** is also available with **`gs://`**. It can be used anywhere that `hdfs://` is available, such as but not limited to mapreduce & `hadoop fs` operations.

  - Note: Adding an additional slash (`gs:///`) will allow you to use the default bucket (defined at cluster build) without needing to specific it.

### Can I deploy in the Google Cloud Platform _Free Trial_ ?

You may use bdutil with HDP by lowering the machine type & count below the recommended specifications. To use the default configuration, upgrade the account from a free trial.

  * In 'platforms/hdp/ambari.conf':
    * `GCE_MACHINE_TYPE='n1-standard-2'`
    * `WORKERS=3 # or less`
  * Or at the command-line provide these switches to the 'deploy' & 'delete':
    * Deploy cluster: `-n 3 -m n1-standard-2`

Known Issues
------------


Feedback & Issues
-----------------

 - <http://github.com/seanorama/bdutil/>
 - <http://twitter.com/seano>

License
-------

[Apache License, Version 2.0](../../LICENSE)
