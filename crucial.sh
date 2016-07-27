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
funcExit() {
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
    -c          override the start command
    -i          install the chroot; implies '-s'
    -r FILE     override ./crucial.rc
    -s          bootstrap Crouton installer
    -u          update the chroot

Examples:
  Disable Chrome power management and enter the first chroot and run bash in the crosh shell tab
  $ sudo bash ./crucial.sh -ac bash

  Enter the first chroot and run a GUI terminal in a Chrome tab 
  $ sudo bash ./crucial.sh -c "xiwi -T xfce4-terminal"

  Enter the first chroot and run a GUI desktop in a Chrome tab 
  $ sudo bash ./crucial.sh -c "xiwi -T startxfce4"
"
  exit 1
}

funcBootstrap() {
  # download the crouton installer script to the Crucial installation dir
  if ! { umask 022 && \
    curl -# -L --connect-timeout 60 --max-time 300 --retry 2 "$CRINSTALLER" -o \
      "$THISWORKINGDIR/crouton"; }; then
    funcExit "Failed to bootstrap Crouton."
  fi
  # refresh the Crouton executables that are required by the existing chroots
  if ! { /bin/sh $THISWORKINGDIR/crouton -p $CRPATH -b; };then
    funcExit "Failed to refresh Crouton executables in $CRPATH/bin"
  fi
  
}

funcInstall() {
  echo "Downloading and installing the chroot. This will take a while."
  /bin/sh $THISWORKINGDIR/crouton -p $CRPATH -t ${CRTARGETS:?} -r ${CRRELEASE:?} -n ${CRNAME:?} 2>/dev/null || \
    funcExit \
      "Crucial was unable to install the chroot. You can run the command yourself to troubleshoot:
      $ sudo /bin/sh $THISWORKINGDIR/crouton -p $CRPATH -t ${CRTARGETS:?} -r ${CRRELEASE:?} -n ${CRNAME:?}"
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
  /bin/sh $CRPATH/bin/edit-chroot -c $CRPATH/chroots -bf $THISTARBALL ${CRNAME:?} 2>/dev/null </dev/null || \
    funcExit "
      Crucial was unable to back up the chroot. You can run the command yourself to troubleshoot:
      $ sudo /bin/sh $CRPATH/bin/edit-chroot -c $CRPATH/chroots -bf $THISTARBALL ${CRNAME:?}"
 
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
  /bin/sh $THISWORKINGDIR/crouton -u -p $CRPATH -n ${CRNAME:?} 2>/dev/null || \
  funcExit "
    Crucial was unable to update the chroot. You can run the command yourself to troubleshoot:
    $ sudo /bin/sh $THISWORKINGDIR/crouton -u -p $CRPATH -n ${CRNAME:?}"
}

#
##
#

while getopts ":abc:hir:su" THISOPT;do
  case $THISOPT in
    a)
      KEEPAWAKE=true
      ;;
    b)
      BACKUPFIRST=true
      ;;
    c)
      CRRUNCMD="$OPTARG"
      ;;
    h)
      funcExit
      ;;
    i)
      BOOTSTRAPFIRST=true
      INSTALLFIRST=true
      ;;
    r)
      THISRCFILE=$OPTARG
      ;;
    s)
      BOOTSTRAPFIRST=true
      ;;
    u)
      UPDATEFIRST=true
      ;;
    \?|:)
      funcExit "Unrecognized option or argument expected in '-$OPTARG'"
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
    funcExit "$THISRCFILE is not a valid runcom file"; 
}
set -o xtrace
source $THISRCFILE
set +o xtrace

#
##
#

# assign default values if not defined in rc file
: ${CRPATH:=/usr/local}
: ${CRNAME:=$CRRELEASE}

# optionally override the rc file
: ${CRRUNCMD:=$CRSTARTCMD}

# bootstrap?
[[ -z "$BOOTSTRAPFIRST" ]] || { 
  funcBootstrap
}

# install?
[[ -z "$INSTALLFIRST" ]] || { 
  funcInstall
}

# test for the chroot
if ! [[ -d $CRPATH/chroots/${CRNAME:?} ]];then
  funcExit \
    "Failed to find the chroot, you can 'sudo bash crucial.sh -i' to install one"
fi

# test for Crouton
if ! [[ -s $THISWORKINGDIR/crouton ]];then
  funcExit \
    "Failed to find Crouton, you can 'sudo bash crucial.sh -s' to install it in $THISWORKINGDIR"
fi

# backup?
[[ -z "$BACKUPFIRST" ]] || { funcBackup; }

# update?
[[ -z "$UPDATEFIRST" ]] || { funcUpdate; }

# enter
STARTUPOPTS="-c $CRPATH/chroots -n ${CRNAME:?} $CRRUNCMD"
if [[ -n "$KEEPAWAKE" ]];then
  export CRPATH
  exec /bin/sh $THISWORKINGDIR/keepawake.sh $STARTUPOPTS
else
  exec /bin/sh $CRPATH/bin/enter-chroot $STARTUPOPTS
fi

