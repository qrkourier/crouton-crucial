# crouton-crucial

A little extra help for using [Crouton](https://github.com/dnschneid/crouton), the Chromium OS universal chroot environment

## Advantages
* save chroot config in a file the perform common operations with less to remember
* easily create and retain a defined number of backups for each Crouton instance
* disable power management in the OS before starting up to address the problem of the OS having USB persist disabled

## Files
* crucial.rc: annotated runcom file for Crouton environments; required by crucial.sh
* crucial.sh: a helper script that launches a Crouton instance, optionally first backing up or updating or both
* keepawake.sh: a wrapper script that disables power management features before invoking enter-chroot

## Bootstrapping
* download and unpack [the zip file](https://github.com/qrkourier/crouton-crucial/archive/master.zip)
* edit crucial.rc to configure a new or existing chroot
* press ctrl-alt-t to open a crosh terminal
* invoke bash
```
crosh> shell
```
* run Crucial
```
$ sudo bash ~/Downloads/crouton-crucial-master/crucial.sh -s
```

