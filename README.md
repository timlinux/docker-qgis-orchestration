# QGIS Mapserver Demo Orchestration

Orchestration scripts for running QGIS demo server.

To use you need to have docker installed on any linux host. You
need a minimum of docker 1.0.0

# Scripts

A number of scripts are provided:

## build

*Useage:*

```bash

./build.sh [github_user|github_organisation]

```

This will build all the docker images.  You can optionally pass a parameter
which is an alternate organisation or user name which will let you build
against your forks of the official QGIS repos. e.g.

**Example:**

```bash
./build.sh [github organisation or user name]
```
  
During the build process, these docker images will be built:

  * **kartoza/qgis-btsync**: This runs a btsync server that will
    contain the GIS. The btsync 
    peer hosted here is read only. To push data to the server, you need to 
    have the write token (ask Tim or Richard for it if needed). The 
    container run from this image will be a long running daemon. 
  * **kartoza/qgis-server**: This runs a QGIS mapserver container 
    which has apache, mod_fcgi and QGIS Mapserver installed in it.
  * **kartoza/qgis-postgis**: This runs a postgis instance.
  * **kartoza/qgis-desktop**: This runs a dockerised version of QGIS desktop 
    and can be used for testing and loading postgis data in a local development 
    environment.
  
## deploy

*Usage:*

```
./deploy.sh <organisation|client_id> [storage_type]
```

This script will launch containers for all the long running daemons defined for
a client. Each container will be named with client prefix followed by a hypen
and then the base name of the image. 

*Arguments:*

* **organisation|client_id** : The first argument should be a client name or id
  comprised of only letters and numbers. Do not use hyphens or other characters
  than those specified in this regex: ``[A-Za-z0-9]*``.

* **storage_type** : The storage type used for the client's storage volume. The 
  following storage types are supported:
  * **btsync**  : This is the default storage container type. Uses a btsync read
  only key. Any user with a RW key may place data into the btsync share which will
  make its way into the storage container. Time to arrive in the storage container
  depends on network latency and file size. 
  * **local** : A non-synchronised local storage area. This is mainly useful for
  testing or where you have direct access to the host's file system.

On deployment, the following host volumes will be created:

* `/var/lib/kartoza/<client_id>-web` : storage area for web content and maps to
  be published via QGIS. This will be mounted as the storage volume when using
  **btsync** and **local** storage and within containers will be mounted as `/web`.
* `/var/lib/kartoza/<client_id>-pg` : storage area for the postgis cluster.
  This will be mounted as the storage volume when using the **postgis** container 
  and is visible within the container as `/var/lib/postgresql`.

*Example:*

```bash
./deploy.sh channel local


Running storage container
=====================================
channel-storage is not running
37b032be7fead7835ba829a6717057eb41cad6f7ac3a57af9a2ed9029a0db7a9

Running postgis container
=====================================
channel-postgis is not running
e18b1292956bef69840add0eed14b3a7feeb1ddf96fba7b8c7ecbd81fce77b90

Running QGIS Server container
=====================================
channel-qgis-server is not running
2a0606fe7c4a3591b0a684543f77faebdfe79019be28763f61dffb3662b1cda5

Containers running for client: channel
==========================================
2a0606fe7c4a        kartoza/qgis-server:latest   /bin/sh -c 'apachect   1 seconds ago       Up Less than a second   0.0.0.0:8198->80/tcp   channel-qgis-server                                   
e18b1292956b        kartoza/postgis:latest       /bin/sh -c /start-po   1 seconds ago       Up Less than a second   5432/tcp               channel-postgis,channel-qgis-server/channel-postgis   
37b032be7fea        ubuntu:14.04                 /bin/bash              2 seconds ago       Up 1 seconds                                   channel-qgis-server/channel-storage,channel-storage  
```

## run

*Usage:*

```bash
./run.sh
```

This script will run QGIS Desktop as a containerised app. The storage container
(see above) will be mounted into it as `/web`. The active user's home directory
will be mounted as `/home/<user>` within the container. This command requires
X Windows as the QGIS Desktop application will be forwarded over X to the 
host's display client. The main intention here is that you can prepare projects
using PostGIS datasources directly within the containerised environment (saving
the project to `/web` in order to publish it via QGIS server).

**Note:** In order to forward the display to the host desktop, we use `xhost +`
while running the aplication, and then `xhost -` afterwards. This may be a cause
of insecurity (because any display server can place a window onto your desktop) 
or interfere with other display related settings on your desktop. Check with
your sysadmin if in doubt.


## functions  

There is an additional script called `functions.sh` which contains common
functions shared by all scripts.


# General usage

The orchestration scripts provided here will build against docker recipes
hosted in GitHub - there is no need to check them all out individually. So 
to use all you need to do is (on your host):


```
git clone https://github.com/kartoza/docker-qgis-orchestration.git
cd docker-qgis-orchestration
./build.sh
./deploy.sh
```

# Reverse proxy

Lastly you will probably want to set up a reverse proxy pointing to your QGIS
Mapserver container (our orchestration scripts publish on 8198 by default).
Here is a sample configuration for nginx:

```
upstream maps.kartoza { server localhost:8198;}
 
server {
  listen      80;
  server_name maps.kartoza.com;
  location    / {
    proxy_pass  http://maps.kartoza;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-For $remote_addr;
  }
}

```


--------

Tim Sutton and Richard Duivenvoorde, August 2014

