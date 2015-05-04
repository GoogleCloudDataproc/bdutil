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
download_bd_resource ${HBASE_TARBALL_URI} /home/hadoop/${HBASE_TARBALL}

tar -C /home/hadoop -xzvf /home/hadoop/${HBASE_TARBALL}
mv /home/hadoop/hbase*/ ${HBASE_INSTALL_DIR}

mkdir -p ${BIGTABLE_LIB_DIR}

# Download the alpn jar.  The Alpn jar should be a fully qualified URL.
# download_bd_resource needs a fully qualified file path and not just a
# directory name to put the file in when the file to download starts with
# http://.
ALPN_JAR_NAME=${ALPN_REMOTE_JAR##*/}
ALPN_BOOT_JAR=${BIGTABLE_LIB_DIR}/${ALPN_JAR_NAME}
download_bd_resource ${ALPN_REMOTE_JAR} ${ALPN_BOOT_JAR}

# Download the jar contains the Bigtable API and the Bigtable HBase integration.
download_bd_resource ${BIGTABLE_HBASE_JAR} ${BIGTABLE_LIB_DIR}

BIGTABLE_CLASSPATH=`readlink -f ${BIGTABLE_LIB_DIR}/bigtable-hbase-*.jar`

# Set up hbase-site.xml to make sure it can access HDFS.
bdconfig merge_configurations \
    --configuration_file ${HBASE_CONF_DIR}/hbase-site.xml \
    --source_configuration_file bigtable-hbase-site-template.xml \
    --resolve_environment_variables \
    --create_if_absent \
    --clobber

# Symlink the Hadoop hdfs-site.xml to hbase's "copy" of it.
ln -s ${HADOOP_CONF_DIR}/hdfs-site.xml ${HBASE_CONF_DIR}/hdfs-site.xml

# Add the hbase 'bin' path to the .bashrc so that it's easy to call 'hbase'
# during interactive ssh session.
add_to_path_at_login "${HBASE_INSTALL_DIR}/bin"

# Assign ownership of everything to the 'hadoop' user.
chown -R hadoop:hadoop /home/hadoop/ ${HBASE_INSTALL_DIR}

# Update hadoop-env.sh with alpn boot classpath.  Create an environment variable
# BIGTABLE_BOOT_OPTS that makes command line requests a bit easier.
echo -e "" >> ${HADOOP_CONF_DIR}/hadoop-env.sh
echo -e "HADOOP_OPTS=\"\${HADOOP_OPTS} -Xbootclasspath/p:${ALPN_BOOT_JAR}\"" >> ${HADOOP_CONF_DIR}/hadoop-env.sh
echo -e "HADOOP_TASKTRACKER_OPTS=\"\${HADOOP_TASKTRACKER_OPTS} -Xbootclasspath/p:${ALPN_BOOT_JAR}\"" >> ${HADOOP_CONF_DIR}/hadoop-env.sh
echo -e "BIGTABLE_BOOT_OPTS=\"${BIGTABLE_BOOT_OPTS}\"" >> ${HADOOP_CONF_DIR}/hadoop-env.sh

# TODO: This should probably be removed at some point.  This is done in order
# add in a newer version of guava that's bundled with ${BIGTABLE_RPC_JAR}
echo -e "HADOOP_CLASSPATH=${BIGTABLE_CLASSPATH}:\${HADOOP_CLASSPATH}" >> ${HADOOP_CONF_DIR}/hadoop-env.sh
echo -e "HADOOP_USER_CLASSPATH_FIRST=true" >> ${HADOOP_CONF_DIR}/hadoop-env.sh

# Update yarn-env.sh with alpn boot classpath.
echo -e "" >> ${HADOOP_CONF_DIR}/yarn-env.sh.
echo -e "YARN_OPTS=\"\${YARN_OPTS} -Dyarn.app.mapreduce.am.command-opts=\"${BIGTABLE_BOOT_OPTS}\"\"" >> ${HADOOP_CONF_DIR}/yarn-env.sh

# Update base-env.sh with alpn boot classpath and add the Bigtable classpath to
# the hbase classpath.
echo -e "HBASE_OPTS=\"\${HBASE_OPTS} ${BIGTABLE_BOOT_OPTS}\"" >> ${HBASE_CONF_DIR}/hbase-env.sh

exit
