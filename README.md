# crouton-crucial

A little extra help for using [Crouton](https://github.com/dnschneid/crouton), the Chromium OS universal chroot environment, or, a way to run a few different flavors of Linux in shared kernel space with Chromium OS or Chrome OS.

## Advantages
* one runcom file per Crouton instance makes it easy to keep track of their respective attributes, 
* easily create and retain a defined number of backups for each Crouton instance,
* disable power management in the OS before starting up (addresses the problem of the OS having USB persist disabled)

## Prerequisites
* at least one working Crouton instance installed on Chromium OS or Chrome OS,
* the ability to open a crosh shell as chronos and run-as root (to test: press ctrl-alt-t, execute "shell", execute "sudo -l")

## Files
* crucial.rc: a commented runcom file for Crouton environments; required by crucial.sh
* crucial.sh: a helper script that launches a Crouton instance, optionally first backing up or updating or both
* keepawake.sh: a wrapper script that disables power management features before invoking enter-chroot

## Usage
```
  $ sudo bash ./crucial.sh [OPTIONS]

    -a          disable Chromium OS power management before startup
    -b          perform a backup and give a brief report before startup
    -c FILE     override default runcom location ./crucial.rc
    -i RELEASE  install the specified Linux release or list 
    -u          perform a Crouton chroot update before startup

Hints:
  # switch to the installation directory before running Crucial, e.g.
    $ cd /media/removable/128SD/crouton-crucial

  # copy the sample runcom file and configure the copy for your instance;
  # configuration options are described in-line
    $ cp crucial.rc precise.rc

  # Crucial can manage an existing Crouton instance; just ensure the runcom
  # file reflects its attributes

Examples:
  # Crucial can install a Crouton instance described by a runcom file
    $ sudo bash ./crucial.sh -c ./precise.rc -i precise

  # disable OS power management (awake) and start up the only installed
  # instance; this implies '-c ./crucial.rc' which is a sample file with sane
  # defaults
    $ sudo bash ./crucial.sh -a

  # backup, update, then start up an instance described by a runcom file
    $ sudo bash ./crucial.sh -buc ./precise.rc
    ```
