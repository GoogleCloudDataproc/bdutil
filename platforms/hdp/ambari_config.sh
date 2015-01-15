## Name:    ambari_config.sh
## Purpose: Configuration overrides for deployments
##          of Hortonworks Data Platform (HDP)
#######################################################################

## bdutil settings

CONFIGBUCKET="hdp-play-00"
PROJECT="hdp-play-00"
NUM_WORKERS=3
WORKER_ATTACHED_PDS_SIZE_GB=100
MASTER_ATTACHED_PD_SIZE_GB=100
## HDP settings
##  - see `ambari_env.sh` for defaults and explanation

AMBARI_PUBLIC=true

# Ambari Service definition seperated into multiple lines.
#   Always include the 1st line.
AMBARI_SERVICES='HDFS MAPREDUCE2 TEZ YARN SLIDER'
AMBARI_SERVICES+=' ZOOKEEPER GANGLIA PIG SLIDER OOZIE'
AMBARI_SERVICES+=' NAGIOS'
AMBARI_SERVICES+=' FLUME SQOOP'
AMBARI_SERVICES+=' HIVE'
#AMBARI_SERVICES+=' HBASE'
#AMBARI_SERVICES+=' KERBEROS'
#AMBARI_SERVICES+=' FALCON'
#AMBARI_SERVICES+=' KAFKA'
#AMBARI_SERVICES+=' STORM'
#AMBARI_SERVICES+=' KNOX'





