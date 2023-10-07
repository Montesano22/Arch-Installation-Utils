#!/bin/bash

echo "############################"
echo "#                          #"
echo "#   SYSTEMD-BOOT RECOVER   #"
echo "#                          #"
echo "############################"

echo "Vuoi avviare lo script? [Y/n]"
read choice

if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
    echo "Uscita dallo script."
    exit 1
fi

# Verifica se cowsay è installato e installalo se necessario
if ! command -v cowsay &> /dev/null; then
    echo "Cowsay non installato. Procedere con l'installazione? [Y/n]"
    read install_cowsay
    if [ "$install_cowsay" == "Y" ] || [ "$install_cowsay" == "y" ]; then
        sudo pacman -S cowsay
    else
        echo "Cowsay è necessario per mostrare il messaggio. Installalo manualmente e riavvia lo script."
        exit 1
    fi
fi

echo "Systemd-boot Recover"

cowsay -e ^^ -f head-in-box "Attenzione! L'utilizzo di questo script potrebbe portare a perdite di dati! Assicurarsi di aver eseguito dei backup!"

read -p "Vuoi continuare? (Y/n): " input

if [[ "$input" == "y" || "$input" == "Y" || -z "$input" ]]; then
    lsblk
    read -p "Indicare la partizione di boot (e.g., /dev/sdX): " partition_device
    echo "Hai inserito $partition_device"
    read -p "Vuoi continuare? (Y/n): " input

    if [[ "$input" == "y" || "$input" == "Y" || -z "$input" ]]; then
        # Verifica se la partizione esiste
        if [ ! -e "$partition_device" ]; then
            echo "Partizione $partition_device non trovata!"
            exit 1
        fi

        # Conferma con l'utente prima della formattazione
        read -p "Sei sicuro di voler formattare $partition_device (y/N): " confirm
        if [ "$confirm" != "y" ]; then
            echo "Operazione annullata."
            exit 0
        fi

        # Formatta la partizione come FAT32
        sudo mkfs.fat -F32 "$partition_device"
        echo "Partizione $partition_device formattata con successo..."

        # Monta le partizioni
        mount_point="/mnt"
        boot_mount_point="$mount_point/boot"
        sudo mount "$partition_device" "$boot_mount_point"
        echo "Partizione di boot montata su $boot_mount_point..."

        echo "Entrando in chroot..."
        sleep 1

        # Installa il kernel e Systemd-Boot
        sudo arch-chroot "$mount_point" <<EOF
            pacman -S --noconfirm linux linux-headers
            bootctl install
EOF

        echo "Configurazione di Systemd-Boot..."
        sleep 1

        echo "title Arch Linux (linux)" | sudo tee "$boot_mount_point/loader/entries/arch.conf"
        echo "linux /vmlinuz-linux" | sudo tee -a "$boot_mount_point/loader/entries/arch.conf"

        # Chiedi all'utente di scegliere AMD (1) o Intel (2)
        while true; do
            read -p "Scegli l'opzione per microcodice (1 per AMD, 2 per Intel): " microcode_option
            if [ "$microcode_option" == "1" ]; then
                sudo pacman -S --noconfirm amd-ucode
                echo "initrd  /amd-ucode.img" | sudo tee -a "$boot_mount_point/loader/entries/arch.conf"
                break
            elif [ "$microcode_option" == "2" ]; then
                sudo pacman -S --noconfirm intel-ucode
                echo "initrd  /intel-ucode.img" | sudo tee -a "$boot_mount_point/loader/entries/arch.conf"
                break
            else
                echo "Opzione non valida. Riprova."
            fi
        done

        partuuid=$(blkid -s PARTUUID -o value "$partition_device")
        echo "options root=PARTUUID=$partuuid rw" | sudo tee -a "$boot_mount_point/loader/entries/arch.conf"

        echo "Bootloader installato con successo!"
        sleep 1

        sudo umount -R "$mount_point"
        echo "Sicuro di poter eseguire il reboot in sicurezza."
    else
        echo "Interazione annullata."
    fi
else
    echo "Interazione annullata."
fi
