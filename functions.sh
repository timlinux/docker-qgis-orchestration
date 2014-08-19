#!/bin/bash

BASE_DIR=/var/lib/kartoza-cloud

STORAGE_CONTAINER=storage

BTSYNC_GIT_REPO=docker-qgis-btsync
BTSYNC_IMAGE=qgis-btsync

POSTGIS_GIT_REPO=docker-postgis
POSTGIS_IMAGE=postgis
POSTGIS_CONTAINER=postgis

QGIS_SERVER_GIT_REPO=docker-qgis-server
QGIS_SERVER_IMAGE=qgis-server
QGIS_SERVER_CONTAINER=qgis-server

QGIS_DESKTOP_GIT_REPO=docker-qgis-desktop
QGIS_DESKTOP_IMAGE=qgis-desktop
QGIS_DESKTOP_CONTAINER=qgis-desktop

function make_directories {

    CLIENT_ID=$1

    # Ensure the base dir exists
    if [ ! -d ${BASE_DIR} ]
    then
        sudo mkdir -p ${BASE_DIR}
        OWNER=${USER}
        sudo chown ${OWNER}.${OWNER} ${BASE_DIR}
    fi
    # Create a directory for persisting the
    # clients web / gis resources
    WEB_DIR=${BASE_DIR}/${CLIENT_ID}-web
    if [ ! -d ${WEB_DIR} ]
    then
        mkdir -p ${WEB_DIR}
    fi

    # Create a directory for persisting the postgresql
    # database cluster
    PG_DIR=${BASE_DIR}/${CLIENT_ID}-pg
    if [ ! -d ${PG_DIR} ]
    then
        mkdir -p ${PG_DIR}
        chmod a+w ${PG_DIR}
    fi

}

function kill_container {
    # kill a single named container
    # host based volumes will be preserved
    NAME=$1

    if docker ps -a | grep ${NAME} > /dev/null
    then
        echo "Killing ${NAME}"
        docker kill ${NAME}
        docker rm ${NAME}
    else
        echo "${NAME} is not running"
    fi

}

function kill_client_containers {
    # kill all containers for a given client / customer
    # Call this function with a unique client ID which 
    # will be prefixed to the container name
    # host based volumes will be preserved
    CLIENT_ID=$1
    NAMES=`docker ps -a |grep -v "Exit" | grep -o "[a-zA-Z\.\-]*[ ]*$" | sed 's/ //g' | grep -v "NAMES" | grep "^${CLIENT_ID}-"`
    for CONTAINER in $NAMES
    do 
        echo "Killing ${CONTAINER}"
        docker kill ${CONTAINER} > /dev/null
        docker rm ${CONTAINER} > /dev/null
    done
    echo "Containers left running with ${CLIENT_ID} in their names:"
    docker ps -a | grep ${CLIENT_ID}
}

function purge {
    # Remove all client data in the storage path on host
    # CAUTION: when purging client data will be lost!
    CLIENT_ID=$1
    sudo rm -rf ${BASE_DIR}/${CLIENT_ID}-*
    ls ${BASE_DIR}
}

function get_next_port {

    # Get next available port on the server
    # it stores the last used port in LASTPORT.txt
    # If that file does not exist then it will be created
    # and a default starting port of 30000 will be used
    
    # Useage:
    #
    # PORT=$(get_next_port)
    # echo $PORT    

    # Ensure the LASTPORT.txt exists
    PORT_COUNTER=LASTPORT.txt
    if [ ! -f LASTPORT.txt ]
    then
        echo "30000" > LASTPORT.txt
    fi
    LAST=`cat ${PORT_COUNTER}`; echo "$LAST + 1" | bc > ${PORT_COUNTER}
    cat ${PORT_COUNTER}

}

function build_btsync_image {

    echo ""
    echo "Building btsync image"
    echo "====================================="

    docker build -t kartoza/${BTSYNC_IMAGE} git://github.com/${ORG}/${BTSYNC_GIT_REPO}.git

}

function run_btsync_container {

    # Call this function with a unique client ID which 
    # will be prefixed to the container name
    CLIENT_ID=$1
    echo "" >> {CLIENT_ID}.log
    echo "Running btsync container" >> {CLIENT_ID}.log
    echo "=====================================" >> {CLIENT_ID}.log

    WEB_DIR=${BASE_DIR}/${CLIENT_ID}-web

    make_directories ${CLIENT_ID}

    kill_container ${CLIENT_ID}-${STORAGE_CONTAINER}

    # TODO figure out how to softcode these ports
    # They need to be sofcoded in the btsync.conf file too
    docker run --name="${CLIENT_ID}-${STORAGE_CONTAINER}" \
        -v ${WEB_DIR}:/web \
        -p 8888:8888 \
        -p 55555:55555 \
        -d -t kartoza/${BTSYNC_IMAGE}

}

function run_storage_container {

    # Call this function with a unique client ID which 
    # will be prefixed to the container name
    CLIENT_ID=$1

    echo "" >> {CLIENT_ID}.log
    echo "Running storage container" >> {CLIENT_ID}.log
    echo "=====================================" >> {CLIENT_ID}.log

    # This is an alternative to using btsync - if you want to
    # simply share a volume from the host into the orchestrated
    # container array - it will act and look like btsync to 
    # the other containers but will simply provide data from 
    # the host without running btsync. This is useful in cases
    # where the host is already running btsync.

    WEB_DIR=${BASE_DIR}/${CLIENT_ID}-web

    make_directories ${CLIENT_ID}

    kill_container ${CLIENT_ID}-${STORAGE_CONTAINER}

    # Simply run bash in daemon mode to consume no resources
    docker run --name="${CLIENT_ID}-${STORAGE_CONTAINER}" \
        -v ${WEB_DIR}:/web \
        -d -t ubuntu:latest /bin/bash

}

function build_postgis_image {

    echo ""
    echo "Building postgis image"
    echo "====================================="

    docker build -t kartoza/${POSTGIS_IMAGE} git://github.com/${ORG}/${POSTGIS_GIT_REPO}.git

}

function run_postgis_container {

    # Call this function with a unique client ID which 
    # will be prefixed to the container name
    CLIENT_ID=$1

    echo "" >> {CLIENT_ID}.log
    echo "Running postgis container" >> {CLIENT_ID}.log
    echo "=====================================" >> {CLIENT_ID}.log

    PG_DIR=${BASE_DIR}/${CLIENT_ID}-pg


    make_directories ${CLIENT_ID}

    kill_container ${CLIENT_ID}-${POSTGIS_CONTAINER}

    PORT=$(get_next_port)
    docker run --name="${CLIENT_ID}-${POSTGIS_CONTAINER}" \
        -p ${PORT}:5432 \
        -v ${PG_DIR}:/var/lib/postgresql \
        -d -t kartoza/${POSTGIS_IMAGE}
    echo "Database forwarded to host on port ${PORT}" >> {CLIENT_ID}.log

}

function build_qgis_server_image {

    echo "" >> {CLIENT_ID}.log
    echo "Building QGIS Server Image" >> {CLIENT_ID}.log
    echo "=====================================" >> {CLIENT_ID}.log

    docker build -t kartoza/${QGIS_SERVER_IMAGE} git://github.com/${ORG}/${QGIS_SERVER_GIT_REPO}.git

}

function run_qgis_server_container {

    # Call this function with a unique client ID which 
    # will be prefixed to the container name
    CLIENT_ID=$1

    echo "" >> {CLIENT_ID}.log
    echo "Running QGIS Server container" >> {CLIENT_ID}.log
    echo "=====================================" >> {CLIENT_ID}.log

    kill_container ${CLIENT_ID}-${QGIS_SERVER_CONTAINER}

    make_directories ${CLIENT_ID}

    # We mount STORAGE volumes which provides
    # /web into this container
    # and we link POSTGIS and STORAGE
    # to establish a dependency on them
    # when bringing this container up
    # The posgis link wil add a useful
    # entry to /etc/hosts that should be used
    # referencing postgis layers
    PORT=$(get_next_port)
    docker run --name="${CLIENT_ID}-${QGIS_SERVER_CONTAINER}" \
        --volumes-from ${CLIENT_ID}-${STORAGE_CONTAINER} \
        --link=${CLIENT_ID}-${POSTGIS_CONTAINER}:${CLIENT_ID}-${POSTGIS_CONTAINER} \
	--link=${CLIENT_ID}-${STORAGE_CONTAINER}:${CLIENT_ID}-${STORAGE_CONTAINER} \
        -p ${PORT}:80 \
        -d -t kartoza/${QGIS_SERVER_IMAGE}
    echo "Apache forwarded to host on port ${PORT}" >> {CLIENT_ID}.log

    
}

function build_qgis_desktop_image {

    echo ""
    echo "Building QGIS Desktop Image"
    echo "====================================="

    docker build -t kartoza/${QGIS_DESKTOP_IMAGE} git://github.com/${ORG}/${QGIS_DESKTOP_GIT_REPO}.git

}

function run_qgis_desktop_container {

    echo "" >> {CLIENT_ID}.log
    echo "Running QGIS Desktop container"
    echo "====================================="

    if test -z "$1"
    then
        echo "Error: you mush specify the client id as parameter"
        return
    fi
    # Call this function with a unique client ID which 
    # will be prefixed to the container name
    CLIENT_ID=$1

    xhost +
    # Users home is mounted as home
    # --rm will remove the container as soon as it ends

    # We mount STORAGE volumes which provides
    # /web into this container
    # and we link POSTGIS and STORAGE
    # to establish a dependency on them
    # when bringing this container up
    # The posgis link wil add a useful
    # entry to/etc/hosts that should be used
    # referencing postgis layers

    docker run --rm --name="${CLIENT_ID}-${QGIS_DESKTOP_CONTAINER}" \
	-i -t \
        --volumes-from ${CLIENT_ID}-${STORAGE_CONTAINER} \
	-v ${HOME}:/home/${USER} \
        --link=${CLIENT_ID}-${POSTGIS_CONTAINER}:${CLIENT_ID}-${POSTGIS_CONTAINER} \
	--link=${CLIENT_ID}-${STORAGE_CONTAINER}:${CLIENT_ID}-${STORAGE_CONTAINER} \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-e DISPLAY=unix$DISPLAY \
	kartoza/${QGIS_DESKTOP_IMAGE}:latest 
    xhost -
}
