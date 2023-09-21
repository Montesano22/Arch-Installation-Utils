#! /usr/bin/bash

if ! command -v cowsay &> /dev/null; then
    echo "Cowsay non installato. Procedere con l'installazione?"
    pacman -S cowsay
fi
echo "Systemd-boot Recover"

echo -e "Attenzione! L'utilizzo di questo script potrebbe portare a perdite di dati! Assicurarsi di aver eseguito dei backup!" | cowsay

read -p "Vuoi continuare? (Y/n): " input

if [[ "$input" == "y" || "$input" == "Y" || -z "$input" ]]; then

    lsblk

    read -p "Indicare la partizione di boot (e.g., /dev/sdX): " partition_device

    echo "Hai inserito $partition_device"

    read -p "Vuoi continuare? (Y/n): " input

    if [[ "$input" == "y" || "$input" == "Y" || -z "$input" ]]; then
        # Check if the partition device exists
        if [ ! -e "$partition_device" ]; then
            echo "Partizione $partition_device non trovata!"
            exit 1
        fi

        # Confirm with the user before formatting
        read -p "Sei sicuro di voler formattare $partition_device (y/N): " confirm
        if [ "$confirm" != "y" ]; then
            echo "Aborted."
            exit 0
        fi
    fi
    # Format the partition as FAT32
    sudo mkfs.fat -F32 "$partition_device"
    echo "Partizione $partition_device formattata..."
    # Check if the user input is /dev/sda1
    if [ "$partition_device" = "/dev/sda1" ]; then

        echo "Rilevato ssd!"

        sleep 1

        mount /dev/sda2 /mnt

        mkdir /mnt/boot

        mount /dev/sda1 /mnt/boot

    # Check if the user input is /dev/nvme0n1p2
    elif [ "$partition_device" = "/dev/nvme0n1p1" ]; then

        echo "Rilevato HDD!"

        sleep 1

        mount /dev/nvme0n1p2 /mnt

        mkdir /mnt/boot

        mount /dev/nvme0n1p1 /mnt/boot

    else
        echo "Unsupported partition device."
        exit 1
    fi

    echo "Entro in Chroot..."

    sleep 1

    arch-chroot /mnt<<EOF

    pacman -S --noconfirm linux linux-headers

    echo "Installo Systemd-Boot..."

    sleep 1

    bootctl install

    echo "Configuro Systemd-Boot..."

    sleep 1

    cd /boot/loader/entries/

    echo "title Arch Linux (linux)" > arch.conf

    echo "linux /vmlinuz-linux" >> arch.conf

    if pacman -Q amd-ucode &>/dev/null; then
        echo "initrd  /amd-ucode.img" >> arch.conf
    fi

    # Check if intel-ucode is installed
    if pacman -Q intel-ucode &>/dev/null; then
        echo "initrd  /intel-ucode.img" >> arch.conf
    fi

    echo "initrd  /initramfs-linux.img" >> arch.conf

    partuuid=$(blkid -s PARTUUID -o value /dev/sda2)

    echo "options root=PARTUUID=$partuuid rw" >> arch.conf

    echo "Bootloader installato con successo!"
EOF

    umount -R /mnt

    echo "E' possibile eseguire il reboot in sicurezza."

else
    echo "Interazione annullata."
fi
