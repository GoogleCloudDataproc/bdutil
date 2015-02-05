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
HBASE_TARBALL=${HBASE_TARBALL_URI##*/}

# Get the tarball, untar it.
gsutil cp ${HBASE_TARBALL_URI} /home/hadoop/${HBASE_TARBALL}
tar -C /home/hadoop -xzvf /home/hadoop/${HBASE_TARBALL}
mv /home/hadoop/hbase*/ ${HBASE_INSTALL_DIR}

# Set up hbase-site.xml to make sure it can access HDFS.
cat << EOF > ${HBASE_INSTALL_DIR}/conf/hbase-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://${MASTER_HOSTNAME}:8020/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>${MASTER_HOSTNAME}</value>
  </property>
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
</configuration>
EOF

# Set up all workers to be regionservers.
echo ${WORKERS[@]} | tr ' ' '\n' > ${HBASE_INSTALL_DIR}/conf/regionservers

# Symlink the Hadoop hdfs-site.xml to hbase's "copy" of it.
ln -s ${HADOOP_CONF_DIR}/hdfs-site.xml ${HBASE_INSTALL_DIR}/conf/hdfs-site.xml

# Explicitly set up JAVA_HOME for hbase.
JAVA_HOME=$(readlink -f $(which java) | sed 's|/bin/java$||')
cat << EOF >> ${HBASE_INSTALL_DIR}/conf/hbase-env.sh
export JAVA_HOME=${JAVA_HOME}
EOF

# Add the hbase 'bin' path to the .bashrc so that it's easy to call 'hbase'
# during interactive ssh session.
add_to_path_at_login "${HBASE_INSTALL_DIR}/bin"

# Assign ownership of everything to the 'hadoop' user.
chown -R hadoop:hadoop /home/hadoop/ ${HBASE_INSTALL_DIR}
