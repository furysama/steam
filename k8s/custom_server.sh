#!/bin/bash
#
# Runs as root. Drop privileges.
#
# Capture kill/term signal and send SIGINT to gracefully shutdown conan server.
PROCESS_WAIT_TIME=25
WATCHDOG_TIME=300

function shutdown() {
  echo 'Shutting down server ...'
  if [ "$(pgrep -n Conan)" != '' ]; then
    echo "Sending SIGINT to Conan server (max ${PROCESS_WAIT_TIME} secs) ..."
    kill -SIGINT `pgrep -n Conan`
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
  su - steam -c "xvfb-run --auto-servernum wine64 ${SERVER_DIR}/LastOasis - Dedicated Server/MistServer.exe -log -force_steamclient_link -messaging -NoLiveServer -EnableCheats -backendapiurloverride="backend.last-oasis.com" -identifier=${SERVER_IDENTIFIER} -port=${SERVER_PORT} -CustomerKey=${CUSTOMER_KEY} -ProviderKey=${HOSTING_KEY} -slots=10 -QueryPort=27015 -OverrideConnectionAddress=${SERVER_IP}"
}

function watch_server() {
  if ps aux | grep [C]onanSandboxServer > /dev/null; then
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
