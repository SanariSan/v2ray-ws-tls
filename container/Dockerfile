FROM debian:bullseye

# ---

ARG V2RAY_VERSION=v4.45.2
ARG USER_NAME=root
ARG DEBIAN_FRONTEND=noninteractive

# ---

USER ${USER_NAME}
WORKDIR /

# ---

COPY --chown=${USER_NAME}:${USER_NAME} /conf/ /conf
COPY --chown=${USER_NAME}:${USER_NAME} /init.sh /init.sh

RUN chmod -R 755 /conf
RUN chmod 755 /init.sh

# ---

RUN apt update -y
RUN apt install -y wget libarchive-tools nginx-light
RUN apt clean -y

# ---

RUN mkdir -p /v2raydir
RUN wget -qO- "https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-64.zip" | \
    bsdtar -xvf- -C /v2raydir
RUN chmod -R 755 /v2raydir

# ---

CMD /init.sh