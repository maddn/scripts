#!/bin/bash

~/scripts/prime_gpg_agent.sh

USERID=mmaddern
PASSWORD=$(gpg --use-agent --quiet --batch -d ~/.passwd/softoken.gpg)
COUNT=0
CONF_FILE=$1

if [ -z $CONF_FILE ]; then
    CONF_FILE="default";
fi;

CONF_FILE="/etc/vpnc/$CONF_FILE.conf"

echo "Generating passcode..."
cd ~/.wine/drive_c/Program\ Files/Secure\ Computing/SofToken-II/
PASSCODE=$(wine Console_UI.exe $USERID <<<$PASSWORD | tail -1 | cut -c30-37)

echo "Xauth password $PASSCODE" >> $CONF_FILE

echo "Connecting to VPN..."
VPNC_OUTPUT="$(sudo vpnc $CONF_FILE 2>&1)"
echo "$VPNC_OUTPUT"

while [ "$VPNC_OUTPUT" = "vpnc: no response from target" ]; do
    if [ $COUNT -ge 5 ]; then
        echo "Failed to connect to VPN after $COUNT attempts";
        break;
    fi;
    echo "Retrying...";
    COUNT=$(($COUNT+1));
    VPNC_OUTPUT="$(sudo vpnc $CONF_FILE 2>&1)"
    echo "$VPNC_OUTPUT"
done;

DEFAULT_CONF=$(head -n -1 $CONF_FILE)
echo "$DEFAULT_CONF" > $CONF_FILE

if [ $(pgrep -c vpnc) -lt 2 ]; then
    echo "Failed: vpnc not running. Retry with passcode $PASSCODE";
fi;

