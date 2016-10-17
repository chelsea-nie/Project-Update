#!/bin/bash

#for mysqldump&recover#
##
source /etc/profile

#清除线上数据库所有数据，然后创建vip_member以及service_platform两个库#
mysql -h10.66.113.60 -P 3306 -uroot -ptdrhEDU123 -e "drop database  if exists service_platform;"
mysql -h10.66.113.60 -P 3306 -uroot -ptdrhEDU123 -e "drop database  if exists vip_member;"
mysql -h10.66.113.60 -P 3306 -uroot -ptdrhEDU123 -e "create database  if not exists service_platform default charset utf8;"
mysql -h10.66.113.60 -P 3306 -uroot -ptdrhEDU123 -e "create database  if not exists vip_member default charset utf8;"
if [ "$?" -eq 0 ];then
echo "[done]"
else
break;
fi
#初始化service_platform此库#
mysql -h10.66.113.60 -P 3306  -uroot -ptdrhEDU123  service_platform < /mnt/add_disk1/project/server-project/service-platform-api/src/main/sql/init-v1.1.sql
mysql -h10.66.113.60 -P 3306 -uroot -ptdrhEDU123 -e "drop database  if exists vip_member;"
mysql -h10.66.113.60 -P 3306 -uroot -ptdrhEDU123 -e "create database  if not exists vip_member default charset utf8;"
#此俩步操作是在上线前，同步原先线上主数据库的数据到云数据库#
mysqldump -uroot -ptdrhedu --compress --default-character-set=utf8 --single-transaction --databases vip_member | mysql -h10.66.113.60 -P 3306 -uroot -ptdrhEDU123
mysqldump -t -uroot -ptdrhedu --compress --default-character-set=utf8 --single-transaction --databases service_platform | mysql -h10.66.113.60 -P 3306 -uroot -ptdrhEDU123
#此步操作是更新老版本里的数据表及结构和触发器等导入至云数据库#
mysql -h10.66.113.60 -P3306  -uroot -ptdrhEDU123  service_platform < /mnt/add_disk1/project/server-project/service-platform-api/src/main/sql/update-v1.1-v1.2.sql
echo "[下一步在执行do update-v1.1-v1.2.sh之前请确保服务平台已能工作正常，为了确保，请手动执行！！]"
sleep 10
#/usr/bin/sh /mnt/add_disk1/project/server-project/service-platform-api/src/main/sql/update-v1.1-v1.2.sh   #此步操作需要手动执行，要确保服务平台运行正常，然后最后再执行do update-v1.1-v1.2.sh
if [ "$?" -eq 0 ];then
echo "[done]"
else
break;
fi
