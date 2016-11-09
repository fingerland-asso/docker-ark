############################### change if needed ###############################
CONTAINER=ark-server
VOLUME=/data/dockers/${CONTAINER}
IMAGE=fingerland/${CONTAINER}
SESSIONNAME=myserver
SERVERMAP=TheIsland
SERVERPASSWORD=
ADMINPASSWORD=changeit
SERVERPORT=27015
STEAMPORT=7778
BACKUPONSTART=1
UPDATEPONSTART=1
BACKUPONSTOP=0
WARNONSTOP=0
OPTIONS=-v '${VOLUME}:/ark' -p '${STEAMPORT}:${STEAMPORT}' -p '${STEAMPORT}:${STEAMPORT}/udp' -p '${SERVERPORT}:${SERVERPORT}' -p '${SERVERPORT}:${SERVERPORT}/udp' -e 'SESSIONNAME=${SESSIONNAME}' -e 'SERVERMAP=${SERVERMAP}' -e 'SERVERPASSWORD=${SERVERPASSWORD}' -e 'ADMINPASSWORD=${ADMINPASSWORD}' -e 'SERVERPORT=${SERVERPORT}' -e 'STEAMPORT=${STEAMPORT}' -e 'BACKUPONSTART=${BACKUPONSTART}' -e 'UPDATEPONSTART=${UPDATEPONSTART}' -e 'BACKUPONSTOP=${BACKUPONSTOP}' -e 'WARNONSTOP=${WARNONSTOP}'
################################ computed data #################################
SERVICE_ENV_FILE=${PWD}/${CONTAINER}.env
SERVICE_FILE=${PWD}/${CONTAINER}.service
################################################################################

help:
	@echo "Fingerland ARK server (docker builder)"

build:
	@docker build -t ${IMAGE} .

volume:
	@sudo mkdir -p ${VOLUME}
	@sudo chown -R 1000:1000 ${VOLUME}

run: volume
	@docker run -ti --restart=always ${OPTIONS} ${IMAGE}

systemd-service:
	@echo "CONTAINER=${CONTAINER}" > ${SERVICE_ENV_FILE}
	@echo "VOLUME=${VOLUME}" >> ${SERVICE_ENV_FILE}
	@echo "OPTIONS=${OPTIONS}" >> ${SERVICE_ENV_FILE}
	@cp service.sample ${SERVICE_FILE}
	@sed -i -e "s;EnvironmentFile=.*$$;EnvironmentFile=${SERVICE_ENV_FILE};" ${SERVICE_FILE}
	#@sudo systemctl enable ${SERVICE_FILE}

install: build volume systemd-service
	@sudo systemctl start ${CONTAINER}.service