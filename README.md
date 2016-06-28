# docker-TimImage_builder rel1.0-21

**Purpose**: Creates configuration files to create CA APM TIM docker Images and Containers  
  _by J. Mertin -- joerg.mertin(-AT-)ca.com_

## Description
The docker-TimImage_builder permits to install a TIM from version 9.6.x to
10.x practically on any Docker Server in a matter of minutes.

## Short description
The docker-TimImage_builder permits to install a CA APM TIM from version
9.6.x to 10.x practically on any Docker Server in a matter of minutes.
The build-script provides a first-configuration UI, and will also
create a script to start/stop the TIM docker container later with all
pre-configured data inside.

## APM version
So far - the docker-builder has been tested with TIM from version 9.6
up to 10.3.

## Installation Instructions

#### Prerequisites
- Docker-Server for hosting the container
- Dedicated network interface for the SPAN Provider. This Network
  interface will be dedicated to the TIM Container - and cannot be
  accessed by any other applicaiton, container after the TIM container
  is activated!
- Copy of the TIM installation files for RedHat/CenOS. Download from
  CA Support site
- The ca-eula.en.txt file needs to be edited and content accepted!

#### Dependencies
- None - the container setup will provide all necessary dependencies


#### Configuration
The configuration section has been set forward, as it is done prior
the docker file creation, hence before the container is created and/or
started.  The `TIMImage_builder.sh` script, when started without
configuration file as argument will interactively ask the information
required to run the TIM inside the docker environment. The regular TIM
configuration will not be impacted by this.


#### Installation

First of all you need to get a copy of the repository or simply clone
it. Get the link - and clone the repository:

`~# git clone https://github.com/CA-APM/docker-TimImage_builder.git`

The TIM Version the container will run is defined by the files
provided in the timXX.x directory. The maker of the Docker-Image needs
to download the TIM files from CA Support site (Download section),
untar the version for CentOS/RedHat 6.x and place the obtained files
into the appropriate version directory, example "tim10.1":

```
admin@antigone:~/docker/docker-TimImage_builder$ ls -l tim10.2/*  
-rwx------ 1 admin adm     1698 Mar 17 01:43 tim10.2/CA-APM-TIM-public_key.txt  
-rw-r--r-- 1 admin adm   352952 Jun 15 10:40 tim10.2/ca-eula.en.txt  
-rwxr-xr-x 1 admin adm 11470907 Mar 16 12:58 tim10.2/timInstall.bin
```

You can have more than one version in the base directory. Make sure to
edit the ca-eula.en.txt file and set the Eula Acceptance to
**CA-EULA=reject** or the installation of the TIM will fail.

This docker-TimImage_builder provides a CLI UI to choose the initial
setup of the TIM docker build, letting the user choose between
different versions, set the name of the image-build and the container
name. In case of the secured network mode, will set the ports that
will be exposed. By default - the TIM docker will use the internal
ports 80, 81, 8080 and 8433, which eventually need to be remapped.  In
"host" network mode, the current network configuration of the host
will be made available to the docker container. This will be very
practical in case one wants to monitor a webserver running on the same
hardware.  
_Note: in case you want to access the container using https, you will
have to provide a valid private key and certificate. Else the server
will refuse secured accesses._


#### For Interactive mode, just call:  
`~# ./TIMImage_builder.sh`

_Note: Every interactive mode will create a configuration file in the
"cfgs" directory. You can then use it for Automated mode._

#### Automated mode, provide a configuration file as argument.  
`~# ./TIMImage_builder.sh cfgs/tim9.7.0.cfg`

In both cases, the script will show the current settings and ask for
confirmation of the image to be built.

```
>>> Options for this Docker Image Build
===============================================================
TIM Version:            tim10.2
TIM Workers:            2
Image name:             caapm/tim10.2
Exposed ports:          8080 8443 81 80
Network mode:           secured
Container Name:         tim10.2
Host SPAN Int.:         dummy0
Port 80 mapped to:      80
Port 81 mapped to:      81
Port 8080 mapped to:    8080
Port 8443 mapped to:    8443

===============================================================
>>> Proceed [y/n]:
```

The Docker-Builder will then create some files that are used to create
the actual docker image, and provide a start script to start the
Container, and a script to enter the container.

The TIM software will be installed in unattended mode using the defaults
as provided by the **CA_AUTOMATION**.


#### Usage Instructions

Every time the `TIMImage_builder.sh` is executed, a CentOS 6.8 OS
image is built, a complete RPM update is performed prior TIM
installation providing the most up to date and secure environment for
the TIM process to run in.

_Note: A cron-job is also running inside the TIM Container to keep
the RPM packages up to date and security fixes applied over time!_

The main issue for the TIM to actually run inside a Docker
environment, is to provide apmpacket the data-flow the TIM workers are
supposed to monitor. Docker however has been designed to share
resources. This is the reason the Admin starting the TIM Container
will have insert the SPAN Device to the Docker-Container, or use the
generated `start_tim.sh` shell script so the container can directly
"hijack" the defined SPAN interfaces on the running host.

The `TIMImage_builder.sh` execution will create 2 scripts:

- **start_tim9.7.0.sh**: This script will start the docker container as
  per the name.  
  _Note:  the configured SPAN interface will be hijacked
  from the docker host and made exclusively available to the inside of
  the TIM container._ 
  * In case the container does not yet exist, it will be built and
    started.
  * In case it already exists, the existing instance will be started
    and networking setup according to request

- **tim9.7.0_shell.sh**: This one will drop you to a shell directly inside
  the running container
  
The TIM Container will create various directories under the user's home
 invoking the start of the container:

| Inside the container | In the user's home directory |
|----------------------|------------------------------|
| /opt/CA/APM/tim/config | ~/docker/{CONTAINER}/config |
| /opt/CA/APM/tim/logs | ~/docker/{CONTAINER}/logs |
| /root/host_dir | ~/docker/{CONTAINER}/exchange |

These directories are persistent. This means that in case you create a
new TIM container with the same release, this directory's content will
not be overwritten.

If you want to upgrade the TIM while keeping the current
configuration, all you need to do is create the new TIM image and
adapt the "{ONTAINER}" to reflect the name of the next running
instance.



## Limitations
* Currently, the container-start script using the secured network mode
  will only work on a Linux Docker Server - as the syntax used to
  Hijack the SPAN Interface is specific to each OS.

* In case the "secured" network mode is used, the network interface
  used for SPAN Port is exclusively assigned to a docker container and
  cannot be used by any other process/docker container.

## Debugging and Troubleshooting
Troubleshooting needs to be done as on a regular TIM.  
_Note: for entering the TIM Container, use the provided `tim9.7.0_shell.sh` script._


## Security

The TIM Container provides no active security. However, during
installation, the latest fixes for underlying OS are applied. At the
same time - a cron-job is installed to update the underlying OS on a
regular base.  
In case this behavior is not wanted, or the container has no access to
regular centos repositories, please remove the `yum.cron` file, and
restart crond.  
```
[root@antigone cron.d]# rm -f /etc/cron.d/yum.cron 
[root@antigone cron.d]# service crond reload
```  
_Note: removing crond alltogether can be done but is not advised as
it also takes care of all the daily/weekly/monthly logfile
maintenante._


## Legal notice: binaries not included
As CA APM TIM is commercial software I cannot provide fully-built
images. Also this project cannot provide the binaries for building the
images. But the addition of the binaries is easy.


## License
This field pack is provided under the [Eclipse Public License, Version
1.0](https://github.com/CA-APM/docker-TimImage_builder/blob/master/LICENSE).

## Support
This document and associated tools are made available from CA
Technologies as examples and provided at no charge as a courtesy to
the CA APM Community at large. This resource may require modification
for use in your environment. However, please note that this resource
is not supported by CA Technologies, and inclusion in this site should
not be construed to be an endorsement or recommendation by CA
Technologies. These utilities are not covered by the CA Technologies
software license agreement and there is no explicit or implied
warranty from CA Technologies. They can be used and distributed freely
amongst the CA APM Community, but not sold. As such, they are
unsupported software, provided as is without warranty of any kind,
express or implied, including but not limited to warranties of
merchantability and fitness for a particular purpose. CA Technologies
does not warrant that this resource will meet your requirements or
that the operation of the resource will be uninterrupted or error free
or that any defects will be corrected. The use of this resource
implies that you understand and agree to the terms listed herein.

Although these utilities are unsupported, please let us know if you
have any problems or questions by adding a comment to the CA APM
Community Site area where the resource is located, so that the
Author(s) may attempt to address the issue or question.

Unless explicitly stated otherwise this field pack is only supported
on the same platforms as the regular APM CEM TIM. See [APM
Compatibility Guide](http://www.ca.com/us/support/ca-support-online/product-content/status/compatibility-matrix/application-performance-management-compatibility-guide.aspx).


### Support URL
https://github.com/CA-APM/docker-TimImage_builder/issues


## Categories
Packaged Applications Monitoring Virtualization/Containers


