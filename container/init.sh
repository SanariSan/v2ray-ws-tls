#!/bin/bash

placeNginxConfig() {
        bash /conf/nginx.conf.sh > /etc/nginx/conf.d/default.conf
        cat /etc/nginx/conf.d/default.conf
}

placeServerV2RayConfig() {
        bash /conf/v2ray-config.json.sh > /v2raydir/config.json
        cat /v2raydir/config.json
}

placeClientV2RayConfig() {
        bash /conf/v2ray-client.json.sh > /client/config.json
        cat /client/config.json
}

uuidsJsonParse() {
        UUIDS_ARR=$(echo $UUIDS | tr ";" "\n")
        UUIDS_JSON=""

        for UUID_SINGLE in $UUIDS_ARR
        do
                UUIDS_JSON+="{\"id\":\"${UUID_SINGLE}\"},"
        done

        UUIDS_JSON="${UUIDS_JSON%?}"
        export UUIDS_JSON
}

uuidsJsonParse
placeNginxConfig
placeServerV2RayConfig
placeClientV2RayConfig

rm -rf /etc/nginx/sites-enabled/default
/v2raydir/v2ray &
nginx -g 'daemon off;'