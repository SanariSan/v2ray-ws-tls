#!/bin/bash
cat <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/log/v2-access.log",
    "error": "/log/v2-error.log"
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "block"
      }
    ]
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": ${V2_PORT},
      "protocol": "vmess",
      "settings": {
        "clients": [${UUIDS_JSON}],
        "default": {
          "level": 0,
          "alterId": ${ALTER_ID}
        }
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${V2_PATH}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ]
}
EOF
