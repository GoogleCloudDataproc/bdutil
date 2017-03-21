# Shutting Down a Hadoop Cluster

Because [Google Compute Engine](https://cloud.google.com/compute/) charges on a [per-minute basis](https://cloud.google.com/compute/pricing), it can be cost effective to shut down your Hadoop cluster once a workload completes. Once the Hadoop cluster is shut down, your data's accessibility depends on the [default file system](QUICKSTART.md) you've chosen:

* When using HDFS, data is inaccessible.
* When using [Google Cloud Storage](https://cloud.google.com/storage/), data is accessible with [gsutil](https://cloud.google.com/storage/docs/gsutil) or the [Google Cloud Platform Console](https://console.cloud.google.com/?_ga=1.81149463.169096153.1475769191).

**When you delete (shutdown) a cluster, the operation is irreversible.**

## Issuing the delete command

To shut down the Hadoop cluster, use the bdutil file included as part of the setup script. Type `./bdutil delete` in the `bdutil-<version>` directory on the command line to shut down the cluster.

Here is an example of the command being run.

    ~/bdutil-0.35.1$ ./bdutil delete
    Wed Aug 13 16:03:15 PDT 2014: Using local tmp dir for staging files: /tmp/bdutil-20140813-160315
    Wed Aug 13 16:03:15 PDT 2014: Using custom environment-variable file(s): ./bdutil_env.sh
    Wed Aug 13 16:03:15 PDT 2014: Reading environment-variable file: ./bdutil_env.sh
    Delete cluster with following settings?
          CONFIGBUCKET='<CONFIGBUCKET>'
          PROJECT='<PROJECT>'
          GCE_IMAGE='backports-debian-7'
          GCE_ZONE='us-central1-b'
          GCE_NETWORK='default'
          PREFIX='hadoop'
          NUM_WORKERS=2
          MASTER_HOSTNAME='hadoop-m'
          WORKERS='hadoop-w-0 hadoop-w-1'
          BDUTIL_GCS_STAGING_DIR='gs://<CONFIGBUCKET>/bdutil-staging/hadoop-m'
          (y/n) y
    Wed Aug 13 16:03:16 PDT 2014: Deleting hadoop cluster...
    ...Wed Aug 13 16:03:17 PDT 2014: Waiting on async 'deleteinstance' jobs to finish. Might take a while...
    ...
    Wed Aug 13 16:04:11 PDT 2014: Done deleting VMs!
    Wed Aug 13 16:04:11 PDT 2014: Execution complete. Cleaning up temporary files...
    Wed Aug 13 16:04:11 PDT 2014: Cleanup complete.

## Verifying all resources have been removed

You **must** use the same bdutil configuration arguments for cluster creation and deletion. Altering the arguments might result in errors when shutting down the cluster. After the script executes, you can type `gcloud compute instances list --project=<PROJECT> | grep <PREFIX>` and verify that no instances are still running. Similarly, you can type `gcloud compute disks list --project=<PROJECT> | grep <PREFIX>` and verify that no created disks accidentally survived.
