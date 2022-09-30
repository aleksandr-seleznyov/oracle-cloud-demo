#!/bin/bash

set -e

export EMAIL=""
export TELEPORT_HOST=""

GRAY='\033[0;31m'
NC='\033[0m' # No Color

pause() {
  local step="${1}"
  ps1
  echo -e -n "${GRAY}# Next step: ${step}${NC}"
  read
}

ps1() {
  echo -ne "\033[01;32m${USER}@$(hostname -s) \033[01;34m$(basename $(pwd)) \$ \033[00m"
}


echocmd() {
  echo "$(ps1)$@"
}

docmd() {
  echocmd "$@"
  read
  $@
}

pause "Waiting for start"

pause "Disable firewalld"
  docmd sudo systemctl stop firewalld
  docmd sudo systemctl disable firewalld


pause "install teleport"
  docmd sudo yum-config-manager --add-repo https://rpm.releases.teleport.dev/teleport.repo -y
  docmd sudo yum install teleport -y

pause "generate initial teleport configuration"
  docmd sudo /usr/local/bin/teleport configure --acme --acme-email="${EMAIL}" --cluster-name="${TELEPORT_HOST}" | sudo tee /etc/teleport.yaml

pause "start teleport service"
  docmd sudo systemctl enable teleport
  docmd sudo systemctl start teleport
  docmd sudo systemctl sta teleport

pause "create initial user"
  docmd sudo /usr/local/bin/tctl users add teleport-admin --roles=editor,access --logins=opc


pause 'All steps all done!'

