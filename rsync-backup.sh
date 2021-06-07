#!/bin/bash

do_rsync() {
    echo "*** Backing up $1 ***"
    eval "rsync $DRY_RUN \
      --archive \
      --verbose \
      --modify-window=1 \
      --rsh=ssh \
      --exclude='.DS_Store' \
      --exclude='$RECYCLE.BIN/' \
      --exclude='.svn' \
      --exclude='.git' \
      --exclude='node_modules' \
      --exclude='.localized' \
      --exclude='TV Library.tvlibrary' \
      --exclude='Photos Library.photoslibrary' \
      --exclude='Music Library.musiclibrary' \
      --exclude='GarageBand' \
      --exclude='@eaDir' \
      $3 $1 maddn@192.168.1.100::$2"
}

if [ "$1" == "-d" ]; then
   DRY_RUN="--dry-run"
else
   unset DRY_RUN
fi

echo $DRY_RUN
do_rsync ~/nso/ nso --delete
do_rsync ~/Work/ work --delete
do_rsync ~/Personal/ personal --delete
do_rsync ~/Pictures/ pictures --delete
do_rsync ~/Music/ music --delete
do_rsync "~/Movies/iMovie\ Library.imovielibrary/" "video/iMovie\ Library.imovielibrary" --delete
