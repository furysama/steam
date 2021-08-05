#!/bin/bash
#
# Runs as root. Drop privileges.
#
# Capture kill/term signal and send SIGINT to gracefully shutdown conan server.
PROCESS_WAIT_TIME=25
WATCHDOG_TIME=300

function shutdown() {
  echo 'Shutting down server ...'
  if [ "$(pgrep -n Mist)" != '' ]; then
    echo "Sending SIGINT to LO server (max ${PROCESS_WAIT_TIME} secs) ..."
    kill -SIGINT `pgrep -n Mist`
    sleep ${PROCESS_WAIT_TIME}
  fi
  if [ "$(pgrep wine)" != '' ]; then
    echo "Sending SIGINT to wine processes (max ${PROCESS_WAIT_TIME} sec) ..."
    kill -SIGINT `pgrep wine`
    sleep ${PROCESS_WAIT_TIME}
  fi
  exit 0
}
trap shutdown SIGINT SIGKILL SIGTERM

function start_server() {
  export SERVER_IP=$(wget -qO-  --header="Metadata-Flavor: Google" metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
  echo "903950" > ${SERVER_DIR}/Mist/Binaries/Linux/steam_appid.txt
  su - steam -c "${SERVER_DIR}/MistServer.sh -log -force_steamclient_link -messaging -NoLiveServer -EnableCheats -backendapiurloverride="backend.last-oasis.com" -identifier=${SERVER_IDENTIFIER} -port=${SERVER_PORT} -CustomerKey=${CUSTOMER_KEY} -ProviderKey=${HOSTING_KEY} -slots=10 -QueryPort=${QUERY_PORT} -OverrideConnectionAddress=${SERVER_IP}"
}

function watch_server() {
  if ps aux | grep [M]istServer-Linux-Shipping > /dev/null; then
    echo 'Server is running ...'
  else
    echo 'Starting server ...'
    start_server &
  fi
}

while true; do
  watch_server
  # background and using wait enables trap capture.
  sleep ${WATCHDOG_TIME} &
  wait
done
