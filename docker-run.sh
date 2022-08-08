#test
docker run \
-it \
--rm \
--name test-project-with-ssl \
-v "/etc/letsencrypt:/etc/letsencrypt" \
-v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
-p 80:80 \
certbot/certbot certonly --standalone --agree-tos --register-unsafely-without-email -d DOMAIN.NAME --dry-run

#nginx-entry-point
docker run --detach \
--name nginx-proxy \
--publish 80:80 \
--publish 443:443 \
--volume certs:/etc/nginx/certs \
--volume vhost:/etc/nginx/vhost.d \
--volume html:/usr/share/nginx/html \
--volume /var/run/docker.sock:/tmp/docker.sock:ro \
nginxproxy/nginx-proxy

#ssl-cert-controller
docker run --detach \
--name nginx-proxy-acme \
--volumes-from nginx-proxy \
--volume /var/run/docker.sock:/var/run/docker.sock:ro \
--volume acme:/etc/acme.sh \
--env "DEFAULT_EMAIL=testmailidc@idc.co" \
nginxproxy/acme-companion

#v2ray
docker run \
--rm \
-it \
--name test-proxy-app \
--volumes-from nginx-proxy \
--env "VIRTUAL_HOST=DOMAIN.NAME" \
--env "LETSENCRYPT_HOST=DOMAIN.NAME" \
--env "LETSENCRYPT_TEST=false" \
--env "WEBSOCKETS=1" \
v2ray-nginx:1

#current one
#v2ray-bare
docker run \
--rm \
-it \
--name test-proxy-app-bare \
--publish 80:80 \
--publish 443:443 \
--volume certs:/etc/nginx/certs \
--volume vhost:/etc/nginx/vhost.d \
--volume html:/usr/share/nginx/html \
v2ray-nginx-bare:1

