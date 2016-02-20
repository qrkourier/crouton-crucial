#!/bin/sh -e
#
# ripped from the crouton project wiki
# (https://github.com/dnschneid/crouton/wiki/Power-manager-overrides)
#

ROOTUID="0"

if [ "$(id -u)" -ne "$ROOTUID" ] ; then
  echo "This script must be executed with root privileges."
  exit 1
else
  echo 1 >/var/lib/power_manager/disable_idle_suspend
  echo 0 >/var/lib/power_manager/use_lid
  ( (status powerd | fgrep -q "start/running" ) && restart powerd ) || \
  start powerd
  echo "Disabled idle/lid suspend"

  sh $CRPATH/bin/enter-chroot $@

  rm -f /var/lib/power_manager/disable_idle_suspend
  rm -f /var/lib/power_manager/use_lid
  ( (status powerd | fgrep -q "start/running" ) && restart powerd ) || \
  start powerd
  echo "Enabled idle/lid suspend"
fi

