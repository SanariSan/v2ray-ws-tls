Set of docker containers to provide easy setup of nginx + v2ray (vmess-ws-tls) proxy on vps.

At the moment there is start script that will lead to working setup.

Before launching it please **install docker** and **change values in start.sh** to your desired.

---

If you want to generate UUIDs from recognizable strings, go to `about:blank` in your browser and paste code from `generate-uuids.js`.

First create private key (normal random uuid), write it down, then put in some words as keywords. Script will output matching UUIDs for each word. You can generate same UUIDs later from same words using private key.

ALL OF THAT IS OPTIONAL AND FOR CONVENIENCE ONLY.

---

TODO:

- Autoremove logs
- Autostart docker on boot
