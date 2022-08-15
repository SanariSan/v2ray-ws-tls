# V2RAY-WS-VMESS + ssl

## Table of Contents

- [About](#about)
- [Getting Started](#getting_started)
- [Usage](#usage)

## About <a name = "about"></a>

Set of 3 docker containers + control script to provide easy setup of nginx + v2ray (vmess-ws-tls) proxy on vps (tested on UBUNTU only).

Server will redirect all requests to your domain to the site you like, except websocket requests to one path specified in config.

Repo presents:

- [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) container which will receive all requests on your vps 80/443 ports
- [nginx-proxy-acme](https://github.com/nginx-proxy/acme-companion) container which is in charge of issuing certificates for any deployed container + auto renewing them
- nginx-v2ray container which is the main deal here

Note that you should use **start.sh**.

Run **start.sh**, not other .sh scripts directly.

---

## Getting Started <a name = "getting_started"></a>

### Prerequisites

1. You should own a domain, which has **A** record pointing to your vps ip (todo: add info how to do it)
2. On your vps with Ubuntu system install git and docker (commands from official site, pick by your own if need) [docker](https://docs.docker.com/engine/install/ubuntu/) | [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

```
sudo apt install git-all

sudo apt remove docker docker-engine docker.io containerd runc
sudo apt update
sudo apt install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

---

### Installing

1. Clone this repo `git clone https://github.com/SanariSan/v2ray-ws-tls`
2. Cd into directory `cd v2ray-ws-tls`
3. Make script executable `chmod 755 ./start.sh`
4. Now replace values in `start.sh` with your own, use **nano** or other editor `nano ./start.sh`
5. Run script with `/bin/bash ./start.sh`

If placing several UUIDs, then split each with **;** as shown in the example config

---

## Usage <a name = "usage"></a>

0. Main menu
1. Press **4)** and check if all values filled correctly

![Main menu](https://github.com/SanariSan/v2ray-ws-tls/blob/master/assets/general.png?raw=true)

2. Proceed to **1)** section (containers) and run test certificate request (it's dry run, no cert generated)
3. If that went fine start all the containers
4. Make sure all containers up and running, you will see **green circles**

![Containers menu](https://github.com/SanariSan/v2ray-ws-tls/blob/master/assets/containers_.png?raw=true)

5. Get back to main menu and press **5)** to display settings for connecting to your server. Content of this file should be moved to your home pc v2ray. The file itself located in `./client` directory near.
6. Check out Logs in section **3)** if need to.

![Logs menu](https://github.com/SanariSan/v2ray-ws-tls/blob/master/assets/logs.png?raw=true)

7. If you wish to enable autostart on boot proceed to **2)** section.

![Autostart menu](https://github.com/SanariSan/v2ray-ws-tls/blob/master/assets/autostart.png?raw=true)

8. To enable BBR optimisation proceed to option **6)**.

---

#### THIS INFO IS OPTIONAL AND FOR CONVENIENCE ONLY

Use if you want to generate UUIDs from recognizable strings, for example "user1", "myid123", etc.

1. First create private key (normal random uuid), for example [here](https://www.uuidgenerator.net/), write it down.
2. Go to `about:blank` in your browser (for example) and paste code from `generate-uuids.js`.
3. Put generated UUID as private key, then enter desired words as keywords. Script will output matching UUIDs for each word. You can generate same UUIDs later from same words using **private key**, don't lose it.
