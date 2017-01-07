# setup.sh
# aoneill - 07/25/16

# DIST_DIR = ...
# PACKAGES = ...

TABLE=gpt
BOOT_SIZE=500
SWAP_DIV=4
CHROOT="/mnt"

DISK_PART_EXISTING=3

function tell() { echo $@; $@; }

function round_up() {
  [[ "$2" == "0" ]] && echo "$1"

  rem=$(echo "$1 % $2" | bc)
  [[ "$rem" == "0" ]] && echo "$1"

  echo "$1 + $2 - $rem" | bc
}

function confirm_parted() {
  echo "Using $1..."
  parted $1 print
  echo -n "Continue (y/n)? "
  read cont
  if [[ "$cont" != "y" ]]; then
    echo "Aborting..."
    return 1
  fi

  return 0
}

function get_part() {
  parted $1 print \
    | grep "^ \+[0-9]" \
    | tail -n 1 \
    | sed -e "s|^ \+\([0-9]\+\).*$|\1|"
}

function mkpart() {
  # Get the device
  dev=$1
  shift 1

  # Identify the filesystem
  cmd="mkfs.$2"
  case $2 in
    linux-swap) cmd="mkswap" ;;
    fat16)      cmd="mkfs.fat -F 16" ;;
    fat32)      cmd="mkfs.fat -F 32" ;;
    hfs+)       cmd="mkfs.hfsplus" ;;
  esac

  # Make the filesystem
  tell parted -a optimal $dev mkpart $@ || return 1

  # Format it
  num=$(get_part $dev)
  tell $cmd ${dev}${num} || return 1

  # Name it (optional)
  [[ -n $1 ]] && tell parted $dev name $num $1
}

function init() {
  opt=$(dialog --menu "Partition Scheme:" --stdout 12 40 4 \
          0 'Linux Only' \
          1 'Linux and Windows' \
          2 'Linux, Windows and OSX' \
          $DISK_PART_EXISTING 'Existing')

  # Leave if cancelled
  clear
  [[ -z $opt ]] && return 1

  # Capture disks on the system
  disks=$(mktemp)
  fdisk -l \
    | grep "Disk /dev" \
    | sed -e "/\/dev\/loop[0-9]\+/d" > $disks

  if [[ "$(cat $disks | wc -l)" == "1" ]]; then
    dev=$(cat $disks | sed -e "s|.*\(/dev/[a-z]\{3\}\).*|\1|")
  else
    # Display disks
    cat $disks

    # Get the disk to partition
    while true; do
      echo -n "Which disk to partition (or \`skip'): "
      read dev

      if [[ $dev =~ ^/dev/sd[a-z]$ || "$dev" == "skip" ]]; then
        break
      fi
    done
  fi

  # Make sure the user wants to do this
  confirm_parted $dev || return 1

  if [[ "$opt" != "$DISK_PART_EXISTING" ]]; then
    # Create table
    tell parted $dev mktable $TABLE

    # Get disk attributes
    sdx=$(basename $dev)
    block="/sys/block/$sdx"
    optimal=$(cat "$block/queue/optimal_io_size")
    blk_size=$(cat "$block/queue/physical_block_size")
    offset=$(cat "$block/queue/alignment_offset")

    # Get the proper start of the block
    end="$(echo "($optimal + $offset) / $blk_size" | bc)"

    # Create boot area
    mkpart $dev boot fat32 "${end}s" "${BOOT_SIZE}M"
    num=$(get_part $dev)
    tell parted $dev set $num boot on

    # Calculate swap space
    ram="$(cat /proc/meminfo | grep MemTotal | awk -e '{ print $2 }')"
    ram=$(echo "$ram / ($SWAP_DIV * 1000)" | bc)
    swap=$(round_up $ram 500)

    # Create swap space
    end=$((swap + BOOT_SIZE))
    mkpart $dev swap linux-swap "${BOOT_SIZE}M" "${end}M"

    # Get the size for the remaining partitions
    hd=$(fdisk -l /dev/sda \
           | head -n 1 \
           | sed -e "s/.* \([0-9]\+\) bytes.*/\1/")
    hd=$(echo "($hd / 1000000) - $end" | bc)
    part="$(echo "$hd / ($opt + 1)" | bc)"

    # Implement partition scheme
    # Linux
    echo $opt
    if [[ "$opt" -ge "0" ]]; then
      mkpart $dev Arch ext4 "${end}M" "$((end + part))M"
      end=$((end + part))
    fi

    # Windows
    if [[ "$opt" -ge "1" ]]; then
      other=1000
      wpart="$(echo "$part - 2 * $other" | bc)"

      # Create main Windows partition
      mkpart $dev Win ntfs "${end}M" "$((end + wpart))M"
      end=$((end + wpart))

      # Set flag
      num=$(get_part $dev)
      tell parted $dev set $num msftdata on

      # Create reserved
      mkpart $dev WinRes ntfs "${end}M" "$((end + other))M"
      end=$((end + other))

      # Set flag
      num=$(get_part $dev)
      tell parted $dev set $num msftres on
    fi

    # OSX
    if [[ "$opt" -ge "2" ]]; then
      mkpart $dev OSX hfs+ "${end}M" "$((end + part))M"
      end=$((end + part))
    fi

    # Make sure the user is satisfied
    confirm_parted $dev || return 1

    # Mount the partitions
    # The third partition is Arch in each configuration, and boot is always first
    tell mount ${dev}3 "$CHROOT/" || return 1
    tell mount ${dev}1 "$CHROOT/boot" || return 1
  else
    # Get the boot and data partitions
    fdisk -l | grep $dev

    # Get the boot partition
    while true; do
      echo -n "Boot partition? (default \`${dev}1'): "
      read boot_part

      echo $boot_part | grep -q "${dev}[0-9]\+" && break
      [[ -z "$boot_part" ]] && boot_part="${dev}1" && break
    done

    # Get the data partition
    while true; do
      echo -n "Data partition? (default \`${dev}3'): "
      read data_part

      echo $data_part | grep -q "${dev}[0-9]\+" && break
      [[ -z "$data_part" ]] && data_part="${dev}3" && break
    done

    # Mount the partitions
    tell mount $data_part "$CHROOT/" || return 1
    tell mkdir -p "$CHROOT/boot" || return 1
    tell mount $boot_part "$CHROOT/boot" || return 1
  fi

  # Copy the installation directory
  tell cp -r "$HOME/$DIST_DIR" "$CHROOT/root/" || return 1
  tell cp -r "$HOME/$PACK_CACHE" "$CHROOT/root/" || return 1

  # Initialize the packages
  tell pacstrap "$CHROOT" base base-devel git openssh || return 1

  # Generate the fstab entries
  genfstab "$CHROOT" >> "$CHROOT/etc/fstab" || return 1

  # Configure pacman
  tell cp "$CHROOT/etc/pacman.conf{,old}"
  tell cp /etc/pacman.conf "$CHROOT/etc/pacman.conf"

  # Run the configuration
  arch-chroot "$CHROOT" /bin/bash -c "cd '$CHROOT/root/$DIST_DIR'; ./configure"
  [[ "$?" != 0 ]] && return 1

  # Clean up
  umount "$CHROOT/boot" || return 1
  umount "$CHROOT"
}

init
if [[ "$?" == "0" ]]; then
  reboot
fi
