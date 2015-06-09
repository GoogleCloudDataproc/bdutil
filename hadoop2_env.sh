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

# Sets environment variables for YARN based Hadoop 2.x deployment

GCS_CACHE_CLEANER_LOGGER='INFO,RFA'

# URI of Hadoop tarball to be deployed. Must begin with gs:// or http(s)://
# Use 'gsutil ls gs://hadoop-dist/hadoop-*.tar.gz' to list Google supplied options
HADOOP_TARBALL_URI="gs://hadoop-dist/hadoop-2.6.0.tar.gz"

# Directory holding config files and scripts for Hadoop
HADOOP_CONF_DIR="${HADOOP_INSTALL_DIR}/etc/hadoop"

# Fraction of worker memory to be used for YARN containers
NODEMANAGER_MEMORY_FRACTION=0.8

# Decimal number controlling the size of map containers in memory and virtual
# cores. Since by default Hadoop only supports memory based container
# allocation, each map task will be given a container with roughly
# (CORES_PER_MAP_TASK / <total-cores-on-node>) share of the memory available to
# the NodeManager for containers. Thus an n1-standard-4 with CORES_PER_MAP_TASK
# set to 2 would be able to host 4 / 2 = 2 map containers (and no other
# containers). For more details see the script 'libexec/configure-mrv2-mem.py'.
CORES_PER_MAP_TASK=1.0

# Decimal number controlling the size of reduce containers in memory and virtual
# cores. See CORES_PER_MAP_TASK for more details.
CORES_PER_REDUCE_TASK=2.0

# Decimal number controlling the size of application master containers in memory
# and virtual cores. See CORES_PER_MAP_TASK for more details.
CORES_PER_APP_MASTER=2.0

# Connector with Hadoop AbstractFileSystem implemenation for YARN
GCS_CONNECTOR_JAR='https://storage.googleapis.com/hadoop-lib-dev/gcs/gcs-connector-1.4.1-SNAPSHOT-hadoop2-20150608-170007.jar?GoogleAccessId=359641935755-j2hkfvkvflpvguhuj2dajativ5ft8856@developer.gserviceaccount.com&Expires=1465344281&Signature=aNgPA0Iq0Ng2OflGhwUklSLKwflvInfRBmSxDes%2FgolJfKZPRtjTXfB1RooMrDKVKb667mK6g9mlAqd7ZIyGxgNaSqeVHCOLlzLJLV75xZCftY%2FNjawwfF7EjNn6CuM%2FIy3d6neituYMh64PQbFtcipUnJM0YsRDVNt1Zqki814='

BIGQUERY_CONNECTOR_JAR='https://storage.googleapis.com/hadoop-lib-dev/bigquery/bigquery-connector-0.7.1-SNAPSHOT-20150608-170517-hadoop2.jar?GoogleAccessId=359641935755-j2hkfvkvflpvguhuj2dajativ5ft8856@developer.gserviceaccount.com&Expires=1465344534&Signature=fXFuUMIQ6DvfPv03KkVlT%2BUpPGA%2B33XmYvbR%2FRPK7nAcwZnvU52GiF0pZt9RlAwNISgkUyY9yW9U2S0xoZbdLJ4BiUpv7UJvGfuXzNK06HQcjvSFjx%2F6KkCcAlx878rLVlI0%2BhAv9YU2SjM18zd09LM8LiEBUwk75V0lJd%2B7BP8='


HDFS_DATA_DIRS_PERM='700'

# 8088 for YARN, 50070 for HDFS.
MASTER_UI_PORTS=('8088' '50070')

# Use Hadoop 2 specific configuration templates.
if [[ -n "${BDUTIL_DIR}" ]]; then
  UPLOAD_FILES=($(find ${BDUTIL_DIR}/conf/hadoop2 -name '*template.xml'))
  UPLOAD_FILES+=("${BDUTIL_DIR}/libexec/hadoop_helpers.sh")
  UPLOAD_FILES+=("${BDUTIL_DIR}/libexec/configure_mrv2_mem.py")
fi

# Use Hadoop 2 specific start scripts
COMMAND_GROUPS+=(
  'deploy_start2:
    libexec/start_hadoop2.sh'
)

COMMAND_STEPS=(
  "deploy-ssh-master-setup,*"
  'deploy-core-setup,deploy-core-setup'
  "*,deploy-ssh-worker-setup"
  "deploy-master-nfs-setup,*",
  "deploy-client-nfs-setup,deploy-client-nfs-setup",
  'deploy_start2,*'
)
