# crouton-crucial

A little extra help for using [Crouton](https://github.com/dnschneid/crouton), the Chromium OS universal chroot environment, or, a way to run a few different flavors of Linux in shared kernel space with Chromium OS or Chrome OS.

## Advantages
* one runcom file per Crouton instance makes it easy to keep track of their respective attributes
* easily create and retain a defined number of backups for each Crouton instance
* disable power management in the OS before starting up (addresses the problem of the OS having USB persist disabled)

## Prerequisites
* at least one working Crouton instance installed on Chromium OS or Chrome OS,
* the ability to open a crosh shell as chronos and run-as root (to test: press ctrl-alt-t, execute "shell", execute "sudo -l")

## Files
* crucial.rc: annotated runcom file for Crouton environments; required by crucial.sh
* crucial.sh: a helper script that launches a Crouton instance, optionally first backing up or updating or both
* keepawake.sh: a wrapper script that disables power management features before invoking enter-chroot

## Installation
* download [the zip file](https://github.com/qrkourier/crouton-crucial/archive/master.zip)
* unpack the zip file
* cd to the new directory, e.g. crouton-crucial-master
* execute
```
$ bash ./crucial.sh -h
```

