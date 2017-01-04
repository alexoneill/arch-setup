# setup.sh
# aoneill - 07/25/16

TABLE=gpt
BOOT_SIZE=500
SWAP_DIV=4

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
  fs=$2
  case $fs in
    linux-swap) fs=mkswap ;;
    fat16)      fs="fat -F 16" ;;
    fat32)      fs="fat -F 32" ;;
    hfs+)       fs=hfsplus ;;
  esac

  # Make the filesystem
  tell parted -a optimal $dev mkpart $@ || return 1

  # Format it
  num=$(get_part $dev)
  tell mkfs.${fs} ${dev}${num} || return 1

  # Name it (optional)
  [[ -n $1 ]] && tell parted ${dev} ${num} name $1
}

function init() {
  opt=$(dialog --menu "Partition Scheme:" --stdout 10 40 3 \
          0 'Linux Only' \
          1 'Linux and Windows' \
          2 'Linux, Windows and OSX')

  # Leave if cancelled
  clear
  [[ -z $opt ]] && return 1

  if [[ "$(fdisk -l | grep "Disk /dev" | wc -l)" == "1" ]]; then
    dev=$(fdisk -l | grep "Disk /dev" | sed -e "s|.*\(/dev/[a-z]\{3\}\).*|\1|")
  else
    # Display disks
    fdisk -l | grep "Disk /dev"

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

  # Create table
  tell parted $dev mktable $TABLE

  # Create boot area
  mkpart $dev boot fat32 0 "${BOOT_SIZE}M"
  num=$(get_part $dev)
  tell parted $dev $num set boot on

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
    tell parted $dev $num set msftdata on

    # Create reserved
    mkpart $dev WinRes ntfs "${end}M" "$((end + other))M"
    end=$((end + other))

    # Set flag
    num=$(get_part $dev)
    tell parted $dev $num set msftres on
  fi

  # OSX
  if [[ "$opt" -ge "2" ]]; then
    mkpart $dev OSX hfs+ "${end}M" "$((end + part))M"
    end=$((end + part))
  fi

  # Make sure the user is satisfied
  confirm_parted $dev || return 1

  cd $HOME/$DIST_DIR/
  ./configure
}

init
if [[ "$?" == "0" ]]; then
  reboot
fi
