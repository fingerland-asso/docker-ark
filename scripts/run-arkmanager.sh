#!/usr/bin/env bash

[ -p /tmp/FIFO ] && rm /tmp/FIFO
mkfifo /tmp/FIFO

function install-steamcmd {
    echo "steamcmd not found. Installing..."
    mkdir -p "${INSTALL_DIR}/steamcmd"
    cd "${INSTALL_DIR}/steamcmd"
    curl -Ss http://media.steampowered.com/installer/steamcmd_linux.tar.gz | tar -xz
}

function install-arkmanager {
    echo "ark-server-tools not found. Installing..."
    mkdir -p "${INSTALL_DIR}/tmp"
    cd "${INSTALL_DIR}/tmp"
    curl -Ss "https://codeload.github.com/FezVrasta/ark-server-tools/tar.gz/v${ARKMANAGER_VERSION}" | tar -xz
    cd "${INSTALL_DIR}/tmp/ark-server-tools-${ARKMANAGER_VERSION}/tools"
    chmod +x install.sh
    ./install.sh --prefix "${INSTALL_DIR}/ark-server-tools"
}

function install-ark {
    echo "No game files found. Installing..."
    mkdir -p ${INSTALL_DIR}/server/ShooterGame/Saved/SavedArks
	mkdir -p ${INSTALL_DIR}/server/ShooterGame/Content/Mods
	mkdir -p ${INSTALL_DIR}/server/ShooterGame/Binaries/Linux/
	touch ${INSTALL_DIR}/server/ShooterGame/Binaries/Linux/ShooterGameServer
    /usr/local/bin/arkmanager install --spinner
    echo "Ark instance is now installed, please check your configuration in the volume linked on ${INSTALL_DIR} before restart the docker"
    echo "- <volume>/instances"
    echo "- <volume>/Game.ini & GameUserSettings.ini"
    echo "- <volume>/arkmanager.cfg"
    exit
}

function fix-volume {
    # we add user settings
    [ ! -f "${INSTALL_DIR}/arkmanager.cfg" ] && cp "/home/steam/samples/arkmanager.cfg" "${INSTALL_DIR}/arkmanager.cfg"
    ln -s "${INSTALL_DIR}/arkmanager.cfg" "/home/steam/.arkmanager.cfg"

    # we get the instances
    [ ! -d "${INSTALL_DIR}/instances" ] && mkdir "${INSTALL_DIR}/instances"
    [ ! -f "${INSTALL_DIR}/instances/main.cfg" ] && cp "/home/steam/samples/main.cfg" "${INSTALL_DIR}/instances"
    mkdir -p "/home/steam/.config/arkmanager"
    ln -s "${INSTALL_DIR}/instances" "/home/steam/.config/arkmanager/instances"

    # we fix volume tree
    [ ! -d "${INSTALL_DIR}/log" ] && mkdir "${INSTALL_DIR}/log"
    [ ! -d "${INSTALL_DIR}/backup" ] && mkdir "${INSTALL_DIR}/backup"
    [ ! -d "${INSTALL_DIR}/staging" ] && mkdir "${INSTALL_DIR}/staging"
    [ ! -L "${INSTALL_DIR}/Game.ini" ] && ln -s "${INSTALL_DIR}/server/ShooterGame/Saved/Config/LinuxServer/Game.ini" "${INSTALL_DIR}/Game.ini"
    [ ! -L "${INSTALL_DIR}/GameUserSettings.ini" ] && ln -s "${INSTALL_DIR}/server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini" "${INSTALL_DIR}/GameUserSettings.ini"
}


function stop {
	if [ ${BACKUPONSTOP} -eq 1 ] && [ "$(ls -A ${INSTALL_DIR}/server/ShooterGame/Saved/SavedArks)" ]; then
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

# we check if steamcmd is installed
[ ! -d "${INSTALL_DIR}/steamcmd" ] && install-steamcmd

# we check if arkmanager is installed
[ ! -f "/usr/local/bin/arkmanager" ] && install-arkmanager

# We check if the game need to be installed
[ ! -d "${INSTALL_DIR}/server" ] || [ ! -f "${INSTALL_DIR}/server/arkversion" ] && install-ark

# Backup on stat is unable ?
if [ ${BACKUPONSTART} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks/)" ]; then
    echo "Backuping..."
    arkmanager backup
fi

# Server start
if [ ${UPDATEONSTART} -eq 0 ]; then
    arkmanager start -noautoupdate
else
    arkmanager start
fi

echo "Server is running..."
trap stop INT
trap stop TERM

read < /tmp/FIFO &
