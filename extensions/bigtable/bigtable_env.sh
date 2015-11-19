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

# This file contains environment-variable overrides to be used in conjunction
# with bdutil_env.sh in order to deploy a Hadoop cluster with HBase installed
# and configured to use Cloud Bigtable.
# Usage: ./bdutil deploy -e extensions/bigtable/bigtable_env.sh.

# Directory on each VM in which to install hbase.
HBASE_INSTALL_DIR=/home/hadoop/hbase-install
HBASE_CONF_DIR=${HBASE_INSTALL_DIR}/conf/
BIGTABLE_ENDPOINT=bigtable.googleapis.com
BIGTABLE_ADMIN_ENDPOINT=bigtabletableadmin.googleapis.com

BIGTABLE_ZONE=us-central1-b
BIGTABLE_CLUSTER=cluster

COMMAND_GROUPS+=(
  "install_bigtable:
     extensions/bigtable/install_hbase_bigtable.sh
  "
)

# Installation of bigtable on master and workers
COMMAND_STEPS+=(
  'install_bigtable,install_bigtable'
)

ALPN_REMOTE_JAR=http://central.maven.org/maven2/org/mortbay/jetty/alpn/alpn-boot/8.1.3.v20150130/alpn-boot-8.1.3.v20150130.jar
BIGTABLE_HBASE_JAR=https://storage.googleapis.com/cloud-bigtable/jars/bigtable-hbase/bigtable-hbase-mapreduce-0.2.2-shaded.jar

# Copied from http://www.us.apache.org/dist/hbase/stable/
# We don't want to overload the apache servers.
HBASE_TARBALL_URI=https://storage.googleapis.com/cloud-bigtable/hbase-dist/hbase-1.1.2/hbase-1.1.2-bin.tar.gz

BIGTABLE_LIB_DIR=${HBASE_INSTALL_DIR}/lib/bigtable
ALPN_CLASSPATH=${BIGTABLE_LIB_DIR}/alpn-boot-8.1.3.v20150130.jar
BIGTABLE_BOOT_OPTS="-Xms1024m -Xmx2048m -Xbootclasspath/p:${ALPN_CLASSPATH}"

# TODO: JAVAOPTS gets used in mapred-template.xml.  There should probably be a better way to do this.
JAVAOPTS="$JAVAOPTS -Xbootclasspath/p:$BIGTABLE_BOOT_OPTS"

GCE_SERVICE_ACCOUNT_SCOPES+=(
  'https://www.googleapis.com/auth/cloud-bigtable.admin'
  'https://www.googleapis.com/auth/cloud-bigtable.data'
  'https://www.googleapis.com/auth/cloud-bigtable.data.readonly'
)
