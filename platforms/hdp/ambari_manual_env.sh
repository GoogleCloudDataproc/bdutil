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

# Extension installing Apache Ambari on the cluster allowing the user to
# manually log in and provision and configure the clusters software.
# This installs but does not configure the GCS connector.

# Import hadoop2_env.sh just for the GCS_CONNECTOR_JAR.
import_env hadoop2_env.sh

###### You might want to change the following. #######
AMBARI_VERSION='1.7.0'

# Since we'll be using HDFS as the default_fs, set some reasonably beefy
# disks.
USE_ATTACHED_PDS=true
WORKER_ATTACHED_PDS_SIZE_GB=1500
MASTER_ATTACHED_PD_SIZE_GB=1500

# Default to 4 workers plus master for good spreading of master daemons.
NUM_WORKERS=4

###### You probably don't want to edit below this. #######

# Use CentOS instead of Debian.
GCE_IMAGE='centos-6'

UPLOAD_FILES=(
  'hadoop2_env.sh'
  'libexec/hadoop_helpers.sh'
)

readonly DEFAULT_FS='hdfs'

# Install JDK with compiler/tools instead of just the minimal JRE.
INSTALL_JDK_DEVEL=true

GCS_CACHE_CLEANER_USER='hdfs'
GCS_CACHE_CLEANER_LOG_DIRECTORY="/var/log/hadoop/${GCS_CACHE_CLEANER_USER}"
GCS_CACHE_CLEANER_LOGGER='INFO,RFA'
HADOOP_CONF_DIR="/etc/hadoop/conf"
HADOOP_INSTALL_DIR="/usr/lib/hadoop"

# Ambari admin on port 8080.
MASTER_UI_PORTS=('8080')

COMMAND_GROUPS+=(
  "ambari-setup:
     libexec/mount_disks.sh
     libexec/install_java.sh
     platforms/hdp/install_ambari.sh
  "

  "install-gcs-connector-on-ambari:
     platforms/hdp/install_gcs_connector_on_ambari.sh
  "
)

COMMAND_STEPS=(
  'ambari-setup,ambari-setup'
  'deploy-master-nfs-setup,*'
  'deploy-client-nfs-setup,deploy-client-nfs-setup'
  'install-gcs-connector-on-ambari,install-gcs-connector-on-ambari'
)
