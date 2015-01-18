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
	- Installed & configured Google Cloud SDK
	- Downloaded bdutil

## Tutorial

1. Deploy the cluster:

    `./bdutil -e platforms/hdp/ambari_env.sh deploy`  

2. Administer the cluster:

    ```
    gcloud compute config-ssh            # updates our SSH config
    ssh -L 8080:127.0.0.1:8080 hadoop-m	 # quick tunnel to Apache Ambari
    open http://localhost:8080/			 # open Ambari in your browser
    ```

3. Use the cluster

    ```
    MapReduce
    ```

1. Delete the cluster

    `./bdutil -e platforms/hdp/ambari_env.sh delete`
    
-----

### Sean's speaking notes

> Hi. I'm Sean Roberts with Hortonworks Partner Solutions. In this recording I'll show how to easily deploy & use Hadoop on the Google Cloud Platform.
>
> Thanks to the engineering partnership between Google & Hortonworks you can deploy the Hortonworks Data Platform in a single command.
> 
> Let's start with an overview of the technology.
> 
> - Infrastructure will be provided by the Google Cloud Platform:
>   - Google Compute Engine for our machines
>   - Google Cloud Storage for cluster configuration files & will also be integrated into HDP to be used as an additional storage option to HDFS, the Hadoop File System
>
>  
> - We'll use Google's bdutil for quickly deploying the cluster.
>   - Visit cloud.google.com/hadoop for much more detail about bdutil and using Hadoop at Google
> - bdutil will leverage
>   - Apache Ambari for provisioning, managing and monitoring the cluster.
>   - Ambari's "blueprint recommendation" system will take care of all the configuration for you resulting in a fully configured
>   - Hortonworks Data Platform cluster.
> 



















d






