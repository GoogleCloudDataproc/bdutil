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

# Extension providing a cluster with Apache Ambari installed and automatically
# provisions and configures the cluster's software. This installs and configures
# the GCS connector.

# Import the base Ambari installation
import_env platforms/hdp/ambari_manual_env.sh

###### You might want to change the following. #######
AMBARI_VERSION='1.7.0'

# The distribution to install on your cluster.
AMBARI_STACK='HDP'
AMBARI_STACK_VERSION='2.2'

# The components of that distribution to install on the cluster.
# Default is all but Apache Knox.
AMBARI_SERVICES='FALCON FLUME GANGLIA HBASE HDFS HIVE KAFKA KERBEROS MAPREDUCE2
    NAGIOS OOZIE PIG SLIDER SQOOP STORM TEZ YARN ZOOKEEPER'

# Since we'll be using HDFS as the default_fs, set some reasonably beefy
# disks.
USE_ATTACHED_PDS=true
WORKER_ATTACHED_PDS_SIZE_GB=1500
MASTER_ATTACHED_PD_SIZE_GB=1500

# Default to 4 workers plus master for good spreading of master daemons.
NUM_WORKERS=4

###### You probably don't want to edit below this. #######

UPLOAD_FILES+=(
  'platforms/hdp/ambari_manual_env.sh'
  'platforms/hdp/configuration.json'
  'platforms/hdp/create_blueprint.py'
)

## Tools for interacting with Ambari SERVER
AMBARI_TIMEOUT=3600
POLLING_INTERVAL=10

AMBARI_API='http://localhost:8080/api/v1'
AMBARI_CURL='curl -su admin:admin -H X-Requested-By:ambari'


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
  "install-ambari-components:
     platforms/hdp/install_ambari_components.sh
  "
)

COMMAND_STEPS+=(
  'install-ambari-components,*'
)
