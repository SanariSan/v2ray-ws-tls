#!/bin/bash

export DOMAIN=yourdomain.name
export CERTIFICATE_EMAIL=your_email@ema.il
export V2_PATH=/path
export V2_PORT=9966
export UUIDS="9b3ae01a-ea22-4751-be21-afa4f877a4f5;b10d95dc-e74e-4e03-be0b-37d2327f9086"
export REDIR_URL=https://example.com
export ALTER_ID=64

# ---

mkdir -p ./log
mkdir -p ./client
touch ./log/v2-access.log
touch ./log/v2-error.log
touch ./log/nginx-access.log
touch ./log/nginx-error.log
chmod -R 755 ./client
chmod -R 755 ./log
chmod 755 ./control.sh
chmod 755 ./bbr.sh

# ---

/bin/bash ./control.sh