# TODO add licence

set -o nounset
set -o errexit

if [[ ${FLINK_MODE} == 'standalone' ]]; then
  sudo -u hadoop ${FLINK_INSTALL_DIR}/bin/start-cluster.sh
fi