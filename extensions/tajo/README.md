Deploying Apache Tajo™ on Google Cloud Platform
===============================================

Apache Tajo
-----------

Apache Tajo is a robust big data warehouse system. Dubbed "an SQL-on-Hadoop", Tajo is optimized for running low-latency, scalable ad-hoc queries and ETL jobs on large data sets stored on both HDFS and other data sources including Amazon S3 and Google Cloud Storage. By supporting SQL standards and leveraging advanced query optimization techniques, Tajo support both interactive analysis and complex ETL in a single solution.

This documents explains how to setup Tajo cluster on Google Cloud Platform using bdutil.

Getting Started
---------------

1. Install gcloud SDK

    https://cloud.google.com/sdk/

2. Install bdutil Tajo extension

    $ git clone https://github.com/GoogleCloudPlatform/bdutil.git

3. Configure

    $ vi  bdutil_env.sh

    ```
    ############### REQUIRED ENVIRONMENT VARIABLES (no defaults) ##################

    # A GCS bucket used for sharing generated SSH keys and GHFS configuration.
    CONFIGBUCKET="YOUR_BUCKET"

    # The Google Cloud Platform text-based project-id which owns the GCE resources.
    PROJECT="YOUR_PROJECT_ID"

    ###############################################################################

    GCE_ZONE="YOUR_ZONE"

    # change it to your instance type.
    GCE_MACHINE_TYPE='n1-standard-4'

    # number of worker nodes
    NUM_WORKERS=2

    # Prefix to be shared by all VM instance names in the cluster, as well as for
    # SSH configuration between the JobTracker node and the TaskTracker nodes.
    PREFIX='tajo'
    ```

    $ vi extensions/tajo/tajo_env.sh

    ```
    # path to tajo tarball
    TAJO_TARBALL_URI='gs://PATH_TO_TAJO_TARBALL/tajo-x.xx.x.tar.gz'
    ```

4. Using cloudSQL for Tajo meta store (optional)

By default, Tajo stores its meta data in built-in Derby database in Tajo master node. Since it is ephemeral storage, you'd better use it for test purpose only. For continuous analysis work, using permanent meta store such as cloudSQL is strongly recommended.

To use existing cloudSQL or MySQL instance for Tajo meta store, set the instance id and connection information.
Tajo master node need to be allowed to connect catalog server.

    $ vi extensions/tajo/tajo_env.sh

    ```
    CATALOG_HOST="YOUR_DBMS_HOST"
    CATALOG_ID="YOUR_DBMS_ID"
    CATALOG_PW="YOUR_DBMS_PW"
    CATALOG_DB=tajo
    ```

To use Derby, leave it blank.

Deployment
----------

To deploy Tajo with Hadoop2 daemon:

    $ ./bdutil -e hadoop2,tajo deploy

Destroy
-------

To delete Tajo cluster:

    ./bdutil -e delete

Or specify PREFIX,

    ./bdutil -P tajo delete

Basic Usage
-----------

By default, Tajo install directory is /home/hadoop/tajo-install.

SSH to Tajo master node:

    gcloud compute ssh --project=YOUR_PROJECT_ID --zone=YOUR_ZONE hadoop-m --ssh-flag="-t" --command="sudo su -l hadoop"

Run Tajo command line shell (tsql):

    /home/hadoop/tajo-install/bin/tsql

Or simply,

    tsql

To stop and start Tajo daemon (Should run as "hadoop" user):

    stop-tajo.sh
    start-tajo.sh

To check Tajo status, see Tajo web UI in your browser:

    http://TAJO_MASTER_NODE_IP:26080/

To connect Tajo from your desktop (eg. via SQL workbench tools), JDBC connection string looks like:

    jdbc:tajo://TAJO_MASTER_NODE_IP:26002/dbname

Note that 26080 and 26002 port need to be open.

Advanced Configuration
----------------------

Refer to Tajo configuration documents for advanced configuration. (http://tajo.apache.org/docs/current/configuration.html)

Status
------

This plugin is currently considered experimental and not officially supported.
Contributions are more than welcome.

