FROM centos:latest
LABEL maintainer="Asdrubal Gonzalez"
ENV container=docker

ENV pip_packages "ansible"
ENV remi_repo "http://rpms.remirepo.net/enterprise/remi-release-7.rpm"
ENV nginx_packages "nginx"
ENV php_packages "php php-cli.x86_64 php-xml.x86_64 php-gd.x86_64 php-pear.noarch php-mcrypt.x86_64 php-mbstring.x86_64 php-pdo.x86_64 php-soap.x86_64 php-process.x86_64 php-pecl-zip.x86_64"

# Install systemd -- See https://hub.docker.com/_/centos/
RUN yum -y update; yum clean all; \
(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

# Install requirements.
RUN yum makecache fast \
&& yum -y install deltarpm epel-release initscripts \
&& yum -y install $remi_repo \
&& yum -y --enablerepo=remi,remi-php72 install htop\
&& yum -y update \
&& yum -y install \
sudo \
which \
python-pip \
&& yum -y install httpd mod_ssl openssl $php_packages \
&& yum clean all
# && yum --enablerepo=remi,remi-php72

# Install Ansible via Pip.
RUN pip install --upgrade pip
RUN pip install $pip_packages

# Disable requiretty.
RUN sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/' /etc/sudoers

#changing the ports of apache
RUN sed -i '42s/80/8080/' /etc/httpd/conf/httpd.conf \
&& sed -i '5s/443/7443/' /etc/httpd/conf.d/ssl.conf

# RUN service httpd restart
CMD [/usr/sbin/apache2ctl -D FOREGROUND]

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts

VOLUME ["/sys/fs/cgroup"]
CMD ["/usr/lib/systemd/systemd"]

EXPOSE 8080
EXPOSE 7443

ADD www /var/www/site
ADD apache-config.conf /etc/httpd/conf.d/000-default.conf