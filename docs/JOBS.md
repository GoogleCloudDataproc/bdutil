# Jobs

Once you have [created a cluster](QUICKSTART.md) you can submit "jobs" (work) to it. These can be entirely new jobs, or jobs you port from an existing environment.

## Writing Jobs

To learn about how to write Hadoop jobs from the ground up, see the [Apache Hadoop tutorials](https://hadoop.apache.org/docs/current/hadoop-mapreduce-client/hadoop-mapreduce-client-core/MapReduceTutorial.html).

Google Cloud Platform offers input/output data connectors for your Hadoop and Spark jobs:

* [Google BigQuery Connector for Hadoop](https://github.com/GoogleCloudPlatform/bigdata-interop)
* [Google Cloud Storage Connector for Hadoop](https://github.com/GoogleCloudPlatform/bigdata-interop)

## Porting existing jobs

When porting a job from HDFS using the Cloud Storage connector for Hadoop, be sure to use the correct file path syntax (`gs://`).
Also note that `FileSystem.append` is unsupported. If you choose Cloud Storage as your default file system, update your MapReduce, if necessary, to avoid using the append method.

## Running jobs

Once you've set up a Hadoop cluster and have written or ported a job, you can run the job using the following steps.

### Validating your setup and data

First, validate that your cluster is set up, and that you can access your data. Navigate to the command line to execute the following commands.

Type `./bdutil shell` to SSH into the master node of the Hadoop cluster.
Type `hadoop fs -ls .` to check the cluster status. If data outputs, the cluster is set up correctly.

### Running the job

Next, run the job from the command line, while you are still connected to the cluster via SSH. Always run jobs as the `hadoop` user to avoid having to type full Hadoop paths in commands.

The following example runs a sample job called WordCount. Hadoop installations include this sample in the `/home/hadoop/hadoop-install/hadoop-examples-*.jar file.`

To run the WordCount job:

1. Navigate to the command line.
1. Type `./bdutil shell` to SSH into the master node of the Hadoop cluster.
1. Type `hadoop fs -mkdir input` to create the `input` directory.
Note that when using Google Cloud Storage as your [default file system](QUICKSTART.md), input automatically resolves to `gs://$<CONFIGBUCKET>/input`.
1. Copy any file from the web, such as the following example text from Apache, by typing the following command: `curl http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html > setup.html`.
1. Copy one or more text files into the `input` directory. Using the same Apache text in the previous step, type the following command: `hadoop fs -copyFromLocal setup.html input`.
1. Type `cd /hadoop-install/share/hadoop/mapreduce` to navigate to the Hadoop install directory.
1. Type `hadoop jar share/hadoop/mapreduce/hadoop-*-examples-*.jar wordcount input output` to run the job on data in the input directory, and place results in the output directory.

### Checking job status

To check the status of of the Hadoop job, visit the [JobTracker page](http://wiki.apache.org/hadoop/JobTracker). See the [monitoring jobs](MONITORING.md) page for instructions on how to access the JobTracker.

### Cleanup

After completing the job, make sure to [shut down the Hadoop cluster](SHUTDOWN.md) for the most cost effective solution.
