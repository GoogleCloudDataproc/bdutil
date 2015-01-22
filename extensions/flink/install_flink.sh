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


# fail if undeclared variables are used
set -o nounset
# exit on error
set -o errexit


# Figure out which tarball to use based on which Hadoop version is being used.
set +o nounset
HADOOP_BIN="sudo -u hadoop ${HADOOP_INSTALL_DIR}/bin/hadoop"
HADOOP_VERSION=$(${HADOOP_BIN} version | tr -cd [:digit:] | head -c1)
set -o nounset
if [[ "${HADOOP_VERSION}" == '2' ]]; then
  FLINK_TARBALL_URI=${FLINK_HADOOP2_TARBALL_URI}
else
  FLINK_TARBALL_URI=${FLINK_HADOOP1_TARBALL_URI}
fi

# Install Flink via this fancy pipe
gsutil cat "${FLINK_TARBALL_URI}" | tar -C /home/hadoop/ -xzv
mv /home/hadoop/flink* "${FLINK_INSTALL_DIR}"

# List all task managers (workers) in the slaves file
# The task managers will be brought up by the job manager (master)
echo ${WORKERS[@]} | tr ' ' '\n' > ${FLINK_INSTALL_DIR}/conf/slaves

# Create temp file in hadoop directory which might be mounted to other storage than os
FLINK_TASKMANAGER_TEMP_DIR="/hadoop/flink/tmp"
mkdir -p ${FLINK_TASKMANAGER_TEMP_DIR}
chgrp hadoop -R /hadoop/flink
chmod 777 -R /hadoop/flink

# Calculate the memory allocations, MB, using 'free -m'. Floor to nearest MB.
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
FLINK_JOBMANAGER_MEMORY=$(python -c \
    "print int(${TOTAL_MEM} * ${FLINK_JOBMANAGER_MEMORY_FRACTION})")
FLINK_TASKMANAGER_MEMORY=$(python -c \
    "print int(${TOTAL_MEM} * ${FLINK_TASKMANAGER_MEMORY_FRACTION})")

# Determine the number of task slots
if [[ "${FLINK_TASKMANAGER_SLOTS}" == "auto" ]] ; then
    FLINK_TASKMANAGER_SLOTS=`grep -c processor /proc/cpuinfo`
fi

# Determine the default degree of parallelization
if [[ "${FLINK_PARALLELIZATION_DEGREE}" == "auto" ]] ; then
    FLINK_PARALLELIZATION_DEGREE=$(python -c \
    "print ${NUM_WORKERS} * ${FLINK_TASKMANAGER_SLOTS}")
fi

# Apply Flink settings by appending them to the default config
cat << EOF >> ${FLINK_INSTALL_DIR}/conf/flink-conf.yaml
jobmanager.rpc.address: ${MASTER_HOSTNAME}
jobmanager.heap.mb: ${FLINK_JOBMANAGER_MEMORY}
taskmanager.heap.mb: ${FLINK_TASKMANAGER_MEMORY}
taskmanager.numberOfTaskSlots: ${FLINK_TASKMANAGER_SLOTS}
parallelization.degree.default: ${FLINK_PARALLELIZATION_DEGREE}
taskmanager.network.numberOfBuffers: ${FLINK_NETWORK_NUM_BUFFERS}
env.java.opts: ${FLINK_JAVA_OPTS}
taskmanager.tmp.dirs: ${FLINK_TASKMANAGER_TEMP_DIR}
fs.hdfs.hadoopconf: ${HADOOP_CONF_DIR}
EOF

# Assign ownership of everything to the 'hadoop' user.
chown -R hadoop:hadoop /home/hadoop/
# Make the Flink log directory writable
chmod 777 ${FLINK_INSTALL_DIR}/log