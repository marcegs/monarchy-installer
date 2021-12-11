# Monarchy Installer

**WARNING** This script it is still an WIP. Use it at your own risk!

**WARNING 2** UEFI ONLY! (for now)

Any and all criticisms are welcome!

## About

Monarchy Installer is a personal project created with the intention of learning bash scripting.

This script is for my personal setup, and as such, it is not intended for those who wish to customize the install process. For instance, if you don't want to use the BTRFS file system, this script won't give you the option to change it, at least for now.

## Features

- Minimal arch install with BTRFS file system and snapper already configured

wow now that's a lot of features!

### Planned Features

- [x] Optional disk encryption

Note: Swap will not be encrypted, still working on it
- [ ] Options between complete and minimal install
- [ ] Complete install
- [ ] Everything else

## Usage

1. Download and boot from the latest Arch Linux ISO

Note: This script assumes that you already have an [Internet connection](https://wiki.archlinux.org/title/Installation_guide#Connect_to_the_internet). 

2. Install git with the following command `pacman -Sy git --noconfirm`

3. Clone the monarchy-installer repository `git clone https://github.com/marcegs/monarchy-installer`

4. cd into the repository `cd monarchy-installer`

5. Run the installer and provide the necessary information `bash install.sh`


Once the sctipt is done, that's it! You can now reboot! :)
