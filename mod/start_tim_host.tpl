#!/bin/sh
# Connect to running docker container -> Identify container first
# docker exec -it "c34330491db6" /bin/bash

CONTAINER=CONTAINERNAME

# Check if the container is already running.
# If yes, exit.
if [ `docker ps | grep ${CONTAINER}$ | wc -l` == 1 ]
then
    echo "*** FATAL: Container ${CONTAINER} is alrady active. Exiting!"
    exit 1
fi

# Check if we already have a stopped container.
# In case that one exists, start it.
if [ `docker ps -a | grep ${CONTAINER}$ | wc -l` == 1 ]
then
    # Docker container exists - start it.
    docker start ${CONTAINER}

else
    # Start actual TIM container
    docker run --name ${CONTAINER} -d \
	   -v ~/docker/${CONTAINER}/config:/opt/CA/APM/tim/config \
	   -v ~/docker/${CONTAINER}/logs:/opt/CA/APM/tim/logs \
	   -v ~/docker/${CONTAINER}/exchange:/root/host_dir \
	   --net=host \
	   IMAGENAME
fi

# Send a message out
echo "======================================================================"
echo "A data-exchange directory has been created:"
echo "* On the Docker-Host: ~/docker/${CONTAINER}/exchange"
echo "* In the $CONTAINER container: /root/host_dir"
