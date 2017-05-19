FROM centos:7
MAINTAINER kishitat

#user add
RUN useradd admin

#install php,httpd,mysql
RUN yum install -y epel-release && \
    rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm && \
    yum install -y --enablerepo=remi,remi-php71 php php-devel php-mbstring php-pdo php-gd httpd mariadb mariadb-server php-mysql wget

#modify php config
RUN sed -i -e "s@;date.timezone =@date.timezone = \"Asia/Tokyo\"@" /etc/php.ini

#edit httpd setting
RUN mkdir -p /opt/httpd/logs && \
    sed -i -e "s/Listen 80/Listen 8080/" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s@ErrorLog .*@ErrorLog /opt/httpd/logs/error_log@" /etc/httpd/conf/httpd.conf && \
    sed -i -e "s@    CustomLog .*@    CustomLog "/opt/httpd/logs/access_log" combined@" /etc/httpd/conf/httpd.conf

#change mariadb setting
RUN /usr/bin/mysql_install_db --user=admin && \
    mkdir -p /opt/mariadb/logs && \
    mkdir -p /opt/run/ && \
    sed -i -e "s@log-error=/var/log/mariadb/mariadb.log@log-error=/opt/mariadb/logs/mariadb.log@" /etc/my.cnf && \
    sed -i -e "s@pid-file=/var/run/mariadb/mariadb.pid@pid-file=/opt/run/mariadb.pid@" /etc/my.cnf


#download wordpress
RUN cd /root/ && \
    curl -LO https://wordpress.org/latest.tar.gz && \
    tar -xzvf latest.tar.gz && \
    cp -R /root/wordpress/* /var/www/html && \
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

#edit wordpress config
RUN sed -i -e "s/database_name_here/db_wordpress/" /var/www/html/wp-config.php && \
    sed -i -e "s/username_here/wq_user/" /var/www/html/wp-config.php && \
    sed -i -e "s/password_here/12345/" /var/www/html/wp-config.php

RUN chown -R admin:admin /opt && \
    chown -R admin:admin /run && \
    chown -R admin:admin /var/www

#initialize mariadb
USER admin
RUN mysqld_safe & \
    sleep 5 && \
    mysql -uroot -e "CREATE DATABASE db_wordpress;" && \
    mysql -uroot -e "GRANT ALL PRIVILEGES ON db_wordpress.* TO wq_user@localhost IDENTIFIED BY \"12345\";"

#create startup shell and add permmision
RUN echo "#!/bin/bash"  > /home/admin/start.sh && \
    echo "mysqld_safe &"  >> /home/admin/start.sh && \
    echo "apachectl -DFOREGROUND "  >> /home/admin/start.sh && \
    chmod u+x /home/admin/start.sh


#EXPOSE port 8080 for web
EXPOSE 8080

USER admin

ENTRYPOINT /home/admin/start.sh
