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
    echo "server-tools not found. Installing..."
    mkdir -p "${INSTALL_DIR}/tmp"
    cd "${INSTALL_DIR}/tmp"
    curl -Ss "https://codeload.github.com/FezVrasta/ark-server-tools/tar.gz/v${ARKMANAGER_VERSION}" | tar -xz
    cd "${INSTALL_DIR}/tmp/ark-server-tools-${ARKMANAGER_VERSION}/tools"
    chmod +x install.sh
    ./install.sh --prefix "${INSTALL_DIR}/server-tools" --me
    rm -fr "${INSTALL_DIR}/ark-server-tools/.*"
}

function install-ark {
    cd ${INSTALL_DIR}
    echo "No game files found. Installing..."
    mkdir -p ${INSTALL_DIR}/server/ShooterGame/Saved/SavedArks
	mkdir -p ${INSTALL_DIR}/server/ShooterGame/Content/Mods
	mkdir -p ${INSTALL_DIR}/server/ShooterGame/Binaries/Linux/
	touch ${INSTALL_DIR}/server/ShooterGame/Binaries/Linux/ShooterGameServer
    ${INSTALL_DIR}/server-tools/bin/arkmanager install --spinner
    echo "Ark instance is now installed, please check your configuration in the volume linked on ${INSTALL_DIR} before restart the docker"
    echo "- <volume>/config/instances"
    echo "- <volume>/config/Game.ini & GameUserSettings.ini"
    echo "- <volume>/config/arkmanager.cfg"
    exit
}

function fix-volume {
    # we add user config
    [ ! -d "${INSTALL_DIR}/config" ] && mkdir -p "${INSTALL_DIR}/config"
    [ ! -f "${INSTALL_DIR}/config/arkmanager.cfg" ] && cp "/home/steam/samples/arkmanager.cfg" "${INSTALL_DIR}/config/arkmanager.cfg"
    ln -s "${INSTALL_DIR}/config/arkmanager.cfg" "/home/steam/.arkmanager.cfg"

    # we get the instances
    [ ! -d "${INSTALL_DIR}/config/instances" ] && mkdir "${INSTALL_DIR}/config/instances"
    [ ! -f "${INSTALL_DIR}/config/instances/main.cfg" ] && cp "/home/steam/samples/main.cfg" "${INSTALL_DIR}/config/instances"
    mkdir -p "/home/steam/.config/arkmanager"
    ln -s "${INSTALL_DIR}/config/instances" "/home/steam/.config/arkmanager/instances"

    # we fix volume tree
    [ ! -d "${INSTALL_DIR}/config/log" ] && mkdir "${INSTALL_DIR}/config/log"
    [ ! -d "${INSTALL_DIR}/config/backup" ] && mkdir "${INSTALL_DIR}/config/backup"
    [ ! -d "${INSTALL_DIR}/config/staging" ] && mkdir "${INSTALL_DIR}/config/staging"

    # We check Ark server config
    cd "${INSTALL_DIR}/config"
    [ ! -L Game.ini ] && ln -s "../server/ShooterGame/Saved/Config/LinuxServer/Game.ini" Game.ini
    [ ! -L GameUserSettings.ini ] && ln -s "../server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini" GameUserSettings.ini
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
# we check if steamcmd is installed
[ ! -d "${INSTALL_DIR}/steamcmd" ] && install-steamcmd

# we check if arkmanager is installed
[ ! -f "${INSTALL_DIR}/server-tools/bin/arkmanager" ] && install-arkmanager

# We fix the volume if needed
fix-volume

# We check if the game need to be installed
[ ! -d "${INSTALL_DIR}/server" ] || [ ! -f "${INSTALL_DIR}/server/arkversion" ] && install-ark

cd "${INSTALL_DIR}"
# Backup on stat is unable ?
if [ ${BACKUPONSTART} -eq 1 ] && [ "$(ls -A server/ShooterGame/Saved/SavedArks/)" ]; then
    echo "Backuping..."
    ${INSTALL_DIR}/server-tools/bin/arkmanager backup
fi

# Server start
if [ ${UPDATEONSTART} -eq 0 ]; then
    ${INSTALL_DIR}/server-tools/bin/arkmanager start -noautoupdate
else
    ${INSTALL_DIR}/server-tools/bin/arkmanager start
fi

echo "Server is running..."
trap stop INT
trap stop TERM

read < /tmp/FIFO &
