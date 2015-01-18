bdutil
======

Utility for creating a Google Compute Engine cluster and installing, configuring, and calling Hadoop and Hadoop-compatible software on it.
More details here: https://cloud.google.com/hadoop/setting-up-a-hadoop-cluster

Requirements
------------

### Create a Google Cloud Platform account

  - Open https://console.developers.google.com/
  - If not already present, open an account
    - The "free trial" can be used though will be limited in performance
      - _It's quota permits permits 4 small instances (n1-standard-2). For performance/production it's recommended to upgrade the account and/or request more quota to enable larger instance types (n1-standard-4 or larger)._

### Configure Google Cloud SDK

  - Install [Google Cloud SDK](https://cloud.google.com/sdk/) on your workstation or control machine
  - In a terminal execute: `gcloud auth login`

### Create and prep a Google Cloud Project

  - Open https://console.developers.google.com/
  - Open 'Create Project' and fill in the details.
    - This document uses: 'my-project-00'
  - Within the project, open 'APIs & auth -> APIs'. Then enable:
    - Google Compute Engine
    - Google Cloud Storage
    - Google Cloud Storage JSON API
  - Create Storage Container: `gsutil mb -p my-project-00 gs://my-project-00`
  - _(optional)_ Set the default project: `gcloud config set project my-project-00`

Installation & Configuration
----------------------------

* Get bdutil:
  * `git clone https://github.com/GoogleCloudPlatform/bdutil; cd bdutil`
  * or https://github.com/GoogleCloudPlatform/bdutil/archive/master.zip

* Set your bucket & container in:
  * `bdutil_env.sh` or `platforms/hdp/ambari.conf`
  * or with these switches to `bdutil`: `-b my-project-00 -p my-project-00`
* Nothing else is required, but you should have a look at `platforms/hdp/ambari.conf`

Usage
-----

### Deploy & Delete the cluster
* Deploy cluster: `./bdutil -e platforms/hdp/ambari_env.sh deploy`
* Delete cluster: `./bdutil -e platforms/hdp/ambari_env.sh delete`
  * ensure to use the same switches as the deploy

Common switches, see 'bdutil --help' for more:
  * -n 4 # number of worker nodes to deploy. Default: 4
  * -m n1-standard-4 # machine type. Default: n1-standard-4

Common configuration changes in `platforms/hdp/ambari_config.sh`:
  * AMBARI_SERVICES= # This defines the Hadoop Services which are deployed
    * Default: FALCON FLUME GANGLIA HBASE HDFS HIVE KAFKA KERBEROS MAPREDUCE2 NAGIOS OOZIE PIG SLIDER SQOOP STORM TEZ YARN ZOOKEEPER
  * AMBARI_PUBLIC= # By default, links to services in Ambari will use the internal (10.) IP & names. Setting this to true will have it use the public IP.
    * Default: false


### Access cluster via SSH

Several options:
  - `./bdutil shell` <- this is preferred
  - 0r with an updated SSH config:
    - `gcloud compute config-ssh`
    - `ssh hadoop-m.us-central1-a.my-project-00`
  - 0r use gcloud tools:
    - `gcloud --project=my-project-00 compute ssh --zone=us-central1-a hadoop-m`


### Access Ambari other services

Ambari is available at http://hadoop-m:8080/ .
You can access it and other services in a few ways:
  - a) quick SSH tunnel
  - b) SOCKS proxy (provided by bdutil)
  - c) directly if your Google Cloud project’s firewall rules permit

a) Quick SSH tunnel _(assuming nothing is listening locally on 8080)_
  - Update your SSH config: `gcloud compute config-ssh`
  - Create the tunnel: `ssh -L 8080:127.0.0.1:8080 hadoop-m` (tab complete to get the hostname or check ~/.ssh/config)
  - open http://127.0.0.1:8080/

b) SOCKS proxy:
  * bdutil will create a proxy on port 1080: `./bdutil socksproxy`
  * Update your browser or system to use the SOCKS proxy.
  * You’ll then have full access to the cluster.
    * For example, Ambari Server will be at http://hadoop-m:8080/

c) directly by opening the Google firewall:
  * Update the network firewall rules for your project from the Google Cloud Platform Console
  * Or issue a command such as this which whitelists your current IP: `gcloud compute firewall-rules create whitelist --project my-project-00 --allow tcp icmp --network default --source-ranges `curl -s4 icanhazip.com`/32`


Common issues
=============

### Tip for 'Free Trial' users, those with limited quota, or simply looking to see a cluster without spending much

This is not recommended for performance or production use.

Set the following in `platforms/hdp/ambari.conf`
  * GCE_MACHINE_TYPE='n1-standard-2`
  * WORKERS=3 # or less

Or set that configuration at  command-line:
* Deploy cluster: `./bdutil -e platforms/hdp/ambari_env.sh -n 3 -m n1-standard-2 deploy`
