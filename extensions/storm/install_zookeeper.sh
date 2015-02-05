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

# Set up ZooKeeper
ZK_INSTALL_TMP_DIR="/zookeeper-$(date +%s)"
mkdir -p ${ZK_INSTALL_TMP_DIR}

ZOOKEEPER_TARBALL_BASENAME=$(\
    grep -o '[^/]*\.tar.gz' <<< ${ZOOKEEPER_TARBALL_URI})
ZOOKEEPER_LOCAL_TARBALL="${ZK_INSTALL_TMP_DIR}/${ZOOKEEPER_TARBALL_BASENAME}"
download_bd_resource ${ZOOKEEPER_TARBALL_URI} ${ZOOKEEPER_LOCAL_TARBALL}

tar -C ${ZK_INSTALL_TMP_DIR} -xvzf ${ZOOKEEPER_LOCAL_TARBALL}
mkdir -p $(dirname ${ZOOKEEPER_INSTALL_DIR})
mv ${ZK_INSTALL_TMP_DIR}/zookeeper*/ ${ZOOKEEPER_INSTALL_DIR}

mkdir -p ${ZOOKEEPER_VAR}/data
mkdir -p ${ZOOKEEPER_VAR}/log

# Copies the sample config into the actual config, but sets the dataDir value to be the data subdirectory of the zookeeper var directory
perl -p -e "s|(?<=dataDir=).*|${ZOOKEEPER_VAR}/data|" \
  ${ZOOKEEPER_INSTALL_DIR}/conf/zoo_sample.cfg > ${ZOOKEEPER_INSTALL_DIR}/conf/zoo.cfg

# Sets the dir locations for the log and tracelog and sets root.logger value to "INFO, ROLLINGFILE" instead of "INFO, CONSOLE"
perl -pi -e 's|^(zookeeper.(?:trace)?log.dir=).*|$1'${ZOOKEEPER_VAR}'/log| ; s|(?<=zookeeper.root.logger=).*|INFO, ROLLINGFILE| ;' \
  ${ZOOKEEPER_INSTALL_DIR}/conf/log4j.properties


# Add the zookeeper 'bin' path to the .bashrc so that it's easy to call access
# zookeeper files during interactive ssh session.
add_to_path_at_login "${ZOOKEEPER_INSTALL_DIR}/bin"

# Assign ownership of everything to the 'hadoop' user.
chown -R hadoop:hadoop /home/hadoop/ ${ZOOKEEPER_VAR}

# Define Supervisor Configuration for ZooKeeper
cat > /etc/supervisor/conf.d/zookeeper.conf <<EOF
[program:zookeeper]
command=${ZOOKEEPER_INSTALL_DIR}/bin/zkServer.sh start-foreground
numprocs=1
autostart=true
autorestart=true
user=hadoop
redirect_stderr=true
stdout_logfile=${ZOOKEEPER_VAR}/log/stdout.log
EOF
