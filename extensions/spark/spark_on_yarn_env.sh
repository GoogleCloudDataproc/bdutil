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
# with bdutil_env.sh in order to deploy a Hadoop 2 + Spark on YARN cluster.
# Usage: ./bdutil deploy -e extensions/spark/spark_env.sh

# Install YARN and Spark
import_env hadoop2_env.sh
import_env extensions/spark/spark_env.sh

# Clusters must have at least 3 workers to run spark-validate-setup.sh
# and many other Spark jobs.
if [[ -n "${NUM_WORKERS}" ]] || (( ${NUM_WORKERS} < 3 )); then
  NUM_WORKERS=3
fi

# An enum of [default|standalone|yarn-client|yarn-cluster].
# yarn-client and yarn-cluster both run Spark jobs inside YARN containers
# yarn-cluster also runs the spark-class or spark-submit process inside a
# container, but it cannot support spark-shell, without specifying another
# master.
# e.g. spark-shell --master yarn-client.
SPARK_MODE='yarn-client'
