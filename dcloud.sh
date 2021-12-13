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
readonly DCLOUD=/tmp/${FILE}-stripped.csv       # Redirection file (remove header, comments and empty lines)
readonly ADHOC=${HOME}/SessionAdHoc.csv         # Any Sessions that are not part of dCloud - shared by others directly

readonly FORMAT="%3s  %-7s %s\n"                # Formatter for displaying on screen
readonly SCRIPT_NAME=$(basename $0)             # This script's name
readonly PID_FILE=/tmp/openconnect.pid

readonly PORT_FORWARDING=13389:198.18.133.252:3389

DOMAIN=rtp                                      # Default dCloud domain

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

  find ${SESSIONS_DIR} -maxdepth 1 -type f -name 'SessionDetails*.csv' \
    -exec cat "{}" \; \
    | grep -v "Session Id" \
    | cut -d "," -f 1,2,3,4 >> ${SESSIONS}

  if [[ -f ${ADHOC} ]]; then
    echo "Merging AdHoc File ...    [${ADHOC}]";
    cat ${ADHOC} | grep -v "Session Id" >> ${SESSIONS};
  fi

  grep -v "^#" ${SESSIONS} | grep -v "^[[:space:]]*$"  | sort -u  > ${DCLOUD}

  if [[ ! -s ${DCLOUD} ]]; then
    echo "No sessions found"
    cleanup
    exit 1
  fi

}

######################################################################
function present () {

  echo "Current domain set to ... [dcloud-${DOMAIN}-anyconnect.cisco.com]"
  echo
  echo "#####################################"
  echo "# Select a dCloud instance to login #"
  echo "#####################################"
  echo

  printf "${FORMAT}" "" "ID" "Title";
  local sid title rest
  local i=0
  while ((i++)); IFS=',' read -r sid title rest; do
    printf "${FORMAT}" "${i})" ${sid} "${title}";
  done < ${DCLOUD}
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
  while ((i++)); IFS=',' read -r sid title user pass; [[ ${i} -lt $1 ]]; do
    true
  done < ${DCLOUD}

  user=${user%%;*}
  pass=${pass##=\"}; pass=${pass%\"}
  echo "Connecting to session ID [${sid}] as user [${user}]"
  echo

  echo ${pass} | openconnect --quiet --no-dtls \
    --user=${user} --passwd-on-stdin \
    --background --pid-file=${PID_FILE} \
    https://dcloud-${DOMAIN}-anyconnect.cisco.com

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
  rm -f ${SESSIONS} ${DCLOUD}
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
    DOMAIN=${input:4}
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
