## Prep

```
CONFIGBUCKET=hdp-00
PROJECT=hdp-00
switches="-b ${CONFIGBUCKET} -p ${PROJECT}"

# add this to make it a smaller test than the defaults
switches+="
    --master_attached_pd_size_gb 100
    --worker_attached_pds_size_gb 100
    -n 1
    -m n1-standard-2"


bdutil="./bdutil ${switches}"
```

## Test ambari_env.sh

```
environment=platforms/hdp/ambari_env.sh
bdutil="${bdutil} -e ${environment}"

## deploy
${bdutil} deploy

## test
${bdutil} shell < ./hadoop-validate-setup.sh
${bdutil} shell < ./hadoop-validate-gcs.sh
${bdutil} shell < ./extensions/querytools/hive-validate-setup.sh
${bdutil} shell < ./extensions/querytools/pig-validate-setup.sh
#${bdutil} shell < ./extensions/spark/spark-validate-setup.sh

## delete
${bdutil} delete
```


## Test ambari_manual_env.sh

```
environment=platforms/hdp/ambari_manual_env.sh
bdutil="${bdutil} -e ${environment}"

## deploy
${bdutil} deploy

## test
# need to add an automated test here:
    ${bdutil} shell # do something here like check the appropriate number of hosts in /api/v1/hosts

## delete
${bdutil} delete

```

## Test re-using disks across multiple deployments of same instance count

```
environment=platforms/hdp/ambari_env.sh
bdutil="${bdutil} -e ${environment}"
unset CREATE_ATTACHED_PDS_ON_DEPLOY
unset DELETE_ATTACHED_PDS_ON_DELETE

## create
export CREATE_ATTACHED_PDS_ON_DEPLOY=true
${bdutil} deploy

## generate some data onto HDFS, and dont’ delete it
echo "hadoop fs -mkdir redeploy-validation.tmp" | ${bdutil} shell

## if you want more data than that:
#${bdutil} -u hadoop-validate-setup.sh run_command -- \
#    sudo -u "$(whoami)" TERA_CLEANUP_SKIP=true TERA_GEN_NUM_RECORDS=100000 ./hadoop-validate-setup.sh

## check that the ‘validate_...’ dir is there
echo "hadoop fs -ls" | ${bdutil} shell

## delete the cluster but keep disks
export DELETE_ATTACHED_PDS_ON_DELETE=false
${bdutil} delete

## create with existing disks
export CREATE_ATTACHED_PDS_ON_DEPLOY=false
${bdutil} deploy

## check that the ‘validate_...’ dir is there
echo "hadoop fs -ls" | ${bdutil} -e ${environment} shell

## delete everything to cleanup this testing
export DELETE_ATTACHED_PDS_ON_DELETE=true
${bdutil} delete
```
