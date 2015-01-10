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

# Environment variables to be used in the local ghadoop as well as in setup
# scripts running on remote VMs; this file will be used as a preamble to each
# partial setup script being run on each VM.

# Import hadoop2_env.sh just for the GCS_CONNECTOR_JAR.
import_env hadoop2_env.sh

# Require centos instead of debian.
GCE_IMAGE='centos-6'

UPLOAD_FILES=(
  'hadoop2_env.sh'
  'libexec/hadoop_helpers.sh'
  'platforms/hdp/configuration.json'
  'platforms/hdp/create_blueprint.py'
)

HDP_VERSION='2.2'
AMBARI_VERSION='1.7.0'
AMBARI_SERVICES='FALCON FLUME GANGLIA HBASE HDFS HIVE KAFKA KERBEROS MAPREDUCE2
    NAGIOS OOZIE PIG SLIDER SQOOP STORM TEZ YARN ZOOKEEPER'

GCS_CACHE_CLEANER_USER='hdfs'
GCS_CACHE_CLEANER_LOG_DIRECTORY="/var/log/hadoop/${GCS_CACHE_CLEANER_USER}"
GCS_CACHE_CLEANER_LOGGER='INFO,RFA'
HADOOP_CONF_DIR="/etc/hadoop/conf"
HADOOP_INSTALL_DIR="/usr/lib/hadoop"

## Tools for interacting with Ambari SERVER
AMBARI_TIMEOUT=3600
POLLING_INTERVAL=10

AMBARI_API='http://localhost:8080/api/v1'
AMBARI_CURL='curl -su admin:admin -H X-Requested-By:ambari'

# Ambari admin on port 8080.
MASTER_UI_PORTS=('8080')

# Since we'll be using HDFS as the default_fs, set some reasonably beefy
# disks.
readonly DEFAULT_FS='hdfs'
USE_ATTACHED_PDS=true
WORKER_ATTACHED_PDS_SIZE_GB=1500
MASTER_ATTACHED_PD_SIZE_GB=1500

# Default to 4 workers plus master for good spreading of master daemons.
NUM_WORKERS=4

function ambari_wait() {
  local condition="$1"
  local goal="$2"
  local failed="FAILED"
  local limit=$(( ${AMBARI_TIMEOUT} / ${POLLING_INTERVAL} + 1 ))

  for (( i=0; i<${limit}; i++ )); do
    local status=$(bash -c "${condition}")
    if [[ "${status}" == "${goal}" ]]; then
      break
    elif [[ "${status}" == "${failed}" ]]; then
      echo "Ambari operiation failed with status: ${status}" >&2
      return 1
    fi
    echo "ambari_wait status: ${status}" >&2
    sleep ${POLLING_INTERVAL}
  done

  if [[ ${i} -eq ${limit} ]]; then
    echo "ambari_wait did not finish within" \
        "'${AMBARI_TIMEOUT}' seconds. Exiting." >&2
    return 1
  fi
}

COMMAND_GROUPS+=(
  "ambari-setup:
     libexec/mount_disks.sh
     libexec/install_java.sh
     platforms/hdp/install_ambari.sh
  "

  "install-gcs-connector-on-ambari:
     platforms/hdp/install_gcs_connector_on_ambari.sh
  "

  "install-ambari-components:
     platforms/hdp/install_ambari_components.sh
  "
)

COMMAND_STEPS=(
  'ambari-setup,ambari-setup'
  'deploy-master-nfs-setup,*'
  'deploy-client-nfs-setup,deploy-client-nfs-setup'
  'install-gcs-connector-on-ambari,install-gcs-connector-on-ambari'
  'install-ambari-components,*'
)
