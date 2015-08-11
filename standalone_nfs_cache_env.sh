# Copyright 2015 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Handy wrapper around single_node_env.sh to turn up just a single server
# capable of acting as the NFS-based GCS consistency cache for multiple
# other clusters.
#
# Usage:
#   ./bdutil -P my-nfs-server -p <project> -z <zone> -b <bucket> generate_config my-nfs-server_env.sh
#   ./bdutil -e my-nfs-server_env.sh deploy
#
#   ./bdutil -P cluster1 -p <project> -z <zone> -b <bucket> generate_config cluster1_env.sh
#   echo GCS_CACHE_MASTER_HOSTNAME=my-nfs-server >> cluster1_env.sh
#   ./bdutil -e cluster1_env.sh deploy
#
#   ./bdutil -P cluster2 -p <project> -z <zone> -b <bucket> generate_config cluster2_env.sh
#   echo GCS_CACHE_MASTER_HOSTNAME=my-nfs-server >> cluster2_env.sh
#   ./bdutil -e cluster2_env.sh deploy
#
#  ./bdutil -e cluster2_env.sh delete
#  ./bdutil -e cluster1_env.sh delete
#  ./bdutil -e my-nfs-server_env.sh delete

# Start with single_node_env.sh to get all the MASTER_HOSTNAME, etc.,
# resolution.
import_env single_node_env.sh

# This server would be somewhat pointless without the GCS connector and the
# NFS cache enabled.
INSTALL_GCS_CONNECTOR=true
DEFAULT_FS='gs'
ENABLE_NFS_GCS_FILE_CACHE=true

# We'll set up Hadoop as normal since it'll be handy to have "hadoop fs -ls"
# on the cache server, but we just won't configure the hadoop daemons to start
# on boot, and won't start them explicitly during deployment. That means
# no jobracker or resourcemanager or namenode, but we should still be able to
# use "hadoop fs" against GCS just fine.
COMMAND_GROUPS+=(
  "deploy-standalone-nfs-cache:
     libexec/install_java.sh
     libexec/mount_disks.sh
     libexec/setup_hadoop_user.sh
     libexec/install_hadoop.sh
     libexec/install_bdconfig.sh
     libexec/configure_hadoop.sh
     libexec/install_and_configure_gcs_connector.sh
     libexec/configure_hdfs.sh
     libexec/set_default_fs.sh
     libexec/setup_master_nfs.sh
  "
)

COMMAND_STEPS=(
  "deploy-standalone-nfs-cache,*"
  "deploy-client-nfs-setup,*"
)
