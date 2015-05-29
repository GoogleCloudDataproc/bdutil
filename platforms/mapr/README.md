MapR Cluster on Google Compute Engine
-------------------------------------

The [MapR distribution](https://www.mapr.com/products/mapr-distribution-including-apache-hadoop) for Hadoop adds enterprise-grade features to the Hadoop platform that make Hadoop easier to use and more dependable. The MapR distribution for Hadoop is fully integrated with the [Google Compute Engine (GCE)](https://cloud.google.com/compute/) framework, allowing customers to deploy a MapR cluster with ready access to Google's cloud infrastructure. MapR provides network file system (NFS) and open database connectivity (ODBC) interfaces, a comprehensive management suite, and automatic compression. MapR provides high availability with a no-NameNode architecture and data protection with snapshots, disaster recovery, and cross-cluster mirroring.

### Make sure you have...
* an active [Google Cloud Platform](https://console.developers.google.com/) account.
* a client machine with [Google Cloud SDK](https://cloud.google.com/sdk/) and [bdutil](https://cloud.google.com/hadoop/downloads) installed.
* access to a GCE project where you can add instances, buckets and disks.
* a valid MapR license (optional).

### Now, to launch a MapR Cluster on GCE using `bdutil`...

1. Set the project and bucket in `mapr_env.sh` (located under `bdutil/platforms/mapr/`).
2. Update `node.lst` to determine the [allocation of cluster roles](http://doc.mapr.com/display/MapR/MapR+Cluster+on+the+Google+Compute+Engine#MapRClusterontheGoogleComputeEngine-gce-config) for the nodes in the cluster. For reference, the config file contains a simple 4-node [M7](https://www.mapr.com/products/hadoop-download) cluster allocation.
	* Node names must have the PREFIX mentioned in `mapr_env.sh`
	* Node names must have suffixes: -m, -w-0, -w-1, -w-2 ...
	For example, if the PREFIX is 'mapr', node names must be 'mapr-m', 'mapr-w-0', 'mapr-w-1', ... 
	* NUM_WORKERS in `mapr_env.sh` must equal one less than number of nodes in `node.lst`
3. (Optional) Copy a valid license into `mapr_license.txt`
4. Deploy the cluster by invoking in the bdutil root directory: 
	```
	./bdutil -e mapr deploy
	```

5. Access the cluster by invoking: 
	```
	gcloud compute config-ssh
	``` 

	The output shows how to ssh into a node. Login as the `MAPR_USER` mentioned in `mapr_env.sh` (for example, `ssh mapr@node1.us-central1-f.t-diplomatic-962`).
6. Test an example application by running:
	```
	yarn jar $MAPR_HOME/hadoop/hadoop-2.5.1/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.5.1-mapr-1501.jar pi 16 100
	```


### At the end...
To delete the cluster, ensure `mapr_env.sh` is same as in when deployed. In the bdutil root directory, invoke: 
```
./bdutil -e mapr delete
```

### Additional Resources
* [Free Hadoop On-Demand Training](https://www.mapr.com/services/mapr-academy/big-data-hadoop-online-training)
* [Why MapR](https://www.mapr.com/why-hadoop/why-mapr)
* [MapR Development Guide](http://doc.mapr.com/display/MapR/Development+Guide)
* [MapR Documentation](http://doc.mapr.com/)
* [MapR Support](https://www.mapr.com/support/overview)
* [Another way](http://doc.mapr.com/display/MapR/MapR+Cluster+on+the+Google+Compute+Engine) to deploy
* [MapR-on-GCE](https://github.com/mapr/gce)

**LICENSE:** [Apache License, Version 2.0](https://github.com/GoogleCloudPlatform/bdutil/blob/master/LICENSE)