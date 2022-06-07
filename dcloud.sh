#!/bin/bash

########################################################################
#
#   Login to your dCloud account and goto your 'My Hub' page
#
#   Use the 'Download Details' button (top right) to get your list
#   by default this (SessionDetails) will go into your 'Downloads' DIR
#
#   Cleanup manually any previous 'SessionDetails.csv' files as needed
#   Script will merge all into one and sort 'unique' by Session ID
#
#   NOTE: needs elevated privileges for tunnel setup (sudo OR root)
#         sudo works best as it read local account directories :-)
#
#   NEED: needs openconnect package installed
#
########################################################################

readonly FILE=SessionDetails
readonly HOME_DIR=/home/mmaddern

readonly SESSIONS_DIR=${HOME_DIR}/Downloads     # Where the SessionDetails files usually go
readonly SESSIONS=/tmp/${FILE}-all.csv          # Temp file to store ALL Sessions downloaded

readonly FORMAT="%3s  %-7s %-4s %s\n"           # Formatter for displaying on screen
readonly SCRIPT_NAME=$(basename $0)             # This script's name
readonly PID_FILE=/tmp/openconnect.pid

readonly PORT_FORWARDING=13389:198.18.133.252:3389

DEFAULT_DATACENTRE=rtp                          # Default dCloud domain

######################################################################
function prg_usage () {

  # Help Message
  echo
  echo "${SCRIPT_NAME} : Use this shell script to automate dCloud VPN sessions"
  echo
  echo "Usage: ${SCRIPT_NAME} [dom=<domain name>] [-d]"
  echo
  echo "Options:"
  echo " -h          This help message"
  echo " -d          Disconnect the running VPN"
  echo " [dom=...]   can be 'rtp' sjc' 'lon', etc - DEFAULT : rtp"
  echo
  exit 0

}

######################################################################
function merge() {

  echo "Merging Session Files ... [${SESSIONS_DIR}]"
  cp /dev/null "${SESSIONS}" # Initialize file - blank it

  for filename in ${SESSIONS_DIR}/SessionDetails*.csv; do
    local datacentre=${filename##${SESSIONS_DIR}/SessionDetails}
    datacentre=${datacentre%%.csv}
    if [[ ${#datacentre} -eq 4 && ${datacentre:0:1} == '.' ]]; then
      datacentre=${datacentre:1:3}
    else
      datacentre=${DEFAULT_DATACENTRE}
    fi
    server="https://dcloud-${datacentre}-anyconnect.cisco.com"

    while IFS=',' read -r sid title user pass rest || [[ -n ${sid} ]]; do
      if [[ -n ${sid} && ${sid} != "Session Id" && ${sid:0:1} != "#" ]]; then
        echo "${sid},${datacentre},${title},${user},${pass},${server}" >> ${SESSIONS}
      fi
    done < ${filename}
  done

  if [[ -f ${SESSIONS_DIR}/SessionsOther.csv ]]; then
    while IFS=',' read -r sid server_name title user pass server rest || [[ -n ${sid} ]]; do
      if [[ -n ${sid} && ${sid} != "Session Id" && ${sid:0:1} != "#" ]]; then
        echo "${sid},${server_name},${title},${user},${pass},${server}" >> ${SESSIONS}
      fi
    done < ${SESSIONS_DIR}/SessionsOther.csv
  fi

}

######################################################################
function present () {

  echo
  echo "#####################################"
  echo "# Select a dCloud instance to login #"
  echo "#####################################"
  echo

  printf "${FORMAT}" "" "ID" "DC" "Title";
  local sid title rest
  local i=0
  while ((i++)); IFS=',' read -r sid datacentre title rest; do
    printf "${FORMAT}" "${i})" ${sid} "${datacentre^^}" "${title}";
  done < ${SESSIONS}
  echo

  NUM_SESSIONS=$((${i}-1))

}

######################################################################
function edit_nat_rule() {
  local nat_rule=$1
  local action=$2

  if iptables -t nat -C ${nat_rule} > /dev/null 2>&1; then
    if [[ ${action} == "D" ]]; then
      iptables -t nat -D ${nat_rule}
    fi
  elif [[ ${action} == "A" ]]; then
    iptables -t nat -A ${nat_rule}
  fi
}

######################################################################
function edit_routing() {

  local local_port dest_ip_address dest_port
  for rule in ${PORT_FORWARDING}; do
    IFS=':' read -r local_port dest_ip_address dest_port <<< "${rule}"
    local prerouting="PREROUTING -p tcp --dport ${local_port} \
      -j DNAT --to-destination ${dest_ip_address}:${dest_port}"
    edit_nat_rule "${prerouting}" $1
  done

  if [[ -n ${PORT_FORWARDING} ]]; then
    local postrouting="POSTROUTING -j MASQUERADE"
    edit_nat_rule "${postrouting}" $1
    echo
    echo "Current IP NAT Routing Table ..."
    echo
    iptables -t nat -L
    echo
  fi

}

######################################################################
function login () {

  local sid title user pass
  local i=0
  while ((i++)); IFS=',' read -r sid datacentre title user pass server; [[ ${i} -lt $1 ]]; do
    true
  done < ${SESSIONS}

  user=${user%%;*}
  pass=${pass##=\"}; pass=${pass%\"}
  server=${server%%$'\r'}
  echo "Connecting to session ID [${sid}] as user [${user}]"
  echo

  echo ${pass} | openconnect --quiet --no-dtls \
    --user=${user} --passwd-on-stdin \
    --background --pid-file=${PID_FILE} \
    ${server}

  local status=$?
  local start=$(date)
  sleep 2

  echo
  echo "Current IP Routes ..."
  echo
  ip route show
  echo

  if [[ ${status} -eq 0 ]]; then
    edit_routing "A"

    echo
    echo "#############################################"
    echo "# Connected at ${start} #"
    echo "#############################################"
    echo
    echo "Use '${SCRIPT_NAME} -d' to disconnect"
  else
    echo
    echo "Error starting VPN"
  fi

}

######################################################################
function cleanup() {
  # Delete temp / redirection files
  rm -f ${SESSIONS}
}

######################################################################
function connect() {

  if [[ -f ${PID_FILE} ]]; then
    echo "There is already a session connected."
    echo "The PID file already exists. [${PID_FILE}]"
    exit 1
  fi

  merge
  present

  local option
  read -p \
    "Select your dCloud instance session (any other option to quit) : " option
  if [[ "${option}" == +([0-9]) ]] &&
      [[ ${option} -gt 0 ]] && [[ ${option} -le ${NUM_SESSIONS} ]]
  then
    login ${option}
  fi

  cleanup

}

######################################################################
function disconnect () {

  edit_routing "D"

  if [[ ! -f ${PID_FILE} ]]; then
    echo "The PID file does not exist. [${PID_FILE}]"
    exit 1
  fi

  local pid=$(cat ${PID_FILE})
  echo "Killing openconnect ... [PID: ${pid}]"
  kill ${pid}
  sleep 2

  echo
  echo "Current IP Routes ..."
  echo
  ip route show

}

######################################################################
function main () {

  if [[ "$EUID" -ne 0 ]]
    then echo "This script must be ran as root"
    exit 1
  fi

  local input=$1
  if [[ "${input:0:4}" == "dom=" ]]; then
    DEFAULT_DATACENTRE=${input:4}
    shift
  fi

  case $1 in
    "-h" | "--help")
      prg_usage
      ;;

    "" | "-c" | "--connect")
      connect
      ;;

    "-d" | "--disconnect")
      disconnect
      ;;

    *)
      echo
      echo "Error: '$1' is not a known command." >&2
      echo "       Run '${SCRIPT_NAME} --help' for a list of known commands." >&2
      echo
      exit 1
      ;;
  esac
}

# Execute
main "$@"
