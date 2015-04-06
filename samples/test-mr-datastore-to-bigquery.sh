#!/usr/bin/env bash
#
# Copyright 2013 Google Inc. All Rights Reserved.
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
###############################################################################
# Runs WordCount job that reads from Datastore and writes to BigQuery.
################################################################################

# Usage:
#   Specify outputDatasetId and outputTableId explicitly:
#       ./bdutil -v -u "samples/*" run_command ./test-mr-datastore-to-bigquery.sh [outputDatasetId] [outputTableId]
#   Auto-generate tableId inside existing dataset:
#       ./bdutil -v -u "samples/*" run_command ./test-mr-datastore-to-bigquery.sh [outputDatasetId]
#   Auto-generate tableId and datasetId, auto-create the dataset:
#       ./bdutil -v -u "samples/*" run_command ./test-mr-datastore-to-bigquery.sh

set -e

source hadoop-env-setup.sh

DATASET_ID=${PROJECT}
OUTPUT_DATASET_ID=$1
OUTPUT_TABLE_ID=$2

CREATED_DATASET=0
if [[ -z "${OUTPUT_DATASET_ID}" ]]; then
  OUTPUT_DATASET_ID="validate_datastoretobigquery_dataset_$(date +%s)"
  echo "No OUTPUT_DATASET_ID provided; using ${OUTPUT_DATASET_ID}"
  bq mk "${PROJECT}:${OUTPUT_DATASET_ID}"
  CREATED_DATASET=1
fi

if [[ -z "${OUTPUT_TABLE_ID}" ]]; then
  OUTPUT_TABLE_ID="validate_datastoretobigquery_table_$(date +%s)"
  echo "No OUTPUT_TABLE_ID provided; using ${OUTPUT_TABLE_ID}"
fi

# Check for existence of jars
for JAR in datastore_wordcountsetup.jar datastoretobigquery_wordcount.jar; do
  if ! [[ -r ${JAR} ]]; then
    echo "Error. Could not find jar: ${JAR}" >&2
    exit 1
  fi
done

# Upload README.txt
hadoop jar datastore_wordcountsetup.jar ${PROJECT} hadoopSampleWordCountLine \
    hadoopSampleWordCountCount ${HADOOP_INSTALL_DIR}/README.txt

#  Perform word count MapReduce on README.txt
hadoop jar datastoretobigquery_wordcount.jar ${DATASET_ID} ${PROJECT} \
  ${OUTPUT_DATASET_ID} ${OUTPUT_TABLE_ID} hadoopSampleWordCountLine wordcount
echo 'Word count job finished successfully.' \
     "Manually clean up with 'bq rm ${OUTPUT_DATASET_ID}.${OUTPUT_TABLE_ID}'"
if (( ${CREATED_DATASET} )); then
  echo "To delete entire dataset: 'bq rm -r ${OUTPUT_DATASET_ID}'"
fi
