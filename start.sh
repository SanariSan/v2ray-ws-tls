#!/bin/bash

### Colors ##
ESC=$(printf '\033') RESET="${ESC}[0m" BLACK="${ESC}[30m" RED="${ESC}[31m"
GREEN="${ESC}[32m" YELLOW="${ESC}[33m" BLUE="${ESC}[34m" MAGENTA="${ESC}[35m"
CYAN="${ESC}[36m" WHITE="${ESC}[37m" DEFAULT="${ESC}[39m"

### Color Functions ##
greenprint() { printf "${GREEN}%s${RESET}\n" "$1"; }
blueprint() { printf "${BLUE}%s${RESET}\n" "$1"; }
redprint() { printf "${RED}%s${RESET}\n" "$1"; }
yellowprint() { printf "${YELLOW}%s${RESET}\n" "$1"; }
magentaprint() { printf "${MAGENTA}%s${RESET}\n" "$1"; }
cyanprint() { printf "${CYAN}%s${RESET}\n" "$1"; }

# ------------------------------------------------------------

showSettings() {
    echo "DOMAIN = ${DOMAIN}"
    echo "CERTIFICATE_EMAIL = ${CERTIFICATE_EMAIL}"
    echo "V2_PATH = ${V2_PATH}"
    echo "V2_PORT = ${V2_PORT}"
    echo "UUIDS = ${UUIDS}"
    echo "REDIR_URL = ${REDIR_URL}"
    echo "ALTER_ID = ${ALTER_ID}"
}

testCert() {
    echo "Testing certificate request for ${DOMAIN}"
    /usr/bin/docker run \
    -it \
    --rm \
    --name ssl-request-dry-run \
    -v "/etc/letsencrypt:/etc/letsencrypt" \
    -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
    -p 80:80 \
    certbot/certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $DOMAIN --dry-run
}

applyBBR() {
    /bin/bash ./bbr.sh
}

# ------------------------------------------------------------

getNetworkCreateCommand() {
    command="docker network create inbound"
}

getNginxContainerRunCommand() {
    command="/usr/bin/docker run \
    --rm \
    --detach \
    --name nginx-proxy \
    --net inbound \
    --publish 80:80 \
    --publish 443:443 \
    --volume $(pwd)/log:/log \
    --volume certs:/etc/nginx/certs \
    --volume vhost:/etc/nginx/vhost.d \
    --volume html:/usr/share/nginx/html \
    --volume /var/run/docker.sock:/tmp/docker.sock:ro \
    nginxproxy/nginx-proxy:1.0"
}

getAcmeContainerRunCommand() {
    command="/usr/bin/docker run \
    --rm \
    --detach \
    --name nginx-proxy-acme \
    --net inbound \
    --volumes-from nginx-proxy \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --volume acme:/etc/acme.sh \
    --env \"DEFAULT_EMAIL=${CERTIFICATE_EMAIL}\" \
    nginxproxy/acme-companion:2.2"
}

getV2RayContainerBuildCommand() {
    command="/usr/bin/docker build -t nginx-v2ray $(pwd)/container"
}

getV2RayContainerRunCommand() {
    command="/usr/bin/docker run \
    --rm \
    --detach \
    --name nginx-v2ray \
    --net inbound \
    --volume $(pwd)/log:/log \
    --volume $(pwd)/client:/client \
    --env \"VIRTUAL_HOST=${DOMAIN}\" \
    --env \"LETSENCRYPT_HOST=${DOMAIN}\" \
    --env \"DOMAIN=${DOMAIN}\" \
    --env \"V2_PATH=${V2_PATH}\" \
    --env \"V2_PORT=${V2_PORT}\" \
    --env \"UUIDS=${UUIDS}\" \
    --env \"REDIR_URL=${REDIR_URL}\" \
    --env \"ALTER_ID=${ALTER_ID}\" \
    nginx-v2ray"
}

# ------------------------------------------------------------

createNetworkOrSkip() {
    if [ $(docker network ls -q --filter name=inbound) ]; then
        return
    fi

    getNetworkCreateCommand
    bash -c "$command"
}

startNginxContainer() {
    if [ $(docker ps -aq -f name='^nginx-proxy$') ]; then
        echo "Container nginx-proxy is already running"
        return
    fi
    echo "Starting nginx-proxy container"
    createNetworkOrSkip
    getNginxContainerRunCommand
    bash -c "$command"
}

startAcmeContainer() {
    if [ $(docker ps -aq -f name='^nginx-proxy-acme$') ]; then
        echo "Container nginx-proxy-acme is already running"
        return
    fi
    echo "Starting nginx-proxy-acme container"
    createNetworkOrSkip
    getAcmeContainerRunCommand
    bash -c "$command"
}

startV2RayContainer() {
    if [ $(docker ps -aq -f name='^nginx-v2ray$') ]; then
        echo "Container nginx-v2ray is already running"
        return
    fi
    echo "Starting nginx-v2ray container"
    createNetworkOrSkip
    getV2RayContainerBuildCommand
    bash -c "$command"
    getV2RayContainerRunCommand
    bash -c "$command"
}

# ------------------------------------------------------------

stopNginxContainer() {
    if [ ! $(docker ps -aq -f name='^nginx-proxy$') ]; then
        echo "Container nginx-proxy is already stopped"
        return
    fi
    echo "Stopping nginx-proxy container"
    docker container stop nginx-proxy
}

stopAcmeContainer() {
    if [ ! $(docker ps -aq -f name='^nginx-proxy-acme$') ]; then
        echo "Container nginx-proxy-acme is already stopped"
        return
    fi
    echo "Stopping nginx-proxy-acme container"
    docker container stop nginx-proxy-acme
}

stopV2RayContainer() {
    if [ ! $(docker ps -aq -f name='^nginx-v2ray$') ]; then
        echo "Container nginx-v2ray is already stopped"
        return
    fi
    echo "Stopping nginx-v2ray container"
    docker container stop nginx-v2ray
}

# ------------------------------------------------------------

startAllContainers() {
    startNginxContainer
    startAcmeContainer
    startV2RayContainer
}

stopAllContainers() {
    stopNginxContainer
    stopAcmeContainer
    stopV2RayContainer
}

# ------------------------------------------------------------

# $1 name $2 path
setupAutostartService() {
    cat <<EOF > ${2}
[Unit]
Description=${1}
After=docker.service
BindsTo=docker.service
ReloadPropagatedFrom=docker.service
StartLimitIntervalSec=0

[Service]
Type=forking
RemainAfterExit=yes
ExecStart=${command}
TimeoutSec=0
Restart=always
RestartSec=30s
GuessMainPID=no

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable $1
    systemctl start $1
}

isServiceExists() {
    local x=$1
    if systemctl status "${x}" 2> /dev/null | grep -Fq "Active:"; then
            return 0
    else
            return 1
    fi
}

setupAutostartNginxContainer() {
    if isServiceExists "nginx-proxy"; then
        echo "Service for nginx-proxy already exists"
        return
    fi
    echo "Setting up autostart for nginx-proxy container"
    stopNginxContainer
    getNginxContainerRunCommand
    setupAutostartService "nginx-proxy" "/etc/systemd/system/nginx-proxy.service"
}

setupAutostartAcmeContainer() {
    if isServiceExists "nginx-proxy-acme"; then
        echo "Service for nginx-proxy-acme already exists"
        return
    fi
    echo "Setting up autostart for nginx-proxy-acme container"
    stopAcmeContainer
    getAcmeContainerRunCommand
    setupAutostartService "nginx-proxy-acme" "/etc/systemd/system/nginx-proxy-acme.service"
}

setupAutostartV2RayContainer() {
    if isServiceExists "nginx-v2ray"; then
        echo "Service for nginx-v2ray already exists"
        return
    fi
    echo "Setting up autostart for nginx-v2ray container"
    stopV2RayContainer
    getV2RayContainerRunCommand
    setupAutostartService "nginx-v2ray" "/etc/systemd/system/nginx-v2ray.service"
}

setupAutostartAllContainer() {
    setupAutostartNginxContainer
    setupAutostartAcmeContainer
    setupAutostartV2RayContainer
}

# ------------------------------------------------------------

# $1 service-name $2 path
removeAutostartService() {
    systemctl stop $1
    systemctl disable $1
    rm $2
    systemctl daemon-reload
    systemctl reset-failed
}

removeAutostartNginxContainer() {
    if ! isServiceExists "nginx-proxy"; then
        echo "Service for nginx-proxy not found"
        return
    fi
    echo "Removing autostart for nginx-proxy container"
    removeAutostartService "nginx-proxy" "/etc/systemd/system/nginx-proxy.service"
}

removeAutostartAcmeContainer() {
    if ! isServiceExists "nginx-proxy-acme"; then
        echo "Service for nginx-proxy-acme not found"
        return
    fi
    echo "Removing autostart for nginx-proxy-acme container"
    removeAutostartService "nginx-proxy-acme" "/etc/systemd/system/nginx-proxy-acme.service"
}

removeAutostartV2RayContainer() {
    if ! isServiceExists "nginx-v2ray"; then
        echo "Service for nginx-v2ray not found"
        return
    fi
    echo "Removing autostart for nginx-v2ray container"
    removeAutostartService "nginx-v2ray" "/etc/systemd/system/nginx-v2ray.service"
}

removeAutostartAllContainer() {
    removeAutostartNginxContainer
    removeAutostartAcmeContainer
    removeAutostartV2RayContainer
}

# ------------------------------------------------------------

nginxAccessLog() {
    less +F ./log/nginx-access.log
}

nginxErrorLog() {
    less +F ./log/nginx-error.log
}

v2RayAccessLog() {
    less +F ./log/v2-access.log
}

v2RayErrorLog() {
    less +F ./log/v2-error.log
}

clearNginxLogs() {
    echo "Clearing nginx logs"
    echo "" >| ./log/nginx-access.log
    echo "" >| ./log/nginx-error.log
}
clearV2RayLogs() {
    echo "Clearing v2ray logs"
    echo "" >| ./log/v2-access.log
    echo "" >| ./log/v2-error.log
}

# ------------------------------------------------------------

menuContainers() {
    echo -ne "
+++++++++++++++++
$(magentaprint 'Containers menu')
++++++++++++++++++++++++++++++++++++++++++++++++++++

Containers status:

$([ $(docker ps -aq -f name='^nginx-proxy$') ] && greenprint '●' || redprint '●') nginx-proxy
$([ $(docker ps -aq -f name='^nginx-proxy-acme$') ] && greenprint '●' || redprint '●') nginx-proxy-acme
$([ $(docker ps -aq -f name='^nginx-v2ray$') ] && greenprint '●' || redprint '●') nginx-v2ray

++++++++++++++++++++++++++++++++++++++++++++++++++++

Action:

$(greenprint '1)') Start nginx-proxy container
$(greenprint '2)') Start nginx-proxy-acme container
$(greenprint '3)') Start V2Ray container
$(greenprint '4)') Start ALL containers
===
$(cyanprint '5)') Stop nginx-proxy container
$(cyanprint '6)') Stop nginx-proxy-acme container
$(cyanprint '7)') Stop V2Ray container
$(cyanprint '8)') Stop ALL containers
===
$(greenprint '9)') Test certificate request for domain (${DOMAIN})
===
$(yellowprint '0/Enter)') Back
$(redprint '999)') Exit

++++++++++++++++++++++++++++++++++++++++++++++++++++

Choose an option:  "
    read -r ans

    clear

    case $ans in
    1)
        startNginxContainer
        menuContainers
        ;;
    2)
        startAcmeContainer
        menuContainers
        ;;
    3)
        startV2RayContainer
        menuContainers
        ;;
    4)
        startAllContainers
        menuContainers
        ;;
    5)
        stopNginxContainer
        menuContainers
        ;;
    6)
        stopAcmeContainer
        menuContainers
        ;;
    7)
        stopV2RayContainer
        menuContainers
        ;;
    8)
        stopAllContainers
        menuContainers
        ;;
    9)
        testCert
        menuContainers
        ;;
    0)
        menuGeneral
        ;;
    "")
        menuGeneral
        ;;
    999)
        exit 0
        ;;
    *)
        echo "Wrong option."
        menuContainers
        ;;
    esac
}

menuAutostart() {
    echo -ne "
+++++++++++++++++
$(magentaprint 'Autostart menu')
++++++++++++++++++++++++++++++++++++++++++++++++++++

Services status:

$(systemctl is-active --quiet nginx-proxy && greenprint '●' || redprint '●') nginx-proxy
$(systemctl is-active --quiet nginx-proxy-acme && greenprint '●' || redprint '●') nginx-proxy-acme
$(systemctl is-active --quiet nginx-v2ray && greenprint '●' || redprint '●') nginx-v2ray

++++++++++++++++++++++++++++++++++++++++++++++++++++

Actions:

$(greenprint '1)') Setup autostart for nginx-proxy container
$(greenprint '2)') Setup autostart for nginx-proxy-acme container
$(greenprint '3)') Setup autostart for V2Ray container
$(greenprint '4)') Setup autostart for ALL containers
===
$(cyanprint '5)') Remove autostart for nginx-proxy container
$(cyanprint '6)') Remove autostart for nginx-proxy-acme container
$(cyanprint '7)') Remove autostart for V2Ray container
$(cyanprint '8)') Remove autostart for ALL containers
===
$(yellowprint '0/Enter)') Back
$(redprint '999)') Exit

++++++++++++++++++++++++++++++++++++++++++++++++++++

Choose an option:  "
    read -r ans

    clear

    case $ans in
    1)
        setupAutostartNginxContainer
        menuAutostart
        ;;
    2)
        setupAutostartAcmeContainer
        menuAutostart
        ;;
    3)
        setupAutostartV2RayContainer
        menuAutostart
        ;;
    4)
        setupAutostartAllContainer
        menuAutostart
        ;;
    5)
        removeAutostartNginxContainer
        menuAutostart
        ;;
    6)
        removeAutostartAcmeContainer
        menuAutostart
        ;;
    7)
        removeAutostartV2RayContainer
        menuAutostart
        ;;
    8)
        removeAutostartAllContainer
        menuAutostart
        ;;
    0)
        menuGeneral
        ;;
    "")
        menuGeneral
        ;;
    999)
        exit 0
        ;;
    *)
        echo "Wrong option."
        menuAutostart
        ;;
    esac
}

menuLogs() {
    echo -ne "
+++++++++++++++++
$(magentaprint 'Logs menu') (ctrl+c to stop, then Q to get back)
++++++++++++++++++++++++++++++++++++++++++++++++++++

Actions:

$(greenprint '1)') Nginx-proxy access log
$(greenprint '2)') Nginx-proxy error log
$(greenprint '3)') V2Ray access log
$(greenprint '4)') V2Ray error log
===
$(cyanprint '5)') Clear logs for nginx-proxy container
$(cyanprint '6)') Clear logs for nginx-v2ray container
===
$(yellowprint '0/Enter)') Back
$(redprint '999)') Exit

++++++++++++++++++++++++++++++++++++++++++++++++++++

Choose an option:  "
    read -r ans

    clear

    case $ans in
    1)
        nginxAccessLog
        menuLogs
        ;;
    2)
        nginxErrorLog
        menuLogs
        ;;
    3)
        v2RayAccessLog
        menuLogs
        ;;
    4)
        v2RayErrorLog
        menuLogs
        ;;
    5)
        clearNginxLogs
        menuLogs
        ;;
    6)
        clearV2RayLogs
        menuLogs
        ;;
    0)
        menuGeneral
        ;;
    "")
        menuGeneral
        ;;
    999)
        exit 0
        ;;
    *)
        echo "Wrong option."
        menuLogs
        ;;
    esac
}

menuGeneral() {
    echo -ne "
+++++++++++++++++
$(magentaprint 'General menu')
++++++++++++++++++++++++++++++++++++++++++++++++++++

Actions:

$(greenprint '1)') Containers menu
$(greenprint '2)') Autostart menu
$(greenprint '3)') Logs menu
$(greenprint '4)') Show current settings
$(greenprint '5)') Display client connection details
$(greenprint '6)') Apply google BBR TCP congestion control algorithm
===
$(redprint '999)') Exit

++++++++++++++++++++++++++++++++++++++++++++++++++++

Choose an option:  "
    read -r ans

    clear

    case $ans in
    1)
        menuContainers
        ;;
    2)
        menuAutostart
        ;;
    3)
        menuLogs
        ;;
    4)
        showSettings
        menuGeneral
        ;;
    5)
        echo -e "$(cyanprint 'For now just copy ./client/config.json via ftp or copy content shown below directly')"
        cat ./client/config.json
        echo -e "$(cyanprint 'For now just copy ./client/config.json via ftp or copy content shown above directly')"
        echo "Press any key to continue..."
        read -n 1
        menuGeneral
        ;;
    6)
        applyBBR
        menuGeneral
        ;;
    999)
        exit 0
        ;;
    *)
        echo "Wrong option."
        menuGeneral
        ;;
    esac
}

mkdir -p ./log
mkdir -p ./client
touch ./log/v2-access.log
touch ./log/v2-error.log
touch ./log/nginx-access.log
touch ./log/nginx-error.log
chmod -R 755 ./client
chmod -R 755 ./log
chmod 755 ./bbr.sh

source ./.env

clear
menuGeneral
