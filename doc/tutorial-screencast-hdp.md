# ![Hortonworks Data Platform](http://hortonworks.com/wp-content/themes/hortonworks/images/layout/header/hortonworks-logo.png) + ![Google Cloud Platform](https://cloud.google.com/_static/images/gcp-logo.png)

Hortonworks Data Platform (HDP) on Google Cloud Platform
========================================================

Deploying Hadoop clusters with **Google's bdutil & Apache Ambari**.

## Resources 

* [Google documentation](https://cloud.google.com/hadoop/) for bdutil & Hadoop on Google Cloud Platform.
* [Latest source on Github](https://github.com/GoogleCloudPlatform/bdutil). Use & improve.
* [Documentation & quickstart for using HDP with bdutil](https://github.com/GoogleCloudPlatform/bdutil/platforms/hdp/README.md).
* [The text you're looking at right now](https://github.com/seanorama/bdutil/blob/master/platforms/hdp/README.md).

## Before you start

* Follow instructions at https://cloud.google.com/hadoop/

    - Google Cloud Platform account & project configured
    - Installed & configured Google Cloud SDK: https://cloud.google.com/hadoop/

    ```
    brew cask install google-cloud-sdk      ## lazy way to install on OSX
    # for other operating systems see: http://cloud.google.com/hadoop/

    gcloud auth login                       ## authenticate to google
    gsutil mb -p hdp-00 gs://hdp-00         ## create a Google Cloud Storage bucket
    gcloud config set project my-hdp-00     ## make it our default project
    ```

    - Download bdutil from https://cloud.google.com/hadoop/

    ```
    git clone https://github.com/seanorama/bdutil/   # using my own repo for this demonstration
    cd bdutil
    ```

## Tutorial

1. Deploy the cluster:

    Only requires the ‘bdutil’ command below, but I recommend checking the configuration in ‘ambari.conf’

    ```
    edit platforms/hdp/ambari.conf                    # not required by worth looking at
    ./bdutil -e platforms/hdp/ambari_env.sh deploy    # deploy the cluster
    ```

1. Administer the cluster:

    ```
    ./bdutil socksproxy             # opens a socks proxy to the cluster at localhost:1080
    open http://hadoop-m:8080/      # My Google Chrome has an extension which automatically uses the proxy
    ```

    ```
    gcloud compute config-ssh               # updates our SSH config
    ssh -L 8080:127.0.0.1:8080 hadoop-m     # quick tunnel to Apache Ambari
    open http://localhost:8080/             # open Ambari in your browser
    ```

1. Use the cluster

    ```
    open https://cloud.google.com/hadoop/running-a-mapreduce-job
    ./bdutil shell < ./doc/tutorial-mapreduce.md
    ```

1. Delete the cluster

    `./bdutil -e platforms/hdp/ambari_env.sh delete`