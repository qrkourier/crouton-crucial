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
  Invoke enter-chroot with the parameters from the runcom file for that
  instance; optionally first doing install, backup, update; or all three

Options:
    -a          keep awake: disable power management 
    -b          save a backup and enforce the retention policy
    -i RELEASE  install Crouton and RELEASE or 
                substitute "list" to print candidates
    -r FILE     override ./crucial.rc
    -u          update the chroot

Hints:
  # make a copy of crucial.rc for each Crouton chroot 
  # Crucial can manage a new or pre-existing Crouton instance

Examples:
  # Crucial can install a Crouton instance described by a runcom file
    $ sudo bash ./crucial.sh -c ./precise.rc -i precise

  # disable idle and lid suspend and start up; implies '-c ./crucial.rc' 
    $ sudo bash ./crucial.sh -a

  # backup, update, and start up an instance 
    $ sudo bash ./crucial.sh -buc ./precise.rc
"
  exit 1
}

funcBootstrap() {
  if ! { umask 022 && \
    curl -# -L --connect-timeout 60 --max-time 300 --retry 2 "$CRINSTALLER" -o \
      "$THISWORKINGDIR/crouton"; }; then
    funcUsage "Failed to bootstrap Crouton."
  fi
}

funcInstall() {
  if ! [[ -s $THISWORKINGDIR/crouton ]];then
    funcBootstrap
  fi
  bash $THISWORKINGDIR/crouton -p ${CRCHROOTDIR%/chroots} -t ${CRTARGETS:?} -r $1 -n ${CRNAME:?} 2>/dev/null || \
    funcUsage \
      "Crucial was unable to install the chroot. You can run the command yourself to troubleshoot:
      $ sudo bash $THISWORKINGDIR/crouton -p ${CRCHROOTDIR%/chroots} -t ${CRTARGETS:?} -r $1 -n ${CRNAME:?}"
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
  edit-chroot -c $CRCHROOTDIR -bf $THISTARBALL ${CRNAME:?} 2>/dev/null || \
    funcUsage "
      Crucial was unable to back up the chroot. You can run the command yourself to troubleshoot:
      $ sudo edit-chroot -c $CRCHROOTDIR -bf $THISTARBALL ${CRNAME:?}"
 
  # report!
  printf '\nFinished backing up %s to %s\n' $(du -h $THISTARBALL)
  THISBACKUPDIR=$(dirname $THISTARBALL)
  ls -goht $THISBACKUPDIR/crouton-*.tar
  
  # give 'em a few seconds to see the report
  for i in {0..9};do sleep 1;printf '.';done
}

funcUpdate() {
  # crouton expects the -p path to contain a "chroots" dir
  # and searches it for a matching CRNAME
  bash $THISWORKINGDIR/crouton -u -p ${CRCHROOTDIR%/chroots} -n ${CRNAME:?} 2>/dev/null || \
  funcUsage "
    Crucial was unable to update the chroot. You can run the command yourself to troubleshoot:
    $ sudo bash $THISWORKINGDIR/crouton -u -p ${CRCHROOTDIR%/chroots} -n ${CRNAME:?}"
}

#
##
#

while getopts ":abhi:r:u" THISOPT;do
  case $THISOPT in
    a)
      KEEPAWAKE=true
      ;;
    b)
      BACKUPFIRST=true
      ;;
    h)
      funcUsage
      ;;
    i)
      INSTALLFIRST=$OPTARG
      ;;
    r)
      THISRCFILE=$OPTARG
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

# derive the Crucial installation dir
THISWORKINGDIR="$(dirname $0)"

# require a runcom file that exists and is not empty and is not this file and
# is named ending *rc; if not defined then look for the sample runcom
[[ -s "${THISRCFILE:=$THISWORKINGDIR/crucial.rc}" && \
  "$(readlink -f $THISRCFILE)" != "$(readlink -f $0)" && \
  "$THISRCFILE" =~ rc$ ]] || { 
    funcUsage "$THISRCFILE is not a valid runcom file"; 
}
set -o xtrace
source $THISRCFILE
set +o xtrace

#
##
#

# assign default values if not defined in rc file
: ${CRCHROOTDIR:=/usr/local/chroots}
: ${CRNAME:=precise}

# install?
[[ -z "$INSTALLFIRST" ]] || { funcInstall $INSTALLFIRST; }

# test for Crouton
if ! [[ -s $THISWORKINGDIR/crouton && -d $CRCHROOTDIR/${CRNAME:?} ]];then
  funcUsage \
    "Failed to find Crouton, please run 'sudo bash ./crucial.sh -i [RELEASE]' to bootstrap"
fi

# backup?
[[ -z "$BACKUPFIRST" ]] || { funcBackup; }

# update?
[[ -z "$UPDATEFIRST" ]] || { funcUpdate; }

# launch
STARTUPOPTS="-c $CRCHROOTDIR -n ${CRNAME:?} $CRSTARTCMD"
if [[ -n "$KEEPAWAKE" ]];then
  bash $THISWORKINGDIR/keepawake.sh $STARTUPOPTS
else
  bash /usr/local/bin/enter-chroot $STARTUPOPTS 2>/dev/null || \
    funcUsage "
      Crucial was unable to start up the chroot. You can run the command yourself to troubleshoot:
      $ sudo bash /usr/local/bin/enter-chroot $STARTUPOPTS"
fi

