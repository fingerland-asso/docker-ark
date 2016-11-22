FROM ubuntu
MAINTAINER Caderrik <caderrik@gmail.com>

ENV SESSIONNAME="myArkSession" STEAMPORT=7778 SERVERPORT=27015 BACKUPONSTOP=0 \
    SERVERMAP="TheIsland" SERVERPASSWORD="" ADMINPASSWORD="changeit" \
    NBPLAYERS=70 UPDATEONSTART=1 BACKUPONSTART=1 BACKUPONSTOP=0 WARNONSTOP=0 \
    ARKMANAGER_VERSION=1.6.09 INSTALL_DIR=/ark

VOLUME "${INSTALL_DIR}"
EXPOSE ${STEAMPORT} 32330 ${SERVERPORT}

RUN set -x && \
    apt-get update -qq && \
    apt-get install -qq curl lib32gcc1

################################################################################
## cleaning as root
RUN apt-get clean autoclean purge && \
    rm -fr /tmp/*

RUN useradd -r -m -u 1000 steam

################################################################################
## ark volume
RUN mkdir -p "${INSTALL_DIR}" && \
    chown steam -R "${INSTALL_DIR}" && \
    chmod 755 -R "${INSTALL_DIR}"

################################################################################
## ARK SPEC

COPY config/arkmanager-user.cfg /home/steam/samples/arkmanager.cfg
COPY config/arkmanager-system.cfg /etc/arkmanager/arkmanager.cfg
COPY config/instance.cfg /home/steam/samples/main.cfg
COPY scripts/run-arkmanager.sh /usr/local/bin/run-arkmanager

USER steam
CMD ["/usr/local/bin/run-arkmanager"]