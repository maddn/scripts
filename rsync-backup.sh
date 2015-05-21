#/bin/bash

echo "*** Backing up Personal folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Personal /mnt/backup
echo
echo "*** Backing up Work folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Work /mnt/backup
echo
echo "*** Backing up Pictures folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Pictures /mnt/backup
echo
echo "*** Backing up Software folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Software /mnt/backup
echo
echo "*** Backing up Music folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Music /mnt/backup
echo
echo "*** Backing up Movies folder ***"
rsync -rtv --modify-window=1 --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Movies /mnt/backup
echo
echo "*** Backing up Old-Stuff folder ***"
rsync -rtv --modify-window=1 --delete --exclude='.localized' --exclude='.DS_Store' --exclude='$RECYCLE.BIN/' ~/Old-Stuff /mnt/backup
echo

