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

set -o nounset
set -o errexit

# Get the filename out of the full URI.
HAMA_TARBALL=${HAMA_TARBALL_URI##*/}

# Get the tarball, untar it.
gsutil cp ${HAMA_TARBALL_URI} /home/hadoop/${HAMA_TARBALL}
tar -C /home/hadoop -xzvf /home/hadoop/${HAMA_TARBALL}
mv /home/hadoop/hama*/ ${HAMA_INSTALL_DIR}

# Set up hama-site.xml to make sure it can access HDFS.
cat << EOF > ${HAMA_INSTALL_DIR}/conf/hama-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>bsp.master.address</name>
    <value>${MASTER_HOSTNAME}:40000</value>
  </property>
  <property>
    <name>hama.zookeeper.quorum</name>
    <value>${MASTER_HOSTNAME}</value>
  </property>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://${MASTER_HOSTNAME}:8020/</value>
  </property>
</configuration>
EOF

# Set up all workers to be groomservers.
echo ${WORKERS[@]} | tr ' ' '\n' > ${HAMA_INSTALL_DIR}/conf/groomservers

# Symlink the Hadoop hdfs-site.xml to hama's "copy" of it.
ln -s ${HADOOP_CONF_DIR}/hdfs-site.xml ${HAMA_INSTALL_DIR}/conf/hdfs-site.xml

# Explicitly set up JAVA_HOME for hama.
JAVA_HOME=$(readlink -f $(which java) | sed 's|/bin/java$||')
cat << EOF >> ${HAMA_INSTALL_DIR}/conf/hama-env.sh
export JAVA_HOME=${JAVA_HOME}
EOF

# Add the hama 'bin' path to the .bashrc so that it's easy to call 'hama'
# during interactive ssh session.
add_to_path_at_login "${HAMA_INSTALL_DIR}/bin"

# Assign ownership of everything to the 'hadoop' user.
chown -R hadoop:hadoop /home/hadoop/ ${HAMA_INSTALL_DIR}
