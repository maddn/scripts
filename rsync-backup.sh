#/bin/bash

do_rsync() {
echo "*** Backing up $1 ***"
rsync $DRY_RUN \
      --recursive \
      --times \
      --verbose \
      --links \
      --modify-window=1 \
      --rsh=ssh \
      --exclude='.localized' \
      --exclude='.DS_Store' \
      --exclude='$RECYCLE.BIN/' \
      --exclude='.picasa.ini' \
      --exclude='Photo Booth Library' \
      --exclude='iMovie Library.imovielibrary' \
      --exclude='iMovie Theater.theater' \
      --exclude='.svn' \
      --exclude='.git' \
      $3 $1 admin@192.168.1.100::$2
echo
}

if [ "$1" == "-d" ]; then
   DRY_RUN="--dry-run"
else
   unset DRY_RUN
fi

echo $DRY_RUN
do_rsync ~/Personal/ personal --delete
do_rsync ~/Pictures/ pictures --delete
do_rsync ~/Music/ music
do_rsync ~/Movies/ video
do_rsync ~/nso/ nso --delete
do_rsync ~/Software/ software --delete
do_rsync ~/Work/ work --delete
do_rsync ~/Old-Stuff/ old-stuff --delete



