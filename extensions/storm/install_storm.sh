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
set -o errexit

# Set up Storm
STORM_MASTER_INSTANCE="${MASTER_HOSTNAME}"

STORM_INSTALL_TMP_DIR="/storm-$(date +%s)"
mkdir -p ${STORM_INSTALL_TMP_DIR}

STORM_TARBALL_BASENAME=$(grep -o '[^/]*\.tar.gz' <<< ${STORM_TARBALL_URI})
STORM_LOCAL_TARBALL="${STORM_INSTALL_TMP_DIR}/${STORM_TARBALL_BASENAME}"
download_bd_resource ${STORM_TARBALL_URI} ${STORM_LOCAL_TARBALL}

tar -C ${STORM_INSTALL_TMP_DIR} -xvzf ${STORM_LOCAL_TARBALL}
mkdir -p $(dirname ${STORM_INSTALL_DIR})
mv ${STORM_INSTALL_TMP_DIR}/apache-storm*/ ${STORM_INSTALL_DIR}

STORM_LIB_DIR="${STORM_INSTALL_DIR}/lib"

if (( ${ENABLE_STORM_BIGTABLE} )); then
  GOOGLE_STORM_LIB_DIR="${STORM_INSTALL_DIR}/lib/google"
  mkdir -p "${GOOGLE_STORM_LIB_DIR}"
  # Download the alpn jar.  The Alpn jar should be a fully qualified URL.
  # download_bd_resource needs a fully qualified file path and not just a
  # directory name to put the file in when the file to download starts with
  # http://.
  ALPN_JAR_NAME="${ALPN_REMOTE_JAR##*/}"
  ALPN_BOOT_JAR="${GOOGLE_STORM_LIB_DIR}/${ALPN_JAR_NAME}"
  download_bd_resource "${ALPN_REMOTE_JAR}" "${ALPN_BOOT_JAR}"
fi


mkdir -p ${STORM_VAR}
cat << EOF | tee -a ${STORM_INSTALL_DIR}/conf/storm.yaml
storm.zookeeper.servers:
  - "${STORM_MASTER_INSTANCE}"
nimbus.host: "${STORM_MASTER_INSTANCE}"
storm.local.dir: "${STORM_VAR}"
supervisor.slots.ports:
  - 6700
  - 6701
  - 6702
  - 6703
storm.messaging.transport: 'backtype.storm.messaging.netty.Context'
storm.messaging.netty.server_worker_threads: 1
storm.messaging.netty.client_worker_threads: 1
storm.messaging.netty.buffer_size: 5242880
storm.messaging.netty.max_retries: 100
storm.messaging.netty.max_wait_ms: 1000
storm.messaging.netty.min_wait_ms: 100

EOF

if (( ${ENABLE_STORM_BIGTABLE} )); then
  cat << EOF | tee -a "${STORM_INSTALL_DIR}/conf/storm.yaml"
worker.childopts: "-Xbootclasspath/p:${ALPN_BOOT_JAR}"
EOF
fi

# Add the storm 'bin' path to the .bashrc so that it's easy to call 'storm'
# during interactive ssh session.
add_to_path_at_login "${STORM_INSTALL_DIR}/bin"

# TODO(user): Fix this a better way.
cp /home/hadoop/hadoop-install/lib/gcs-connector*.jar /home/hadoop/storm-install/lib/
cp /home/hadoop/hadoop-install/hadoop-core*.jar /home/hadoop/storm-install/lib/
cp /home/hadoop/hadoop-install/lib/commons-configuration*.jar /home/hadoop/storm-install/lib/

# Assign ownership of everything to the 'hadoop' user.
chown -R hadoop:hadoop /home/hadoop/ ${STORM_VAR}
