#!/usr/bin/env bash




# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    sleep 1
    echo "This script must be run as root. Aborting Install ..."
    exit 1
fi

# Exit on any error
set -e
# Exit on any undefined variable
set -u
# Exit on any error in a pipeline
set -o pipefail
#Intro
sleep 2
echo ""
echo ""
echo "Arch linux install script"
sleep 1
echo "File format set to xfs change by your needs."
sleep 1
echo "Have to post setup secureboot by yourself using sbctl."
sleep 1
echo ""
echo ""

# Prompt the user for customizations
echo "Configure settings ..."
sleep 2
read -rp "Enter the desired hostname: " HOSTNAME
sleep 1
read -rp "Enter the desired username: " USERNAME
sleep 1
read -rs -p "Enter the root password: " ROOT_PASSWORD
sleep 1
echo ""
read -rs -p "Enter the user password: " USER_PASSWORD
sleep 1
echo ""

#Prompt for Timezone
timedatectl list-timezones | less
read -rp "Enter the desired timezone (e.g., America/New_York): " TIMEZONE
echo "Updating Timezone ..."
sleep 2
# Prompt for partition information
lsblk

read -rp "Enter the EFI partition (e.g., /dev/sda1): " EFI_PARTITION
sleep 1
read -rp "Enter the root partition (e.g., /dev/sda2): " ROOT_PARTITION
sleep 1
read -rp "Enter the swap partition (e.g., /dev/sda3): " SWAP_PARTITION
sleep 1
echo "Updating Partitioning ..."
sleep 2

# Update system clock
echo "Updating Time ..."
timedatectl set-ntp true
sleep 2

# Partitioning
echo "Formatting Drives..."
sleep 2

mkfs.fat -F32 "$EFI_PARTITION"
sleep 1

mkfs.xfs -f "$ROOT_PARTITION"
sleep 1

mkswap "$SWAP_PARTITION"
sleep 1

#Mounting Drives
echo "Mounting Drives ..."
sleep 2
mount "$ROOT_PARTITION" /mnt

mkdir -p /mnt/boot/efi
mount "$EFI_PARTITION" /mnt/boot/efi

swapon "$SWAP_PARTITION"
sleep 1

# Install essential packages
echo "Installing Linux"
sleep 2
pacstrap /mnt base linux linux-firmware sof-firmware base-devel
sleep 2


echo "Checking CPU vendor and model ..."
sleep 2
CPU_VENDOR=$(lscpu | grep 'Vendor ID' | awk '{print $3}')
CPU_MODEL=$(lscpu | grep 'Model name' | awk '{print $3,$4,$5,$6,$7,$8,$9}')
echo "Your CPU vendor is %s and your CPU model is %s" "$CPU_VENDOR" "$CPU_MODEL"
sleep 2

# Install ucode package
echo "Installing ucode package ..."
sleep 2
case "$CPU_VENDOR" in
  GenuineIntel) pacstrap /mnt intel-ucode;;
  AuthenticAMD) pacstrap /mnt amd-ucode;;
  *) echo "Unknown CPU vendor. Skipping ucode installation.";;
esac
sleep 1

# Generate an fstab file
genfstab -U /mnt > /mnt/etc/fstab
sleep 1

# Change root into the new system
echo "Changing root"
sleep 2
arch-chroot /mnt /bin/bash <<EOF
echo "Setting up system ..."
sleep 2

# Set the system clock
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc
sleep 1

# Generate locales
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
sleep 1

# Set the hostname
echo "%s" "$HOSTNAME" >> /etc/hostname
sleep 1

# Configure hosts file
echo "127.0.0.1  localhost" >> /etc/hosts
echo "::1        localhost" >> /etc/hosts
echo "127.0.0.1  %s.localdomain  %s" "$HOSTNAME" "$HOSTNAME" >> /etc/hosts

# Set root password
echo "root:%s"$ROOT_PASSWORD" | chpasswd
sleep 1

# Install and configure bootloader (GRUB in this example)
echo "Setting grub ..."
sleep 2
pacman -Sy --noconfirm grub efibootmgr dosfstools os-prober mtools
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch --modules="tpm" --disable-shim-lock
grub-mkconfig -o /boot/grub/grub.cfg
sleep 1

# Create a new user
echo "Setting up user for first boot ..."
sleep 2
useradd -m -G wheel "$USERNAME"

# Set a password for the new user
echo "%s:%s" "$USERNAME" "$USER_PASSWORD" | chpasswd

# Enable sudo for the new user
echo "%%wheel ALL=(ALL) ALL" > /etc/sudoers.d/"$USERNAME"

# Enable NetworkManager
echo "Enabling NetworkManager"
sleep 2
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# Install additional packages
pacman -S vim git wget curl

EOF
sleep 1
echo "Install has been successful"
sleep 3

# Unmount all partitions and reboot
umount -a

# Ask the user for reboot option
read -rp "Do you want to reboot now? (y/n): " REBOOT_OPTION
case "$REBOOT_OPTION" in
  y|Y) echo "Rebooting ..."; reboot;;
  n|N) echo "Exiting ..."; exit 0;;
  *) echo "Invalid option. Exiting ..."; exit 1;;
esac

