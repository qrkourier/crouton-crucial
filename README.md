# crouton-crucial

A little extra help for using [Crouton](https://github.com/dnschneid/crouton), the Chromium OS universal chroot environment, or, a way to run a few different flavors of Linux in shared kernel space with Chromium OS or Chrome OS.

## Advantages
* one runcom file per Crouton instance makes it easy to keep track of their respective attributes, 
* easily limit the maximum number of backups for each Crouton instance,
* disable power management in the OS before starting up (addresses the problem of the OS re-mounting external storage devices as described in [this issue](https://github.com/dnschneid/crouton/issues/1936))

## Prerequisites
* at least one working Crouton instance installed on Chromium OS or Chrome OS,
* the ability to open a crosh shell as chronos and run-as root (press ctrl-alt-t, execute "shell", execute "sudo -l")

## Files
* crucial.rc: a commented runcom file for Crouton environments; required by crucial.sh;
* crucial.sh: a helper script that launches a Crouton instance, optionally first backing up or updating or both;

## Usage
```
  sudo bash ./crucial.sh [OPTIONS]

    -a        disable Chromium OS power management before startup
    -b        perform a backup and give a brief report before startup
    -c FILE   override default runcom location ./crucial.rc
    -u        perform a Crouton chroot update before startup
```
