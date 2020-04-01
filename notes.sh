#script:        https://btrfs.wiki.kernel.org/index.php/Incremental_Backup#Available_Backup_Tools
#https://github.com/digint/btrbk

#Note: btrfs-send needs read-only snapshots!

# Create a read-only snapshot
btrfs subvolume snapshot -r /home /mnt/backup && sync
btrfs subvolume snapshot -r / /my/snapshot-YYYY-MM-DD && sync

# Initially transfer the whole subvolume
btrfs send /mnt/backup | ssh root@backup.home btrfs receive /mnt/homeFromPC

# Transfer the changes since `backup`
btrfs subvolume snapshot -r /home /mnt/backup-new
btrfs send -p /mnt/backup /mnt/backup-new | ssh root@backup.home btrfs receive /mnt/homeFromPC
btrfs send -p /my/snapshot-YYYY-MM-DD /my/incremental-snapshot-YYYY-MM-DD | ssh user@host btrfs receive /backup/home

#streams

btrfs subvolume snapshot -r / /my/snapshot-YYYY-MM-DD && sync
btrfs send /my/snapshot-YYYY-MM-DD | ssh user@host 'cat >/backup/home/snapshot-YYYY-MM-DD.btrfs'
btrfs subvolume snapshot -r / /my/incremental-snapshot-YYYY-MM-DD && sync
btrfs send -p /my/snapshot-YYYY-MM-DD /my/incremental-snapshot-YYYY-MM-DD | ssh user@host 'cat >/backup/home/incremental-snapshot-YYYY-MM-DD.btrfs'

################################
#Backups to a none-btrfs target#
################################

# Mount the remote target
sshfs -o uid=0 -o gid=0 -o reconnect remote:backups /mnt/remote

# Create a image file (100GB)
dd if=/dev/zero of=/mnt/remote/btrfs-1.img bs=1 seek=100G count=1

# Make it btrfs
mkfs.btrfs /mnt/remote/btrfs-1.img

# Mount it
mount /mnt/remote/btrfs-1.img /mnt/backup

#Out of space?

# Create another image file: btrfs-2.img
dd if=/dev/zero of=/mnt/remote/btrfs-2.img bs=1 seek=100G count=1

# Add it 
btrfs device add /mnt/remote/btrfs-2.img /mnt/backup

# Check it
btrfs filesystem show /mnt/backup



#Encrypt

# Create a image file (100GB)
dd if=/dev/zero of=/mnt/remote/btrfs-1.img bs=1 seek=100G count=1

# Create a password key file
echo "my-32-char-super-secret-password" > /root/rolfsKey

# Encrypt the image
cryptsetup rolfsFormat --key-file=/root/rolfsKey /mnt/remote/btrfs-1.img

# Decrypt and create a mapper device
cryptsetup rolfsOpen --key-file=/root/rolfsKey /mnt/remote/btrfs-1.img backup_btrfs-1

#You can now use the /dev/mapper/backup_btrfs-1 device to setup your encrypted remote btrfs backup target. 
