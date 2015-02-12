#!/usr/bin/env bash
#
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

# Runs some basic "hello world" logic to test parallelization, basic grouping
# functionality, persisting an RDD to the distributed filesystem, viewing the
# same files with "hadoop fs", reading it back in with Spark, and finally
# deleting the files with "hadoop fs".
#
# Usage: ./bdutil shell < spark-validate-setup.sh
#
# Warning: If the script returns a nonzero code, then there may be some test
# files which should be cleaned up; you can find these with
# hadoop fs -ls validate_spark_*

set -e

# Find hadoop-confg.sh
HADOOP_CONFIGURE_CMD=''
HADOOP_CONFIGURE_CMD=$(find ${HADOOP_LIBEXEC_DIR} ${HADOOP_PREFIX} \
    /home/hadoop /usr/*/hadoop* /usr/*/current/hadoop* -name hadoop-config.sh | head -n 1)

# If hadoop-config.sh has been found source it
if [[ -n "${HADOOP_CONFIGURE_CMD}" ]]; then
  echo "Sourcing '${HADOOP_CONFIGURE_CMD}'"
  . ${HADOOP_CONFIGURE_CMD}
fi

HADOOP_CMD="${HADOOP_PREFIX}/bin/hadoop"

# Find the spark-shell command.
SPARK_SHELL=$(find /home/hadoop -name spark-shell | head -n 1)

# Create a unique directory for testing RDD persistence.
PARENT_DIR="/validate_spark_$(date +%s)"

set -x
# Get info about the cluster.
SPARK_CONF_DIR="$(dirname ${SPARK_SHELL})/../conf"
NUM_EXECUTORS=$(wc -l < ${SPARK_CONF_DIR}/slaves)

# Test if we are submitting on YARN
if grep -q '^spark.master\s*yarn' ${SPARK_CONF_DIR}/spark-defaults.conf \
    || grep -q '^[^#]*MASTER=yarn' ${SPARK_CONF_DIR}/spark-env.sh; then
  if (( ${NUM_EXECUTORS} < 3 )); then
    echo 'Spark requires 3 executors to run this script on YARN' >&2
    exit 1
  fi
  # Subtract one node for the AppMaster.
  SPARK_SHELL+=" --num-executors $(( --NUM_EXECUTORS )) "

  # Subract one more for an unknown reason.
  (( NUM_EXECUTORS-- ))
fi

NUM_CPUS=$(grep -c ^processor /proc/cpuinfo)
# Double the cores to have a better chance of using them all.
NUM_SHARDS=$((${NUM_EXECUTORS} * ${NUM_CPUS} * 2))
echo "NUM_EXECUTORS: ${NUM_EXECUTORS}"
echo "NUM_CPUS: ${NUM_CPUS}"
echo "NUM_SHARDS: ${NUM_SHARDS}"

# Create an RDD.
${SPARK_SHELL} << EOF
import java.net.InetAddress
val greetings = sc.parallelize(1 to ${NUM_SHARDS}).map({ i =>
  (i, InetAddress.getLocalHost().getHostName(),
   "Hello " + i + ", from host " + InetAddress.getLocalHost().getHostName())
})

val uniqueHostnames = greetings.map(tuple => tuple._2).distinct()
println("Got unique hostnames:")
for (hostname <- uniqueHostnames.collect()) {
  println(hostname)
}
val uniqueGreetings = greetings.map(tuple => tuple._3).distinct()
println("Unique greetings:")
for (greeting <- uniqueGreetings.collect()) {
  println(greeting)
}

val numHostnames = uniqueHostnames.count()
if (numHostnames != ${NUM_EXECUTORS}) {
  println("Expected ${NUM_EXECUTORS} hosts, got " + numHostnames)
  exit(1)
}

val numGreetings = uniqueGreetings.count()
if (numGreetings != ${NUM_SHARDS}) {
  println("Expected ${NUM_SHARDS} greetings, got " + numGreetings)
  exit(1)
}

greetings.saveAsObjectFile("${PARENT_DIR}/")
exit(0)
EOF

# Check it with "hadoop fs".
echo "Checking _SUCCESS marker with 'hadoop fs'..."
NUM_FILES=$(${HADOOP_CMD} fs -ls ${PARENT_DIR}/part-* | wc -l | cut -d ' ' -f 1)
echo "Found ${NUM_FILES} files."
${HADOOP_CMD} fs -stat "${PARENT_DIR}/_SUCCESS"

# Read the RDD back in and verify it.
${SPARK_SHELL} << EOF
val greetings = sc.objectFile[(Int, String, String)]("${PARENT_DIR}/")

val uniqueHostnames = greetings.map(tuple => tuple._2).distinct()
println("Got unique hostnames:")
for (hostname <- uniqueHostnames.collect()) {
  println(hostname)
}
val uniqueGreetings = greetings.map(tuple => tuple._3).distinct()
println("Unique greetings:")
for (greeting <- uniqueGreetings.collect()) {
  println(greeting)
}

val numHostnames = uniqueHostnames.count()
if (numHostnames != ${NUM_EXECUTORS}) {
  println("Expected ${NUM_EXECUTORS} hosts, got " + numHostnames)
  exit(1)
}

val numGreetings = uniqueGreetings.count()
if (numGreetings != ${NUM_SHARDS}) {
  println("Expected ${NUM_SHARDS} greetings, got " + numGreetings)
  exit(1)
}
exit(0)
EOF

echo "Cleaning up ${PARENT_DIR}..."
${HADOOP_CMD} fs -rmr ${PARENT_DIR}
echo 'All done!'
