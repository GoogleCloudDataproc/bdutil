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
GCS_CONNECTOR_JAR='https://storage.googleapis.com/hadoop-lib-dev/gcs/gcs-connector-1.3.2-SNAPSHOT-hadoop2-20141222-135330.jar?GoogleAccessId=359641935755-j2hkfvkvflpvguhuj2dajativ5ft8856@developer.gserviceaccount.com&Expires=1450821787&Signature=cQDn6fvv2Hyu58z9uzLQEIu42WyeSOY97lO8pXgZNq%2BEX5YGW8VjBWP1YzBX1Slkufc6USrb4009TZhSu%2BQATsZwYa7jOGh0sLSsHEmCPvUI3HrENag8rvvhefLnxGx6vrFcA2fOskivUOp5ZTyh1K0sCDBqjoSLTbGIFXeuNr0='

DATASTORE_CONNECTOR_JAR='https://storage.googleapis.com/hadoop-lib-dev/datastore/datastore-connector-0.14.10-SNAPSHOT-20141222-133725-hadoop2.jar?GoogleAccessId=359641935755-j2hkfvkvflpvguhuj2dajativ5ft8856@developer.gserviceaccount.com&Expires=1450820611&Signature=iZWtERtR1vRszg8D734aO%2BadLcOpSjgOF5%2BxsNYLN%2B26oVO8KnEAF%2FRFVEsVQMXxwMSY8olp7r7zegBhOsuAflm%2F7d8rSpXOqWuoUI7VfGaadC%2FNfkQTux%2Fl0rkvZj1bk85fsQO115p1voOyIH%2FweZ8U05cx6hIkvdG3s%2FPnVts='

BIGQUERY_CONNECTOR_JAR='https://storage.googleapis.com/hadoop-lib-dev/bigquery/bigquery-connector-0.5.1-SNAPSHOT-20141222-112706-hadoop2.jar?GoogleAccessId=359641935755-j2hkfvkvflpvguhuj2dajativ5ft8856@developer.gserviceaccount.com&Expires=1450812947&Signature=M14Jcxt5HjiCGhDvOQGJdr9UcwrFp4ELJ617AW9O2cpZ453%2F5irwsnHPgGjeczpoD4sCxidheWTCEcSOa8y0E163zBNKXda1Nc0gHyMVQMQOPWzfQ1QgQCTuT%2BD39FjNyvOazlXJymzuRJruLRK2CY2HbbN%2FSpacVUCrckn6ABU='


HDFS_DATA_DIRS_PERM='700'

# 8088 for YARN, 50070 for HDFS.
MASTER_UI_PORTS=('8088' '50070')

# Use Hadoop 2 specific configuration templates.
if [[ -n "${BDUTIL_DIR}" ]]; then
  UPLOAD_FILES=($(find ${BDUTIL_DIR}/conf/hadoop2 -name '*template.xml'))
  UPLOAD_FILES+=(${BDUTIL_DIR}/libexec/hadoop_helpers.sh)
fi
UPLOAD_FILES+=("libexec/configure_mrv2_mem.py")

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
