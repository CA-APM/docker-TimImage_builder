# latest installs CentOS 6.8, adds some RPM's, prepares for TIM
# installation, installs TIM the upgrades Image to latest release.
# Will activate 4 TIM Workers
# apache is actually the process which will keep the container running.
# Added Cron-Job to keep the system updated through yum (RedHat 6.x
# release - point releases will be added)

FROM centos:6.8
MAINTAINER Joerg Mertin

RUN yum -y install centos-release mod_ssl compat-libstdc++-33 pexpect unzip httpd nspr libpcap gdb mod_wsgi java-1.7.0-openjdk policycoreutils-python nano e2fsprogs-libs file lsof pciutils zip file cronie tar && yum -y update && yum clean all

# This is to have the TIM package extract itself in unattended mode.
ADD CA_AUTOMATION /etc/CA_AUTOMATION

# Add Public key
ADD TIMVER/CA-APM-TIM-public_key.txt /root/CA-APM-TIM-public_key.txt

# Add and Modify the Eula file
ADD TIMVER/ca-eula.en.txt /root/ca-eula.en.txt
RUN sed -i 's/6.8/6.5/g' /etc/centos-release

# Add TIM Binary
ADD TIMVER/timInstall.bin /root/timInstall.bin

# Change Working directory and execute the timInstall.bin to extract
# the RPM installer script and RPM files
WORKDIR /root
RUN ./timInstall.bin

# Fix bug in the installer script
RUN sed -i s'/--prefix= //g' /root/timInstallRPM.sh

# Actually installing the RPM's. Note there is a bug anyway in it.
# As it is not fatal, skipping it.
RUN /root/timInstallRPM.sh

# Limit the number of TIM workers to be started
RUN sed -i 's/^#workers N/workers WORKER/g' /opt/CA/APM/tim/config/balancer.cnf && sed -i 's/6.5/6.8/g' /etc/centos-release

# Added cronjob for yum update / to keep the image updated (OS Security fixes)
ADD mod/yum.cron /etc/cron.d

# Add the program that will actually be run
ADD mod/clean_rc.sh /clean_rc.sh 
RUN chmod +x /clean_rc.sh  
RUN /clean_rc.sh 

# Remove the TIM Software
RUN rm -f /root/timInstall.bin /root/CA-APM-TIM-public_key.txt /root/ca-eula.en.txt

# Take a backup of the Logs and Configuration directory
RUN tar zcf /root/initial_TIM_config_logs.tar.gz /opt/CA/APM/tim/config /opt/CA/APM/tim/logs
ADD mod/pre-tim.init /etc/init.d/pre-tim
RUN /sbin/chkconfig --add pre-tim

EXPOSE EXPOSEDPORTS

ENTRYPOINT ["/sbin/init"]
