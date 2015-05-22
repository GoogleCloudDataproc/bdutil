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
HADOOP_TARBALL_URI="gs://hadoop-dist/hadoop-2.5.2.tar.gz"

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
GCS_CONNECTOR_JAR='https://storage.googleapis.com/hadoop-lib-dev/gcs/gcs-connector-1.3.4-SNAPSHOT-hadoop2-20150521-171734.jar?GoogleAccessId=359641935755-j2hkfvkvflpvguhuj2dajativ5ft8856@developer.gserviceaccount.com&Expires=1463791002&Signature=PdhJSkuW6dAyp8i%2BvXf32NuoYezTVseO3bN422Wr36WSFKpetThfgKuez9N1o%2BRbFbd5qSA3J0E5yQ6%2Bh9F3O86%2BIlUFDmJeg4NTNyKjzC1%2B5FoQLqQ0JTcdKtLXwTIO3ugDm1AP7A6to%2F0ivPf%2BVAiqiNhKLAvglGyfB5riUEk='

BIGQUERY_CONNECTOR_JAR='https://storage.googleapis.com/hadoop-lib-dev/bigquery/bigquery-connector-0.6.1-SNAPSHOT-20150521-175606-hadoop2.jar?GoogleAccessId=359641935755-j2hkfvkvflpvguhuj2dajativ5ft8856@developer.gserviceaccount.com&Expires=1463793407&Signature=mVEcy8nvAitm4jUFURwCH1nleHEeFsueY1yCHmicZhvlvn3s%2BA1slGCDTy14UrWxLa0QmwEuCDMRGXfIE6ogVPmI8u7%2B6VyBg72z0zjeiPj5JgpiV424OB6uRkVjSl480O%2BOUg9QZhxHnIxORx12a2GuhOtpuXCjzUdDS6JOqCE='


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
