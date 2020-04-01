#Note: btrfs-send needs read-only snapshots!

# Create a read-only snapshot
btrfs subvolume snapshot -r /home /mnt/backup

# Initially transfer the whole subvolume
btrfs send /mnt/backup | ssh root@backup.home btrfs receive /mnt/homeFromPC
