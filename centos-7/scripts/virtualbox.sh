VBOX_VERSION=$(cat /home/cloudpack/.vbox_version)

# required for VirtualBox 4.3.26
yum install -y bzip2

cd /tmp
mount -o loop /home/cloudpack/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm -rf /home/cloudpack/VBoxGuestAdditions_*.iso
rm /var/log/vboxadd-install.log
yum -y clean all
rm -rf /tmp/rubygems-*
rm /var/log/vboxadd-install.log
