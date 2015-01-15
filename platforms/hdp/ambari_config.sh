## Name:    ambari_config.sh
## Purpose: Configuration overrides for deployments
##          of Hortonworks Data Platform (HDP)
#######################################################################

## HDP settings
##  - see `ambari_env.sh` for defaults and explanation

AMBARI_PUBLIC=true
AMBARI_SERVICES='FLUME GANGLIA HDFS MAPREDUCE2 NAGIOS OOZIE PIG SLIDER SQOOP TEZ YARN ZOOKEEPER'


## bdutil settings

NUM_WORKERS=3
WORKER_ATTACHED_PDS_SIZE_GB=100
MASTER_ATTACHED_PD_SIZE_GB=100

