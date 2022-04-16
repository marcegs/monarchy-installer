# Monarchy Installer

**WARNING** This script it is still an WIP. Use it at your own risk!

**WARNING 2** UEFI ONLY! (for now)

Any and all criticisms are welcome!

## About

Monarchy installer is an Arch Linux installer for those who just wanna get it over with.

## Features

- Minimal arch install with BTRFS file system and snapper
- Optional disk encryption
- Options between complete and minimal install (useless option atm c:)
- Zram instead of swap partition!

### Planned Features

- [ ] Prevent user from leaving a field blank or an invalid input
- [ ] Choose between ext4 and btrfs file systems
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
