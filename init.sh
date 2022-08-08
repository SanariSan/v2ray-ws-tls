#!/bin/bash

# bash /conf/nginx.conf.sh > /etc/nginx/conf.d/default.conf
# echo /etc/nginx/conf.d/default.conf
# cat /etc/nginx/conf.d/default.conf

rm -rf /etc/nginx/sites-enabled/default
/v2raydir/v2ray &
nginx -g 'daemon off;'