FROM debian:bullseye

WORKDIR /

ARG V2RAY_VERSION=v4.31.0

USER root

COPY --chown=root:root conf/ /conf
COPY --chown=root:root init.sh /init.sh

# ARG DEBIAN_FRONTEND=noninteractive

RUN echo "Container started $(date)" >> /track.txt
RUN apt update -y
RUN apt install -y curl wget libarchive-tools nginx-light
RUN apt clean -y
RUN mkdir -p /v2raydir /wwwroot
RUN wget -qO- "https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-64.zip" | \
    bsdtar -xvf- -C /v2raydir
RUN chmod +x /init.sh

CMD /init.sh