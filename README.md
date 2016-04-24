# arch-setup
A quick script to install and configure my Arch installation.

Background
----------

I like to toy with new operating systems, and often I break something. 
This repository should contain an executable file, as well as resources,
to setup my Arch Linux installation the way I like it.

This will make it easier for me to restore my computer to a working state,
and give other people an idea for how I like to do work.

Installation
============

Pre-Boot
--------

Follow the [pre-install instructions](https://wiki.archlinux.org/index.php/Installation_guide#Pre-installation)
on the Arch Wiki. The following instructions assume you have a working
internet connection as well as a disk partitioned to your heart's content.

### Install base packages

Mount your Linux partition(s) on and within `/mnt` (including `/mnt/boot`).
Next, preform the following command to prepare `/mnt`:

```bash
pacstrap /mnt base base-devel git openssh
```

Finally, `chroot` into your fresh install. `/bin/bash` is supplied for a richer
command-line interface:

```bash
arch-chroot /mnt /bin/bash
```

### Generate filesystem information

Ensuring *all* relevant partitions are mounted within the filesystem, 
generate filesystem information with the following command:

```bash
genfstab >> /etc/fstab
```

### Run configuration script

Clone this repository into your system with the following command:

```bash
git clone https://github.com:/alexoneill/arch-setup.git
```

Then, run the configuration script and follow the prompts:

```bash
cd arch-setup
./configure
```

Finally, `reboot`, and remove the installation medium. If everything worked,
your system should boot normally and you may continue onto the next section.

Natively Booted
---------------

After rebooting, login with the `root` account. Next, return to the script
directory and run configure again:

```bash
cd arch-setup
./configure
```

Reboot, again. Once the system starts up, you will be presented with a
graphical login and the system will be fully configured!
