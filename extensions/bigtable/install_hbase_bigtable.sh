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
HBASE_TARBALL="${HBASE_TARBALL_URI##*/}"

# Get the tarball, untar it.
download_bd_resource "${HBASE_TARBALL_URI}" "/home/hadoop/${HBASE_TARBALL}"

tar -C /home/hadoop -xzvf "/home/hadoop/${HBASE_TARBALL}"
mv /home/hadoop/hbase*/ "${HBASE_INSTALL_DIR}"

mkdir -p "${BIGTABLE_LIB_DIR}"

# Download the alpn jar.  The Alpn jar should be a fully qualified URL.
# download_bd_resource needs a fully qualified file path and not just a
# directory name to put the file in when the file to download starts with
# http://.
ALPN_JAR_NAME="${ALPN_REMOTE_JAR##*/}"
ALPN_BOOT_JAR="${BIGTABLE_LIB_DIR}/${ALPN_JAR_NAME}"
download_bd_resource "${ALPN_REMOTE_JAR}" "${ALPN_BOOT_JAR}"

# Download the jar contains the Bigtable API and the Bigtable HBase integration.
BIGTABLE_HBASE_JAR_NAME="${BIGTABLE_HBASE_JAR##*/}"
download_bd_resource "${BIGTABLE_HBASE_JAR}" "${BIGTABLE_LIB_DIR}/${BIGTABLE_HBASE_JAR_NAME}"

BIGTABLE_CLASSPATH=`readlink -f ${BIGTABLE_LIB_DIR}/bigtable-hbase-*.jar`

# Set up hbase-site.xml to make sure it can access HDFS.
bdconfig merge_configurations \
    --configuration_file "${HBASE_CONF_DIR}/hbase-site.xml" \
    --source_configuration_file bigtable-hbase-site-template.xml \
    --resolve_environment_variables \
    --create_if_absent \
    --clobber

# Symlink the Hadoop hdfs-site.xml to hbase's "copy" of it.
ln -s "${HADOOP_CONF_DIR}/hdfs-site.xml" ${HBASE_CONF_DIR}/hdfs-site.xml

# Add the hbase 'bin' path to the .bashrc so that it's easy to call 'hbase'
# during interactive ssh session.
add_to_path_at_login "${HBASE_INSTALL_DIR}/bin"

# Assign ownership of everything to the 'hadoop' user.
chown -R hadoop:hadoop /home/hadoop/ "${HBASE_INSTALL_DIR}"

# Update hadoop-env.sh with alpn boot classpath.  Create an environment variable
# BIGTABLE_BOOT_OPTS that makes command line requests a bit easier.
echo -e "" >> "${HADOOP_CONF_DIR}/hadoop-env.sh"
echo -e "HADOOP_OPTS=\"\${HADOOP_OPTS} -Xbootclasspath/p:${ALPN_BOOT_JAR}\"" >> "${HADOOP_CONF_DIR}/hadoop-env.sh"
echo -e "HADOOP_TASKTRACKER_OPTS=\"\${HADOOP_TASKTRACKER_OPTS} -Xbootclasspath/p:${ALPN_BOOT_JAR}\"" >> "${HADOOP_CONF_DIR}/hadoop-env.sh"
echo -e "BIGTABLE_BOOT_OPTS=\"${BIGTABLE_BOOT_OPTS}\"" >> "${HADOOP_CONF_DIR}/hadoop-env.sh"

# TODO: This should probably be removed at some point.  This is done in order
# add in a newer version of guava that's bundled with ${BIGTABLE_RPC_JAR}
echo -e "HADOOP_CLASSPATH=${BIGTABLE_CLASSPATH}:\${HADOOP_CLASSPATH}" >> "${HADOOP_CONF_DIR}/hadoop-env.sh"
echo -e "HADOOP_USER_CLASSPATH_FIRST=true" >> "${HADOOP_CONF_DIR}/hadoop-env.sh"

# Update yarn-env.sh with alpn boot classpath.
echo -e "" >> "${HADOOP_CONF_DIR}/yarn-env.sh"
echo -e "YARN_OPTS=\"\${YARN_OPTS} -Dyarn.app.mapreduce.am.command-opts=\"${BIGTABLE_BOOT_OPTS}\"\"" >> "${HADOOP_CONF_DIR}/yarn-env.sh"

# Update base-env.sh with alpn boot classpath and add the Bigtable classpath to
# the hbase classpath.
echo -e "HBASE_OPTS=\"\${HBASE_OPTS} ${BIGTABLE_BOOT_OPTS}\"" >> "${HBASE_CONF_DIR}/hbase-env.sh"

# Create bigtable wrapper shell scripts for spark-submit and spark-shell 
if [ ! -z "${SPARK_INSTALL_DIR:-}" ]; then 
    # If users want to install Spark and Cloud Bigtable, the Cloud Bigtable argument has to come after Spark
    # If Spark install directory does not exist yet, it means the user includes spark_env.sh in the arguments of bdutil, but put it after bigtable_env.sh
    if [ ! -d "${SPARK_INSTALL_DIR}" ]; then
        logerror "If you are configuring Hadoop, Spark, and Bigtable, please order the input arguments as Hadoop -> Spark -> Bigtable."
        exit 1
    fi

    echo -e "#!/usr/bin/env bash" > "${HBASE_INSTALL_DIR}/bin/execute-with-bigtable.sh"
    cat << EOF >> "${HBASE_INSTALL_DIR}/bin/execute-with-bigtable.sh"
EXECUTE_OPT="\$1"; shift
if [[ "\${EXECUTE_OPT}" != "spark-submit" && "\${EXECUTE_OPT}" != "spark-shell" ]]; then
    echo "Please enter 'spark-submit' or 'spark-shell' as the first argument when calling execute-with-bigtable."
    exit 1
fi
if ! which "\${EXECUTE_OPT}" ; then
    echo "Cannot find "\${EXECUTE_OPT}" on the \\\$PATH."
    exit 1
fi
CONFIG_OPTS=()
APPLICATION_ARGS=()
EXTRA_CLASSPATH=""
contains_jars=0
contains_extra_jars=0

while ((\$#)); do
    case "\$1" in
        --jars)
            contains_jars=1
            # The following line is repeated twice---the first line gets the "--jars", the second lines gets the jars that comes after "--jars". Because Spark accepts other --ARGUMENT, it needs the "--jars" to tell what the jars coming after "--jars" are for.
            CONFIG_OPTS+=("\$1"); shift
            CONFIG_OPTS+=("\$1"); shift
            ;;
        --extraJars)
            contains_extra_jars=1
            shift
            EXTRA_CLASSPATH="\$1"; shift
            ;;
        *)
            APPLICATION_ARGS+=("\$1"); shift
 	    ;;
    esac
done
if (( \${contains_extra_jars} )) && (( \${contains_jars} )); then
    echo "Please only set --jars or --extraJars, not both"
    exit 1
elif (( \${contains_extra_jars} )); then
    CONFIG_OPTS+=( --jars \$((hbase classpath) | tr \":\" \",\"),\${EXTRA_CLASSPATH} )
elif (( ! \${contains_extra_jars} ))  &&  (( ! \${contains_jars} )); then #if does contain jars --> it would've been set in the previous while loop 
    CONFIG_OPTS+=( --jars \$((hbase classpath) | tr \":\" \",\") )
fi
SPARK_DIST_CLASSPATH="\$(hbase classpath)" "\${EXECUTE_OPT}" "\${CONFIG_OPTS[@]}" "\${APPLICATION_ARGS[@]}"
EOF
    chmod 755 "${HBASE_INSTALL_DIR}/bin/execute-with-bigtable.sh"

    echo -e "#!/usr/bin/env bash" > "${HBASE_INSTALL_DIR}/bin/bigtable-spark-submit"
    cat << EOF >> "${HBASE_INSTALL_DIR}/bin/bigtable-spark-submit"
execute-with-bigtable.sh spark-submit "\$@"
EOF
    chmod 755 "${HBASE_INSTALL_DIR}/bin/bigtable-spark-submit"

    echo -e "#!/usr/bin/env bash" > "${HBASE_INSTALL_DIR}/bin/bigtable-spark-shell"
    cat << EOF >> "${HBASE_INSTALL_DIR}/bin/bigtable-spark-shell"
execute-with-bigtable.sh spark-shell "\$@"
EOF
    chmod 755 "${HBASE_INSTALL_DIR}/bin/bigtable-spark-shell"

fi
