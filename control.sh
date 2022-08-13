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

showSettings() {
    echo "DOMAIN = $DOMAIN"
    echo "CERTIFICATE_EMAIL = $CERTIFICATE_EMAIL"
    echo "V2_PATH = $V2_PATH"
    echo "V2_PORT = $V2_PORT"
    echo "UUIDS = $UUIDS"
    echo "REDIR_URL = $REDIR_URL"
    echo "ALTER_ID = $ALTER_ID" 
}

testCert() {
    echo "Testing certificate request for $DOMAIN"
    docker run \
    -it \
    --rm \
    --name ssl-request-dry-run \
    -v "/etc/letsencrypt:/etc/letsencrypt" \
    -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
    -p 80:80 \
    certbot/certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $DOMAIN --dry-run
}

startNginxContainer() {
    echo "Starting nginx-proxy container"
    docker run \
    --rm \
    --detach \
    --name nginx-proxy \
    --publish 80:80 \
    --publish 443:443 \
    --volume $(pwd)/log:/log \
    --volume certs:/etc/nginx/certs \
    --volume vhost:/etc/nginx/vhost.d \
    --volume html:/usr/share/nginx/html \
    --volume /var/run/docker.sock:/tmp/docker.sock:ro \
    nginxproxy/nginx-proxy
}

startAcmeContainer() {
    echo "Starting nginx-proxy-acme container"
    docker run \
    --rm \
    --detach \
    --name nginx-proxy-acme \
    --volumes-from nginx-proxy \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --volume acme:/etc/acme.sh \
    --env "DEFAULT_EMAIL=$CERTIFICATE_EMAIL" \
    nginxproxy/acme-companion
}

startV2RayContainer() {
    echo "Starting nginx-v2ray container"
    docker build -t nginx-v2ray:1 ./container
    docker run \
    --rm \
    --detach \
    --name nginx-v2ray \
    --volume $(pwd)/log:/log \
    --volume $(pwd)/client:/client \
    --env "VIRTUAL_HOST=$DOMAIN" \
    --env "LETSENCRYPT_HOST=$DOMAIN" \
    --env "DOMAIN=$DOMAIN" \
    --env "V2_PATH=$V2_PATH" \
    --env "V2_PORT=$V2_PORT" \
    --env "UUIDS=$UUIDS" \
    --env "REDIR_URL=$REDIR_URL" \
    --env "ALTER_ID=$ALTER_ID" \
    nginx-v2ray:1
}

stopNginxContainer() {
    echo "Stopping nginx-proxy container"
    docker container stop nginx-proxy
}

stopAcmeContainer() {
    echo "Stopping nginx-proxy-acme container"
    docker container stop nginx-proxy-acme
}

stopV2RayContainer() {
    echo "Stopping nginx-v2ray container"
    docker container stop nginx-v2ray
}

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

applyBBR() {
    /bin/bash ./bbr.sh
}

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

menuContainers() {
    echo -ne "
+++++++++++++++++
$(magentaprint 'Containers menu')
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
$(greenprint '9)') Test certificate request for domain ($DOMAIN)
===
$(yellowprint '0)') Back
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
    999)
        exit 0
        ;;
    *)
        echo "Wrong option."
        menuContainers
        ;;
    esac
}

menuLogs() {
    echo -ne "
+++++++++++++++++
$(magentaprint 'Logs menu') (ctrl+c to stop, then Q to get back)
++++++++++++++++++++++++++++++++++++++++++++++++++++
Action:

$(greenprint '1)') Nginx access log
$(greenprint '2)') Nginx error log
$(greenprint '3)') V2Ray access log
$(greenprint '4)') V2Ray error log
===
$(yellowprint '0)') Back
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
    0)
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
Action:

$(greenprint '1)') Containers menu
$(greenprint '2)') Logs menu
$(greenprint '3)') Display client connection details
$(greenprint '4)') Show current settings
$(greenprint '5)') Apply google BBR TCP congestion control algorithm
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
        menuLogs
        ;;
    3)
        echo "For now just copy ./client/config.json"
        menuGeneral
        ;;
    4)
        showSettings
        menuGeneral
        ;;
    5)
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

clear
menuGeneral
