#!/bin/bash

echo "#############################"
echo "#                           #"
echo "#    SWAP FILE INSTALLER    #"
echo "#                           #"
echo "#############################"

echo "Vuoi avviare lo script? [Y/n]"
read choice

if [ "$choice" != "Y" ] && [ "$choice" != "y" ]; then
    echo "Uscita dallo script."
    exit 1
fi

echo "Inserire la dimensione del file di swap (da 1 a 8 in gigabyte):"
read size

# Verifica se la dimensione è un numero valido compreso tra 1 e 8
if [[ "$size" =~ ^[1-8]$ ]]; then
    size="${size}G"  # Aggiunge la G per indicare gigabyte
    echo "Creazione del file di swap di $size in corso..."

    # Esegui il comando dd per creare il file di swap
    dd if=/dev/zero of=/swapfile bs=1G count="$size" status=progress

    # Verifica se la creazione è avvenuta con successo
    if [ $? -eq 0 ]; then
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile

        # Aggiungi il file di swap a /etc/fstab
        echo "/swapfile none swap defaults 0 0" | tee -a /etc/fstab
        echo "File di swap creato con successo e attivato."
    else
        echo "Si è verificato un errore durante la creazione del file di swap."
    fi
else
    echo "Dimensione non valida. Inserire un numero da 1 a 8."
    exit 1
fi
