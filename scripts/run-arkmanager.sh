#!/usr/bin/env bash

[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

function fix-volume {
    cd /ark

    # we add user settings
    [ ! -f "/ark/arkmanager.cfg" ] && cp /home/steam/samples/arkmanager.cfg /ark/arkmanager.cfg
    ln -s /ark/arkmanager.cfg /home/steam/.arkmanager.cfg

    # we get the instances
    [ ! -d "/ark/instances" ] && mkdir /ark/instances
    [ ! -f "/ark/instances/main.cfg" ] && cp /home/steam/samples/main.cfg /ark/instances
    mkdir -p /home/steam/.config/arkmanager
    ln -s /ark/instances /home/steam/.config/arkmanager/instances

    # we fix volume tree
    [ ! -d /ark/log ] && mkdir /ark/log
    [ ! -d /ark/backup ] && mkdir /ark/backup
    [ ! -d /ark/staging ] && mkdir /ark/staging
    [ ! -L /ark/Game.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/Game.ini Game.ini
    [ ! -L /ark/GameUserSettings.ini ] && ln -s server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini GameUserSettings.ini
}

function ark-install {
    echo "No game files found. Installing..."
    mkdir -p /ark/server/ShooterGame/Saved/SavedArks
	mkdir -p /ark/server/ShooterGame/Content/Mods
	mkdir -p /ark/server/ShooterGame/Binaries/Linux/
	touch /ark/server/ShooterGame/Binaries/Linux/ShooterGameServer
    arkmanager install --spinner
    echo "Ark instance is now installed, please check your configuration in the volume linked on /ark before restart the docker"
    echo "- <volume>/instances"
    echo "- <volume>/Game.ini & GameUserSettings.ini"
    echo "- <volume>/arkmanager.cfg"
    exit
}

function stop {
	if [ ${BACKUPONSTOP} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks)" ]; then
		echo "Backuping on stop..."
		arkmanager backup
	fi
	if [ ${WARNONSTOP} -eq 1 ];then
	    arkmanager stop --warn
	else
	    arkmanager stop
	fi
	exit
}

##################################### Main #####################################
# We fix the volume if needed
fix-volume

# We check if the game need to be installed
[ ! -d /ark/server ] || [ ! -f /ark/server/arkversion ] && ark-install

# Backup on stat is unable ?
if [ ${BACKUPONSTART} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks/)" ]; then
    echo "Backuping..."
    arkmanager backup
fi

# Server
if [ ${UPDATEONSTART} -eq 0 ]; then
    arkmanager start -noautoupdate
else
    arkmanager start
fi

echo "Server is running..."
trap stop INT
trap stop TERM

read < /tmp/FIFO &
wait