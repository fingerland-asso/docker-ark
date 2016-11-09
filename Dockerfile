FROM ubuntu
MAINTAINER Caderrik <caderrik@gmail.com>

RUN set -x && \
    apt-get update -qq && \
    apt-get install -qq curl lib32gcc1

RUN useradd -r -m -u 1000 steam

################################################################################
## ark volume
RUN mkdir /ark && \
    chown steam -R /ark && \
    chmod 755 -R /ark

################################################################################
## arkmanager install
WORKDIR "/tmp"
ENV ARKMANAGER_VERSION=1.6
RUN curl -Ss https://codeload.github.com/FezVrasta/ark-server-tools/tar.gz/v${ARKMANAGER_VERSION} | tar -xz && \
    chmod +x /tmp/ark-server-tools-*/tools/install.sh && \
    cd /tmp/ark-server-tools-*/tools && \
    ./install.sh steam

################################################################################
## cleaning as root
RUN apt-get clean autoclean purge && \
    rm -fr /tmp/*

################################################################################
## steamcmd installcat
USER steam
WORKDIR "/home/steam"
RUN mkdir steamcmd &&\
    cd steamcmd &&\
    curl -Ss http://media.steampowered.com/installer/steamcmd_linux.tar.gz | tar -xz

################################################################################
## ARK SPEC

COPY config/arkmanager-user.cfg /home/steam/samples/arkmanager.cfg
COPY config/arkmanager-system.cfg /etc/arkmanager/arkmanager.cfg
COPY config/instance.cfg /home/steam/samples/main.cfg
COPY scripts/run-arkmanager.sh /usr/local/bin/run-arkmanager

ENV SESSIONNAME="myArkSession" STEAMPORT=7778 SERVERPORT=27015 BACKUPONSTOP=0 \
    SERVERMAP="TheIsland" SERVERPASSWORD="" ADMINPASSWORD="changeit" \
    NBPLAYERS=70 UPDATEONSTART=1 BACKUPONSTART=1 BACKUPONSTOP=0 WARNONSTOP=0

VOLUME "/ark"
WORKDIR "/ark"
EXPOSE ${STEAMPORT} 32330 ${SERVERPORT}

CMD ["/usr/local/bin/run-arkmanager"]