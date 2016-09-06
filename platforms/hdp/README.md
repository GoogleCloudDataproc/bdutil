# <img src="http://hortonworks.com/wp-content/themes/hortonworks/images/logo.png" width="300" /> + <img src="https://cloud.google.com/_static/images/cloud/gcp-logo.svg" width="400" />

Hortonworks Data Platform (HDP) on Google Cloud Platform
========================================================

This extension, to Google's [`bdutil`](https://github.com/GoogleCloudPlatform/bdutil), provides support for deploying the [Hortonworks Data Platform](http://hortonworks.com/) with a single command.

The extension utilizes Apache Ambari's Blueprint Recommendations to fully configure the cluster without the need for manual configuration.

Resources
---------

* [Google Cloud Platform documentation](https://cloud.google.com/hadoop/) for `bdutil` & Hadoop on Google Cloud Platform.
* [Source on GitHub](https://github.com/GoogleCloudPlatform/bdutil). Open to the community and welcoming your collaboration.

Video Tutorial
--------------

[<img src="http://img.youtube.com/vi/raCtS84Vb6w/0.jpg" width="320px" />](http://www.youtube.com/watch?v=raCtS84Vb6w)

Before you start
----------------

#### Create a Google Cloud Platform account

* Open [Google Cloud Console](https://console.cloud.google.com/)
* Sign-in or create an account
* The "free trial" [may be used](#questions)

#### Create a Google Cloud Project

* Open [Google Cloud Console](https://console.cloud.google.com/)
* Open 'Create Project' and fill in the details.
  - As an example, this document uses `hdp-00`
- Within the project, open 'APIs & auth -> APIs'. Then enable:
  - Google Compute Engine
  - Google Cloud Storage
  - Google Cloud Storage JSON API

#### Configure Google Cloud SDK & Google Cloud Storage

* Install [Google Cloud SDK](https://cloud.google.com/sdk/) locally
* Configure the SDK:

  ```sh
  gcloud auth login                   # authenticate to Google Cloud Platform
  gcloud config set project hdp-00    # set the default project
  gsutil mb -p hdp-00 gs://hdp-00     # create a Google Cloud Storage bucket
  ```

#### Download `bdutil`

* [Latest packaged version](https://cloud.google.com/hadoop/downloads)
* Latest sorce from GitHub:

   ```sh
   git clone https://github.com/GoogleCloudPlatform/bdutil
   cd bdutil
   ```

Quick start
-----------

1. Set your project & bucket from above in `bdutil_env.sh`

1. Deploy or Delete the cluster:

* Deploy: `./bdutil -e ambari deploy`
* Delete: `./bdutil -e ambari delete`
  * when deleting, ensure to use the same switches/configuration as the deploy

See `./bdutil --help` for more details.

Configuration
-------------

* You can deploy without setting any configuration, but take a look at [`ambari.conf`](ambari.conf).

Here are some of the defaults to consider:

  ```sh
  GCE_ZONE='us-central1-a'           # the zone/region to deploy in
  NUM_WORKERS=4                      # the number of worker nodes. Total
                                     #     is NUM_WORKERS + 1 master
  GCE_MACHINE_TYPE='n1-standard-4'   # the machine type
  WORKER_ATTACHED_PDS_SIZE_GB=1500   # 1500GB attached to each worker
  MASTER_ATTACHED_PD_SIZE_GB=1500    # 1500GB attached to master

  # The Hortonworks Data Platform services which will be installed.
  # This is nearly the entire stack.
  AMBARI_SERVICES="ACCUMULO AMBARI_METRICS ATLAS FALCON FLUME GANGLIA HBASE HDFS
      HIVE KAFKA MAHOUT MAPREDUCE2 OOZIE PIG SLIDER SPARK SQOOP STORM TEZ YARN
      ZOOKEEPER"

  AMBARI_PUBLIC=false                # Services listed on internal
                                     # hostname not public IP. Need
                                     # a socks proxy or tunnel to access.
  ```

Use the cluster
---------------

### SSH

* You'll have immediate SSH access with: `./bdutil shell`
* Or update your SSH config with: `gcloud compute config-ssh`

#### Access Ambari & other services

a. With a local socks proxy:

  ```sh
  ./bdutil socksproxy             # opens a socks proxy to the cluster at localhost:1080

  # I use the Chrome extension 'Proxy SwitchySharp' to automatically detect
  # when connecting to Google Compute Engine.
  open http://hadoop-m:8080/      # My Google Chrome has an extension
                                  # which automatically uses the proxy
  ```

b. Or with a local SSH tunnel:

  ```sh
  gcloud compute config-ssh                  # updates our SSH config for direct SSH access to all nodes
  ssh -L 8080:127.0.0.1:8080 hadoop-m  <TAB> # quick tunnel to Apache Ambari
  open http://localhost:8080/                # open Ambari in your browser
  ```

c. Or open a firewall rule from the [Google Cloud Console](https://console.cloud.google.com/)

#### Use the cluster

You now have a full HDP cluster. If you are new to Hadoop, take alook at [the tutorials](http://hortonworks.com/). For command-line based jobs, `bdutil` provides [methods for passing through commands](https://cloud.google.com/hadoop/running-a-mapreduce-job), e.g.,

```sh
./bdutil shell < ./extensions/google/gcs-validate-setup.sh
```

Questions
---------

### Can I set/override Hadoop configurations during deployment?

For adding/overriding Hadoop configurations, update [`configuration.json`](configuration.json) and then use the extension as documented. And contribute back if you think the defaults should be changed.

### Can I deploy HDP manually using Ambari and/or use my own Ambari Blueprints?

Yes. Set [`ambari_manual_env.sh`](ambari_manual_env.sh) as your environment (with the `-e` switch) instead of [`ambari_env.sh`](ambari_env.sh). That will configure Ambari across the cluster & handle all HDP prerequisites, but not trigger the Ambari Blueprints which install HDP.

After manually deploying your cluster, you can use

```sh
./bdutil <YOUR_FLAGS> -e platforms/hdp/ambari_manual_post_deploy_env.sh run_command_steps
```

to configure HDFS directories and install the GCS connector. Note that it uses `run_command_steps` instead of `deploy`.

### Can I re-use the attached persistent disk(s) across deployments?

`bdutil` supports keeping persistent disks (aka `ATTACHED_PDS`) online when deleting machines. It can then deploy a new cluster using the same disks without loss of data, assuming the number of workers is the same.

The basic commands are below. Find more detail in [TEST.md](./TEST.md).

```sh
# deploy the cluster & create disks
./bdutil -e ambari deploy

# delete the cluster but don't delete the disks
export DELETE_ATTACHED_PDS_ON_DELETE=false
./bdutil -e ambari delete

# create with existing disks
export CREATE_ATTACHED_PDS_ON_DEPLOY=false
./bdutil -e ambari deploy
```

Another approach to retain data across cluster deployments would be to use `gs://` (Google Cloud Storage) instead of `hdfs://` in your Hadoop jobs, even setting it as the default, or backup HDFS to Google Cloud Storage before cluster deletion.

Note: Hortonworks can't guarantee the safety of data throughout this process. You should always take care when manipulating disks and have backups where necessary.

### What are the built-in storage options?

By default, HDFS is on attached disks (`pd-standard` or `pd-ssd`); the size and type can be set in [`ambari.conf`](ambari.conf). The rest of the system resides on the local boot disk, unless configured otherwise.

Google Cloud Storage is also available with `gs://`. It can be used anywhere that `hdfs://` is available, such as but not limited to MapReduce & `hadoop fs` operations. Note: adding an additional slash (`gs:///`) will allow you to use the default bucket (defined at cluster build) without needing to specify it.

### Can I deploy in Google Cloud Platform using the free trial?

Yes, you can use `bdutil` with HDP by lowering the machine type & count below the recommended specifications. To use the default configuration, upgrade the account from a free trial.

  * In [`ambari.conf`](ambari.conf):

    ```
    GCE_MACHINE_TYPE=n1-standard-2
    WORKERS=3 # or less
    ```

  * Or at the command-line provide these switches to the `deploy` & `delete`: `-n 3 -m n1-standard-2`

Feedback & Issues
-----------------

 - <http://github.com/seanorama/bdutil/>
 - <http://twitter.com/seano>

License
-------

[Apache License, Version 2.0](../../LICENSE)
