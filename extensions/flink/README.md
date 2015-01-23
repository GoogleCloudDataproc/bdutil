Deploying Flink on Google Compute Engine
========================================

Set up a bucket
----------------

If you have not done so, create a bucket for the bdutil config and
staging files. A new bucket can be created with the gsutil:

    gsutil mb gs://<bucket_name>


Adapt the bdutil config
-----------------------

To deploy Flink with bdutil, adapt at least the following variables in
bdutil_env.sh.

    CONFIGBUCKET="<bucket_name>"
    PROJECT="<compute_engine_project_name>"
    NUM_WORKERS=<number_of_workers>


Bring up a cluster with Flink
-----------------------------

To bring up the Flink cluster on Google Compute Engine, execute:

    ./bdutil -e extensions/flink/flink_env.sh deploy

To run a Flink example job:

    ./bdutil shell
    curl http://www.gutenberg.org/cache/epub/2265/pg2265.txt > text
    gsutil cp text gs://<bucket_name>/text
    cd /home/hadoop/flink-install/bin
    ./flink run ../examples/flink-java-examples-*-WordCount.jar gs://<bucket_name>/text gs://<bucket_name>/output