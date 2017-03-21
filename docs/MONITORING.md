# Monitoring jobs

You can monitor the activity of your cluster using the Hadoop web interface while `wordcount` is running. Apache Hadoop provides web interfaces for the Hadoop Distributed File System (HDFS), MapReduce, and YARN. However, because these interfaces do not require user authentication to connect to them, they are insecure. Instead of opening these ports to public traffic, we recommend that you create a secure SSH tunnel from your local network to your [Compute Engine network](https://cloud.google.com/compute/docs/networking).

## Set up a secure SSH tunnel

**Google Cloud Shell** - Using the Google Cloud Shell to create an SSH tunnel is not supported and will not work. You must use a locally-installed SSH client, like PuTTY or the MacOS Terminal to create an SSH tunnel.

### Option 1 (easier) - bdutil socksproxy
You can use the command `bdutil socksproxy`. By default, this command will open a SOCKS proxy to the cluster at `localhost:1080`. You can also pass a port when opening the proxy, such as `bdutil socksproxy 8081`.

Your SSH tunnel supports traffic proxying using the [SOCKS protocol](http://en.wikipedia.org/wiki/SOCKS). This means that you can send network requests through your SSH tunnel in any browser that supports the SOCKS protocol. For example, the following command allow you to open an instance of the Chrome web browser that sends network requests through the SSH tunnel.

    chrome \
      --proxy-server="socks5://localhost:1080" \
      --host-resolver-rules="MAP * 0.0.0.0 , EXCLUDE localhost" \
      --user-data-dir=/tmp/<hadoop-master>

With this option or the one below, you can use Chrome or many other browsers.

### Option 2 - gcloud compute ssh

We recommend using [local port forwarding](https://www.wikipedia.org/wiki/Port_forwarding#Local_port_forwarding) to set up the SSH tunnel. Run the following to set up an SSH tunnel to the Hadoop master instance on port 1080 of your local host:

    gcloud compute ssh <hadoop-master> --zone=<hadoop-master-zone> \
      --ssh-flag="-D 1080" --ssh-flag="-N" --ssh-flag="-n"

The `--ssh-flag` flag allows you to add extra parameters to your SSH connection. The `--ssh-flag` values above have the following meanings:

* `-D 1080` specifies dynamic application-level port forwarding.
* `-N` instructs the gcloud command-line tool not to open a remote shell.
* `-n` instructs the gcloud command-line tool not to read from stdin.

Using this command, your SSH tunnel operates independently from your other SSH shell sessions. By keeping the SSH tunnel independent, you can avoid both seeing tunnel-related errors in your shell output and closing your SSH tunnel by accident.

The following command, as an example, will allow you to open an instance of the Chrome web browser that sends network requests through the SSH tunnel.

    chrome \
      --proxy-server="socks5://localhost:1080" \
      --host-resolver-rules="MAP * 0.0.0.0 , EXCLUDE localhost" \
      --user-data-dir=/tmp/<hadoop-master>

This command uses the following flags:

* `-proxy-server="socks5://localhost:1080"` tells Chrome to send all http:// and https:// URL requests through the SOCKS proxy server `localhost:1080`, using version 5 of the SOCKS protocol. The hostname for these URLs are resolved by the proxy server, not locally by Chrome.
* `--host-resolver-rules="MAP * 0.0.0.0 , EXCLUDE localhost"` prevents Chrome from sending any DNS requests over the network.
* `--user-data-dir=/tmp/<hadoop-master>` forces Chrome to open a new window that is not tied to an existing Chrome session. Without this flag, Chrome may open a new window attached to an existing Chrome session, ignoring your `--proxy-server` setting. The value set for `--user-data-dir` can be any nonexistent path.

Note that the location of the `chrome` executable varies across operating systems. Common locations are as follows:

| Operating System | Chrome Executable Path |
| --- | --- |
| Mac OS X |	`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` |
| Linux	| `/opt/google/chrome/chrome` |
| Windows	| `C:\Program Files (x86)\Google\Chrome\Application\chrome` |

## Use the tunnel to view the Hadoop web interface

After you've created a secure SSH tunnel, you can open the Hadoop MapReduce web interface (for Hadoop 1.x) or Hadoop YARN web interface (for Hadoop 2.x) in your web browser.

### MapReduce web interface (Hadoop 1.x)

Navigate to `http://<hadoop-master>:50030/` in your web browser to be redirected to the Hadoop Map/Reduce Administration web interface. The top portion of this page provides basic information regarding the state of your cluster.

Further down on the page is a section for Running Jobs. When a MapReduce job is running, a table of running jobs with summary details about each job appears in this section. To view details about a running job, click the linked job ID in the Jobid column.

After your job completes, the job appears in the Completed Jobs section of the Hadoop Map/Reduce Administration page. The Completed Jobs section will not appear until at least one job has been run.

The Hadoop Map/Reduce Administration web interface does not refresh automatically. The job detail page, however, refreshes every 30 seconds.

### YARN web interface (Hadoop 2.x)

Navigate to `http://<hadoop-master>:8088/` to be redirected to the Hadoop All Applications web interface. The top portion of this page provides metrics regarding the application layer of your Hadoop cluster.

Below this is a section for running and completed jobs. To view details about a job, click the linked job ID in the ID column. Selecting this link takes you to the application detail page. From there, you can click through to more details about the MapReduce job.

The Hadoop 2.x Applications and Map/Reduce web interfaces do not refresh automatically.
