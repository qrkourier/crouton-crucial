#!/bin/bash -e
#

# title           :crucial.sh
# description     :a helper script for Crouton
# author          :w@qrk.us
# date            :20160124
# bash version    :4.2.48
# crouton version :1-20160116142703~master:d9b40a7f

# if any exit code is non-zero then bail out
set -o errexit

# complain helpfully
funcUsage() {
  >&2 echo "
$*

Usage: 
  $ sudo bash ./crucial.sh [OPTIONS]

Summary:
  Apply runcom and invoke enter-chroot, optionally first doing any of
  bootstrap, backup, or update

Options:
    -a          awake: disable power management before startup
    -b          invoke edit-chroot to backup before startup
    -c FILE     override default runcom file: ./crucial.rc
    -i RELEASE  invoke crouton to install RELEASE or "list" 
    -u          invoke crouton to update the chroot before startup

Hints:
  # switch to the Crucial installation directory to run it, e.g.
    $ cd /media/removable/USB32/crouton-crucial

  # copy the sample runcom file and configure the copy for your instance;
  # configuration options are described in-line
    $ cp crucial.rc precise.rc

  # Crucial can manage an existing Crouton instance; just ensure the runcom
  # file reflects its attributes

Examples:
  # Crucial can install a Crouton instance described by a runcom file
    $ sudo bash ./crucial.sh -c ./precise.rc -i precise

  # disable idle and lid suspend and start up the only installed
  # instance; this implies '-c ./crucial.rc' 
    $ sudo bash ./crucial.sh -a

  # backup, update, and start up an instance 
    $ sudo bash ./crucial.sh -buc ./precise.rc
"
  exit 1
}

funcInstall() {
  bash ./crouton -p ${CRCHROOTDIR%/chroots} -t $CRTARGETS -r $1 $THISNAMEOPT
}

funcBackup() {
  # assemble the tarball file name; determine the 2-digit backup number by
  # dividing the day of the month by the CRPOLICY integer from the runcom file
  THISTARBALL="${CRBACKUPS:?}/crouton-${CRNAME:?}-$(
    printf '%02d\n' $((
      $(date +%e)/${CRPOLICY:?}
    ))
  ).tar"
  
  # backup the specified chroot; edit-chroot will not guess the name, so it
  # must be given in the runcom file 
  edit-chroot -c $CRCHROOTDIR -bf $THISTARBALL ${CRNAME:?}
 
  # report!
  printf '\nFinished backing up %s to %s\n' $(du -h $THISTARBALL)
  THISBACKUPDIR=$(dirname $THISTARBALL)
  ls -goht $THISBACKUPDIR/crouton-*.tar
  
  # give 'em a few seconds to see the report
  for i in {0..9};do sleep 1;printf '.';done
}

funcUpdate() {
  # ./crouton expects the -p path to contain a "chroots" dir
  # and searches it for a matching CRNAME
  bash ./crouton -u -p ${CRCHROOTDIR%/chroots} -n ${CRNAME:?}
}

while getopts ":abc:hi:u" THISOPT;do
  case $THISOPT in
    a)
      KEEPAWAKE=true
      ;;
    b)
      BACKUPFIRST=true
      ;;
    c)
      THISRCFILE=$OPTARG
      ;;
    h)
      funcUsage
      ;;
    i)
      INSTALLFIRST=$OPTARG
      ;;
    u)
      UPDATEFIRST=true
      ;;
    \?|:)
      funcUsage "Unrecognized option or argument expected in '-$OPTARG'"
      ;;
  esac
done

#
##
#

# require a runcom file that exists and is not empty and is not this file and
# is named ending *rc; if not defined then look for the sample runcom
[[ -s "${THISRCFILE:=./crucial.rc}" && \
  "$(readlink -f $THISRCFILE)" != "$(readlink -f $0)" && \
  "$THISRCFILE" =~ rc$ ]] || { 
    funcUsage "$THISRCFILE is not a valid runcom file"; 
}
source $THISRCFILE

#
##
#

# if CRNAME is not defined in the runcom then let THISNAMEOPT remain empty;
# else assign 
THISNAMEOPT=${CRNAME:+"-n $CRNAME"}
echo "The Crouton chroots dir is ${CRCHROOTDIR:=/usr/local/chroots}"
echo "The name of this Crouton instance is ${CRNAME:=precise}"

# install?
[[ -z "$INSTALLFIRST" ]] || { funcInstall $INSTALLFIRST; }

# backup?
[[ -z "$BACKUPFIRST" ]] || { funcBackup; }

# update?
[[ -z "$UPDATEFIRST" ]] || { funcUpdate; }

# launch
STARTUPOPTS="-c $CRCHROOTDIR $THISNAMEOPT $CRSTARTCMD"
if [[ -n "$KEEPAWAKE" ]];then
  bash ./keepawake.sh $STARTUPOPTS
else
  bash enter-chroot $STARTUPOPTS
fi

