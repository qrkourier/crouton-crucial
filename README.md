# crouton-crucial

A little extra help for using [Crouton](https://github.com/dnschneid/crouton), the Chromium OS universal chroot environment

## Advantages
* save chroot config in a file the perform common operations with less to remember
* easily create and retain a defined number of backups for each Crouton instance
* disable power management in the OS before starting up to address the problem of the OS having USB persist disabled

## Files
* crucial.rc: annotated runcom file for Crouton environments; required by crucial.sh; edit this first
* crucial.sh: starts a Crouton chroot; optionally first installing, backing up, or updating
* keepawake.sh: a wrapper script optionally called by crucial.sh that disables suspend before enter-chroot

## Bootstrapping
* download and unpack [the zip file](https://github.com/qrkourier/crouton-crucial/archive/master.zip)
* edit crucial.rc to configure a new or existing chroot
* press ctrl-alt-t to open a crosh terminal
* invoke bash as root (requires Chromebook Developer Mode)
```
crosh> shell
```
* run Crucial and bootstrap Crouton
```
$ sudo bash ~/Downloads/crouton-crucial-master/crucial.sh -s
```

