#/bin/bash

echo "*** Backing up Personal folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Personal /Volumes/Backup
echo
echo "*** Backing up Work folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Work /Volumes/Backup
echo
echo "*** Backing up Pictures folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Pictures /Volumes/Backup
echo
echo "*** Backing up Software folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Software /Volumes/Backup
echo
echo "*** Backing up Music folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Music /Volumes/Backup
echo
echo "*** Backing up Movies folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Movies /Volumes/Backup
echo
echo "*** Backing up Old-Stuff folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Old-Stuff /Volumes/Backup
echo

