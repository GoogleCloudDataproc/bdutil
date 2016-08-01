# Copyright 2014 Google Inc. All Rights Reserved.
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

# Extension file for deploying CDH with bdutil

# Requies Hadoop 2 libraries (for recent versions at least).
import_env hadoop2_env.sh

# Change these.
CDH_VERSION=5
# Components are installed / started in the order they are listed.
MASTER_COMPONENTS="hadoop-hdfs-namenode hadoop-hdfs-secondarynamenode
    hadoop-yarn-resourcemanager hadoop-mapreduce-historyserver
    hive-metastore hive-server2 hive pig oozie hue"
DATANODE_COMPONENTS="hadoop-hdfs-datanode hadoop-yarn-nodemanager
    hadoop-mapreduce"

# Install JDK with compiler/tools instead of just the minimal JRE.
INSTALL_JDK_DEVEL=true

# Hardware configuration.
NUM_WORKERS=4
WORKER_ATTACHED_PDS_SIZE_GB=1500
MASTER_ATTACHED_PD_SIZE_GB=1500

# Don't change these.
HADOOP_CONF_DIR='/etc/hadoop/conf'
HADOOP_INSTALL_DIR='/usr/lib/hadoop'
DEFAULT_FS='hdfs'
UPLOAD_FILES+=('platforms/cdh/cdh-core-template.xml')
USE_ATTACHED_PDS=true

COMMAND_GROUPS+=(
  "deploy-cdh:
     libexec/mount_disks.sh
     libexec/install_java.sh
     platforms/cdh/install_cdh.sh
     libexec/install_bdconfig.sh
     libexec/configure_hadoop.sh
     libexec/install_and_configure_gcs_connector.sh
     libexec/configure_hdfs.sh
     libexec/set_default_fs.sh
     platforms/cdh/configure_cdh.sh"

  "restart_services:
     platforms/restart_services.sh"
)

COMMAND_STEPS=(
  'deploy-cdh,deploy-cdh'
  'deploy-master-nfs-setup,*'
  'deploy-client-nfs-setup,deploy-client-nfs-setup'
  'restart_services,restart_services'
)
