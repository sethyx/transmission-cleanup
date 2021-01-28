# transmission-cleanup

![GitHub top language](https://img.shields.io/github/languages/top/sethyx/transmission-cleanup)
[![Docker Build](https://img.shields.io/docker/cloud/build/sethyx/transmission-cleanup.svg)](https://hub.docker.com/repository/docker/sethyx/transmission-cleanup)
[![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/sethyx/transmission-cleanup)](https://hub.docker.com/repository/docker/sethyx/transmission-cleanup)
![](https://img.shields.io/docker/pulls/sethyx/transmission-cleanup "Total docker pulls")

A simple script to remove torrents from Transmission that have been seeding for a long time.

Please respect the torrent etiquette and don't set the seeding threshold to a low value. You can setup your Transmission to mark torrents as finished once they reached the preferred ratio (1+:1). This script can help removing torrents which are not being leeched anymore and therefore probably won't ever get marked as finished.

## Supported tags and Dockerfile links

-	[`latest` (*Dockerfile*)](https://github.com/sethyx/transmission-cleanup/blob/main/Dockerfile)

## How it works

- Connects to Transmission RPC to list torrents and get torrent details (supports user+password auth).
- If a torrent finished downloading and has been seeding for more than the defined threshold, marks it as completed.
- If a torrent is marked as completed, removes the torrent.
- Runs periodically.

## How to use

### docker-compose (recommended)

```
version: '3.4'
services:
  transmission-cleanup:
    image: sethyx/transmission-cleanup:latest
    container_name: transmission-cleanup
    environment:
      - "TRANSMISSION_RPC=host:9091"
      - "TRANSMISSION_RPC_AUTH=true" # optional, set to true if using auth
      - "TRANSMISSION_RPC_USER=youruser" # optional
      - "TRANSMISSION_RPC_PASSWORD=yourpassword" # optional
      - "RUN_INTERVAL=12" # hours
      - "SEEDING_THRESHOLD=7" # days
```

### docker cli

```bash
docker run -d \
    -e "TRANSMISSION_RPC=host:9091" \
    -e "TRANSMISSION_RPC_AUTH=true" \
    -e "TRANSMISSION_RPC_USER=youruser" \
    -e "TRANSMISSION_RPC_PASSWORD=yourpassword" \
    -e "RUN_INTERVAL=12" \
    -e "SEEDING_THRESHOLD=7" \
    transmission-cleanup
```

## Parameters

Container images are configured using parameters passed at runtime (such as those above).

| Parameter | Function |
| :----: | --- |
| `-e "TRANSMISSION_RPC=host:9091"` | host and port of Transmission RPC, the default port is 9091 |
| `-e "TRANSMISSION_RPC_AUTH=true"` | optional, set this to true if your Transmission RPC expects a user and password for authentication |
| `-e "TRANSMISSION_RPC_USER=youruser"` | optional, username, if you're using auth |
| `-e "TRANSMISSION_RPC_PASSWORD=youruser"` | optional, password, if you're using auth |
| `-e "RUN_INTERVAL=12"` | interval to check torrents (hours) |
| `-e "SEEDING_THRESHOLD=7"` | seeding time (days) that should be considered finished - once reached, the torrent will be marked as finished and then removed in the next run |


## Logging

Everything goes to `stdout`.
