#!/bin/sh
# Connect to running docker container -> Identify container first
# docker exec -it "c34330491db6" /bin/bash

CONTAINER=CONTAINERNAME
# Note, the Docker container will exclusively use this Network interface !!!
HOST_DEV=HOSTDEV

# Checking if the configured Host Device to import into the TIM
# exists. If not - exit.
ifconfig ${HOST_DEV} &> /dev/null
errlvl=$?

if [ $errlvl -gt 0 ]
then
    echo "*** Network interface ${HOST_DEV} not found. Exiting!"
    exit $errlvl
fi


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
	   -p PORTHTTP8:8080 \
	   -p PORTHTTPS:443 \
	   -p PORTHTTP1:81 \
	   -p PORTHTTP:80 \
	   IMAGENAME
fi

# Wait 5 seconds for container to be usable bi IP stuff.
sleep 1

# Create temp directory to store the netns
sudo mkdir -p /var/run/netns

# Conpute the Docker Container ID
PID=$(docker inspect -f '{{.State.Pid}}' ${CONTAINER})

# Link to ID
sudo ln -s /proc/${PID}/ns/net /var/run/netns/${PID}

# Move the ethernet device into the container. Leave out 
# the 'name $HOST_DEV' bit to use an automatically assigned name in 
# the container
sudo ip link set ${HOST_DEV} netns ${PID} name ${HOST_DEV}

# and bring it up.
sudo ip netns exec ${PID} ip link set ${HOST_DEV} up

# Set promiscuous mode
sudo ip netns exec ${PID} ip link set ${HOST_DEV} promisc on

# Delete netns link to prevent stale namespaces when the docker
# container is stopped
sudo rm -f /var/run/netns/${PID}

# Send a message out
echo "======================================================================"
echo "A data-exchange directory has been created:"
echo "* On the Docker-Host: ~/docker/${CONTAINER}/exchange"
echo "* In the $CONTAINER container: /root/host_dir"
