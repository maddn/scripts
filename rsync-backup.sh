#/bin/bash

do_rsync() {
echo "*** Backing up $1 ***"
rsync $DRY_RUN \
      --recursive \
      --times \
      --verbose \
      --modify-window=1 \
      --exclude='.localized' \
      --exclude='.DS_Store' \
      --exclude='$RECYCLE.BIN/' \
      --exclude='.picasa.ini' \
      --exclude='.picasa.ini' \
      --exclude='iMovie Library.imovielibrary' \
      --exclude='iMovie Theater.theater' \
      --exclude='.svn' \
      --exclude='.git' \
      $2 $1 /mnt/backup
echo
}

if [ "$1" == "-d" ]; then
   DRY_RUN="--dry-run"
else
   unset DRY_RUN
fi

echo $DRY_RUN
do_rsync ~/Personal --delete
do_rsync ~/Pictures --delete
do_rsync ~/Music --delete
do_rsync ~/Movies
do_rsync ~/Software --delete
do_rsync ~/Work --delete
do_rsync ~/Old-Stuff --delete

