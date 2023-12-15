#!/bin/bash

# Prompt the user for customizations
echo "Simple Arch install Make partitioon and fromat partitioon first befoor using "
sleep 2
echo "Configure setings ..."
sleep 1
read -p "Enter the desired hostname: " HOSTNAME
sleep 1
read -p "Enter the desired username: " USERNAME
sleep 1
read -s -p "Enter the root password: " ROOT_PASSWORD
sleep 1
echo
read -s -p "Enter the user password: " USER_PASSWORD
sleep 1
echo "Select timezone"
sleep 1
echo "Available Timezones:"
timedatectl list-timezones | less
read -p "Enter the desired timezone (e.g., America/New_York): " TIMEZONE
echo "Updating Timezone ..."
sleep 2
# Prompt for partition information
lsblk

read -p "Enter the EFI partition (e.g., /dev/sda1): " EFI_PARTITION
sleep 1
read -p "Enter the root partition (e.g., /dev/sda2): " ROOT_PARTITION
sleep 1
read -p "Enter the swap partition (e.g., /dev/sda3): " SWAP_PARTITION
sleep 1
echo "Updating Partitioning ..."

# Update system clock
echo "Udating Time ..."
timedatectl set-ntp true

# Partitioning
#echo "Formating Drives..."
#sleep 1
#mkfs.fat -F32 $EFI_PARTITION
#sleep 1
#mkfs.xfs -f $ROOT_PARTITION
#sleep 1
#mkswap $SWAP_PARTITION
#sleep 1


echo "mouning Drives ..."
mount $ROOT_PARTITION /mnt

mkdir -p /mnt/boot/efi
mount $EFI_PARTITION /mnt/boot/efi

swapon $SWAP_PARTITION
sleep 1

# Install essential packages
echo "Installing Linux"
sleep 1
pacstrap /mnt base linux linux-firmware sof-firmware intel-ucode amd-ucode
sleep 1
# Generate an fstab file
genfstab -U /mnt > /mnt/etc/fstab
sleep 1

# Change root into the new system
echo "changing root"
sleep 1
arch-chroot /mnt /bin/bash <<EOF
echo "setting up system ..."
sleep 1

# Set the system clock
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sleep 1

# Generate locales
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
sleep 1

# Set the hostname
echo "$HOSTNAME" >> /etc/hostname
sleep 1

# Configure hosts file
echo "127.0.0.1  localhost" >> /etc/hosts
echo "::1        localhost" >> /etc/hosts
echo "127.0.0.1  $HOSTNAME.localdomain  $HOSTNAME" >> /etc/hosts

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd
sleep 1

# Install and configure bootloader (GRUB in this example)
echo "Setting grub ..."
sleep 1
pacman -Sy --noconfirm grub efibootmgr dosfstools os-prober mtools
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch --modules="tpm" --disable-shim-lock
grub-mkconfig -o /boot/grub/grub.cfg
sleep 1

# Create a new user
echo "Setting up user for first boot ..."
sleep 1
useradd -m -G wheel $USERNAME

# Set a password for the new user
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Enable sudo for the new user
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/$USERNAME

# Enable NetworkManager
echo "enabaling NetworkManager"
pacman -Sy --noconfirm networkmanager
systemctl enable NetworkManager

# Install additional packages
pacman -Sy --noconfirm vim git wget curl

EOF
sleep 1
echo "Install has been complete reboot now"
