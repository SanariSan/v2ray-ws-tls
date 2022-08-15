#!/bin/bash
cat <<EOF
server {
    listen 80 default_server;
    server_name _;

    access_log /log/nginx-access.log;
    error_log /log/nginx-error.log;

    location / {
        # Redirect away for any location
        return 301 ${REDIR_URL};

        # Use this way to show other website with your url in address bar
        # proxy_pass ${REDIR_URL};
    }

    location ${V2_PATH} {
        # Redirect away if upgrade type is other than websocket
        if (\$http_upgrade != "websocket") {
            return 301 ${REDIR_URL};
        }

        # Uncomment to show real IP in v2ray access.log
        # proxy_set_header X-Real-IP \$remote_addr;
        # proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # WS upgrade require following options
        proxy_set_header        Host \$http_host;
        proxy_set_header        Upgrade \$http_upgrade;
        proxy_set_header        Connection      "upgrade";

        proxy_http_version 1.1;
        proxy_redirect off;

        proxy_pass http://localhost:${V2_PORT};
    }
}
EOF