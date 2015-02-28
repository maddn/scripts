#!/bin/bash

~/scripts/prime_gpg_agent.sh

USERID=CISCO\\mmaddern
PASSWORD=$(gpg --use-agent --quiet --batch -d ~/.passwd/cisco.gpg)
TEMP_LOCATION=/mnt/data/shared/Temp
FULL_PATH=$(readlink -f "$@");

if [ $(vmrun -T player list | grep -c Windows) -eq 0 ]; then
    echo "Error: Windows VM not running";
    exit;
fi;

echo "File full path: $FULL_PATH";

if [ $(echo $FULL_PATH | cut -b 1-16) != "/mnt/data/shared" ]; then
    NEW_FILE=$TEMP_LOCATION/$(basename "$FULL_PATH");
    echo "Copying to $NEW_FILE"
    if [ -e "$NEW_FILE" ]; then
        echo "ERROR: Temporary file already exists. Aborting.";
        exit;
    fi;
    cp "$FULL_PATH" "$NEW_FILE"
    FULL_PATH=$NEW_FILE;
fi;

FILE=$(echo $FULL_PATH | sed 's/\/mnt\/data\/shared/Z\:\\Shared/g' | sed 's/\//\\/g');
echo "Converting to $FILE";

echo "Running in VMWare...";
vmrun -T player \
    -gu $USERID -gp $PASSWORD runProgramInGuest \
    "/mnt/data/vmware/Windows 7 x64/Windows 7 x64.vmx" \
    -activeWindow -interactive \
    "C:\Windows\System32\cmd.exe" "/C Start /WAIT \"\" \"$FILE\""

if [ -n "$NEW_FILE" ]; then
    echo "Deleting $NEW_FILE";
    rm "$NEW_FILE"
fi;
