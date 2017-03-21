# bdutil Quickstart

If you want to deploy a Spark and Hadoop cluster manually, you can use `bdutil`, a command line tool, to easily deploy and manage clusters. This page describes how to configure and deploy a cluster using bdutil.

You can run bdutil on any Bash v3 or later shell, either on your own machine or on a Google Compute Engine instance that you own. If you are running bdutil on a Google Compute Engine instance, you can deploy or manage a Spark or Hadoop instance in the same or a different project.

## Before you begin

* You must have [bdutil and gcloud installed](../README.md) on your computer or on a Google Compute Engine instance.
* You must have write permissions to a Google Compute Engine project.

## Set up your shell environment

If you haven't used [`gcloud compute ssh`](https://cloud.google.com/sdk/gcloud/reference/compute/ssh) before for this project on this machine, configure `gcloud compute ssh` by following [the documentation](https://cloud.google.com/compute/docs/instances/connecting-to-instance). Make sure that the tool is configured without a passphrase. You can test your configuration by using [`gcloud compute instances create`](https://cloud.google.com/sdk/gcloud/reference/compute/instances/create) to create a new Compute Engine instance, then using `gcloud compute ssh` to connect to that instance. If you can connect to the instance, your ssh keys are properly configured. Be sure to run [`gcloud compute instances delete`](https://cloud.google.com/sdk/gcloud/reference/compute/instances/delete) after the test.

**When installing software or configuring your instance, you may find it useful to log in as the `hadoop` user explicitly.**
To switch the current user account to the `hadoop` user, run the following command:

    sudo su -l hadoop

If you prefer to always log in as the hadoop user, use the `--command` flag:

    gcloud compute ssh --zone=<hadoop-master-zone> <hadoop-master> \
      --ssh-flag="-t" --command="sudo su -l hadoop"

## Choose a default file system

You'll need to choose a default storage system for your data. The following options are available:

| File system |	Description |
| --- | --- |
| **[Google Cloud Storage](https://cloud.google.com/storage/) [Default]**	| Google Cloud Storage is the easiest, most reliable and most cost-effective way to store large quantities of data persistently in Hadoop on Google Cloud Platform. Use the [Google Cloud Storage connector for Hadoop](https://github.com/GoogleCloudPlatform/bigdata-interop/tree/master/gcs) to connect seamlessly to Cloud Storage, either on the command-line or as part of a MapReduce. Additional benefits include interoperability with other Google services, automatic capacity scaling, and high data availability. |
| **Hadoop Distributed File System (HDFS)** |	Hadoop Distributed File System (HDFS) is the default file system when using Apache Hadoop. While we recommend using Cloud Storage as your default, you may want to use HDFS instead if you'd like to quickly try out Hadoop on Google Cloud Platform with pre-existing jobs. HDFS is scalable across VMs, but doesn't scale per instance as well as Cloud Storage due to VM disk bandwidth limits. Data can be made persistent if you specify [persistent disk](https://cloud.google.com/compute/docs/disks/persistent-disks). It is more expensive than the other options. To make this the default storage system, change `DEFAULT_FS` in **bdutil_env.sh**. For more information, see the [Apache HDFS Users Guide](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html). |

You can also enable programmatic access to [Google BigQuery](https://github.com/GoogleCloudPlatform/bigdata-interop/tree/master/bigquery).

## File path syntax

All *non-Hadoop-aware commands* assume local file storage for paths without any transport prefix. That means `ls /tmp/` refers to `/tmp` on your local instance drive.

All *Hadoop-aware commands* assume the default Hadoop storage system — either Cloud Storage or HDFS — for paths without a transport prefix — for example, `ls /tmp` refers to `/tmp` on your command line, or `SparkContext.textFile(/tmp/)` in code, refer to a file in your default Hadoop storage system.

If you need to access data for a Hadoop-aware command in the non-default file system you must fully qualify the path. Otherwise, you can use a simplified path syntax, as shown in the table below:

| File location	| Cloud Storage is the default file system	| HDFS is the default file system |
| --- | --- | --- |
| Cloud Storage default bucket | `gs://<default_bucket>/dir/file` OR `dir/file` | `gs://<default_bucket>/dir/file` |
| Cloud Storage non-default bucket	| `gs://<alternate bucket>/dir/file` |	`gs://<alternate bucket>/dir/file` |
| HDFS	| `hdfs://<host>:8020/dir/file` | `hdfs://<host>:8020/dir/file` OR `hdfs:/dir/file` OR `/dir/file` |

**Tip** - To determine your default Cloud Storage bucket, run one of the following commands:

    hadoop org.apache.hadoop.conf.Configuration | grep fs.default

    cat /home/hadoop/hadoop-install/etc/hadoop/core-site.xml | grep -A1 default

## Configure your deployment

**The default configuration is Hadoop 1 with Cloud Storage as the storage system.** Other configuration defaults are listed in the downloaded `bdutil_env.sh` file. To specify Hadoop 2 in `bdutil`, specify `--env_var_files hadoop2_env.sh` in your `bdutil` deployment command.

The `bdutil` tool is used to deploy or stop instances. Instance settings are configured using command-line flags. However, as a convenience, we have provided shell scripts that set many of these flags and perform environment setup for useful Hadoop configurations. You can specify one or more of these shell scripts as input to bdutil to configure your environment. The setup package includes the following configuration files:

* **`bdutil_env.sh`** The base configuration. It is always run by bdutil; you do not need to specify it. Modify this script to apply your specific project and base configuration details.
single_node_env.sh Deploys a pseudo-distributed cluster with all of the required Hadoop components running on a single VM.
* **`hadoop2_env.sh`** Deploys a cluster with the [latest stable version of Hadoop 2.x](http://hadoop.apache.org/docs/current/) instead of the traditional Hadoop 1.x version.
* **`bigquery_env.sh`** Deploys a cluster with the [BigQuery connector](https://github.com/GoogleCloudPlatform/bigdata-interop/tree/master/bigquery) for Hadoop installed. Not compatible with hadoop2_env.sh.
* **`extensions/querytools/querytools_env.sh`** Deploys a cluster with [Apache Pig](http://pig.apache.org) and [Apache Hive](http://hive.apache.org) installed. Not compatible with `hadoop2_env.sh`.
* **`extensions/spark/spark_env.sh`** Deploys a cluster with [Apache Spark](http://spark.apache.org) installed.

Specify one or more of the above configuration files using the `--env_var_files` flag. Do not specify the base `bdutil_env.sh` script, which is always run. For example, the following command deploys a 5-worker cluster (`-n 5`) with the prefix `my-cluster`, assigning the default Cloud Storage bucket to be `foo-bucket`, with BigQuery connector Hive, and Pig on each instance.

    ./bdutil --bucket foo-bucket -n 5 -P my-cluster \
       --env_var_files bigquery_env.sh,querytools_env.sh deploy

If you pass in multiple files, values in later files override values in earlier files if the values conflict.

Run `./bdutil --help` for documentation and examples of running the tool to configure, deploy, or delete your instance.

You can save your common flag settings in a custom config file using the `--generate_config` command. Run `./bdutil --help` for an example.

### Writing custom environment variable configuration files

You can also write custom configuration files. The following table describes important environment variables that you may want to specify.

| Environment variable	| Description | Default |
| --- | --- | --- |
| `CONFIGBUCKET` | A required variable that must either be set before running the setup script or at runtime using the `--bucket` (even if you don't plan to use Google Cloud Storage as your default file system.) This environment variable specifies the Cloud Storage bucket that is used for sharing generated SSH keys and configuration values. The Cloud Platform PROJECT specified, must have Can edit permissions to the bucket. For more information about service accounts, see [Authenticating From Google Compute Engine](https://cloud.google.com/compute/docs/authentication#whatis). In the event no project is specified in bdutil_env.sh or using the --project flag at runtime, then the default project configured with gcloud will be used, see [Managing authentication and credentials with gcloud](https://cloud.google.com/sdk/gcloud/#gcloud.auth). | None. |
| `PROJECT` | The Google Cloud Platform project ID that the setup script uses to create Google [Compute Engine instances](https://cloud.google.com/compute/docs/instances). If not specified, this configuration variable is set to the [default project ID](https://cloud.google.com/sdk/gcloud/#gcloud.auth) used by gcloud. | Default project ID. |
| `DEFAULT_FS` | The default file system for the Hadoop cluster. Set `hdfs` for HDFS, and `gs` for Cloud Storage. | `gs` |
| `GCE_MACHINE_TYPE` | The [machine type](https://cloud.google.com/compute/docs/instances) of the Google Compute Engine instance. Each node in the Hadoop cluster is set to this machine type. | `n1-standard-4` |
| `GCE_ZONE` | The [zone](https://cloud.google.com/compute/docs/zones) of the Google Compute Engine instance. Each node in the Hadoop cluster is set to this zone. This value may need to be updated occasionally due to [scheduled zone maintenance windows](https://cloud.google.com/compute/docs/zones#maintenance). | `us-central1-a` |
| `GCE_SERVICE_ACCOUNT_SCOPES` |  The comma-separated list of [Service-Account scopes](https://cloud.google.com/compute/docs/authentication) to enable for your instances. `storage-full` is a required scope value for gsutil and the [Google Cloud Storage connector for Hadoop](https://github.com/GoogleCloudPlatform/bigdata-interop/tree/master/gcs). | `storage-full` |
| `HADOOP_TARBALL_URI` |  The URI of the Hadoop tarball to be deployed on the cluster. The value must begin with `gs://` or `http(s)://` and can be any URI source that contains a 1 file, such as an Apache mirror or your own Cloud Storage bucket. Supported tarballs include `hadoop-1.2.1-bin.tar.gz` and `hadoop-2.4.1.tar.gz`. To use Hadoop 2.X, copy or edit `hadoop2_env.sh` instead of relying on this variable since there are significant setup differences between Hadoop 1.x and Hadoop 2.x. | `gs://hadoop-dist/hadoop-1.2.1-bin.tar.gz` |
| `JAVAOPTS` | Options that TaskTracker nodes use when creating child JVM processes. For more information about these options, see Task Execution & Environment. | `-Xms1024m -Xmx2048m` |
| `NUM_WORKERS` | The number of worker nodes in the Hadoop cluster. | `2` |
| `PREFIX` | The prefix that [Google Compute Engine](https://cloud.google.com/compute/) appends to each [instance name](https://cloud.google.com/compute/docs/instances) in the Hadoop cluster. | `hs-ghfs` |
| `ENABLE_HDFS` | Controls whether or not to configure and start HDFS on the deployed cluster. This value must be set to `true` if `DEFAULT_FS` is set to hdfs. | `true` |
| `USE_ATTACHED_PDS` | Indicates if a [persistent disk](https://cloud.google.com/compute/docs/disks/persistent-disks#attach_disk) should be created and attached to each [instance](https://cloud.google.com/compute/docs/instances) in the Hadoop cluster. The related `CREATE_ATTACHED_PDS_ON_DEPLOY` property controls if `bdutil` will first create the persistent disk. After the persistent disk is optionally created, bdutil attaches the persistent disk to the instance by using the `gcloud compute instances create` command. By default, the persistent disk name is the instance name, followed by a `-pd` suffix. | `false` |
| `CREATE_ATTACHED_PDS_ON_DEPLOY` | Indicates if `bdutil` should create a persistent disk for the instance. If `CREATE_ATTACHED_PDS_ON_DEPLOY` is set to `true`, bdutil creates a non-root persistent disk by calling `gcloud compute instances create`. If `false`, bdutil assumes that the persistent disk exists and does not need to be created. This property is only used if the `USE_ATTACHED_PDS property` is set to `true`. | `true` |
| `DELETE_ATTACHED_PDS_ON_DELETE` | Indicates if the persistent disk should be deleted when the [cluster shuts down](SHUTDOWN.md). This property is only used if the `USE_ATTACHED_PDS` property is set to `true`. If you want to persist HDFS data between cluster deployments, set this property to `false` **before shutting down the cluster**, and set `CREATE_ATTACHED_PDS_ON_DEPLOY` to `false` the next time you deploy the same instance name. | `true` |
| `WORKER_ATTACHED_PDS_SIZE_GB` | Specifies the size in GB of the persistent disk that will be attached to each worker node instance. This property is only used if `USE_ATTACHED_PDS` is set to `true` and `CREATE_ATTACHED_PDS_ON_DEPLOY` is set to `true`. | `500` |
| `NAMENODE_ATTACHED_PD_SIZE_GB` | Specifies the size in GB of the persistent disk that will be attached to each name node instance. This property is only used if `USE_ATTACHED_PDS` is set to `true` and `CREATE_ATTACHED_PDS_ON_DEPLOY` is set to `true`. | `500` |

### Deploy your instances

Navigate to the the `bdutil-*` directory on the command line, then type the following:

    ./bdutil deploy --bucket <configuration-bucket> <any other flags>

#### For example:

    ./bdutil --bucket foo-bucket -n 5 -P my-cluster \
      --env_var_files bigquery_env.sh,datastore_env.sh deploy

Deployment can take a few minutes. The script prints "Deployment complete" on the command line when the cluster is up.

You are currently limited to a single master per Hadoop cluster on Google Compute Engine. When using bdutil you can add multiple clusters to a project.

When you deploy a Hadoop machine, the Hadoop software is installed under `/home/hadoop`. All users who can SSH into the Hadoop master will have all of the necessary Hadoop-related variables set in their shell environment automatically. This means you can run Hadoop jobs with no additional configuration. .

### Is an instance a master or worker?

By default, workers are named `hadoop-w-****` and masters are named `hadoop-m-****`. On the command line, run gcloud [`compute instances describe <instance_name>`](https://cloud.google.com/sdk/gcloud/reference/compute/instances/describe) which may display tags indicating the role of an instance.

## Troubleshooting deployment

During deployment, `bdutil` runs remote setup commands with **stdout** and **stderr** piped into files on the instances. You can view these files for debugging purposes by:

1. Using `gcloud compute ssh` to log into the instance
1. Navigating to your home directory, then viewing the `*.stderr` and `*.stdout` files or uploading the files to Cloud Storage.
