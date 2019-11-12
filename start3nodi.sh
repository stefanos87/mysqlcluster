

  
 
#!/bin/bash

#-v $PWD/d$N:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root \

docker network create groupnet

for N in 1 2 3
do docker run -d --name=node$N --net=groupnet --hostname=node$N \
  -v /var/lib/mysql -e MYSQL_ROOT_PASSWORD=root \
  stefanos87/sugar9mysql57:1.0 \
  --server-id=$N \
  --log-bin='binlog' \
  --binlog_format='ROW' \
  --enforce-gtid-consistency='ON' \
  --log-slave-updates='ON' \
  --gtid-mode='ON' \
  --transaction-write-set-extraction='XXHASH64' \
  --binlog-checksum='NONE' \
  --master-info-repository='TABLE' \
  --relay-log-info-repository='TABLE' \
  --plugin-load='group_replication.so' \
  --relay-log-recovery='ON' \
  --group-replication-start-on-boot='OFF' \
  --group-replication-group-name='aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' \
  --group-replication-local-address="node$N:33060" \
  --group-replication-group-seeds='node1:33060,node2:33060,node3:33060' \
  --loose-group-replication-single-primary-mode='OFF' \
  --loose-group-replication-enforce-update-everywhere-checks='ON'
echo "container $N instanziato"
sleep 7
done


docker ps


for N in 1 2 3
do docker exec -it node$N mysql -uroot -proot \
  -e "SET SQL_LOG_BIN=0;" \
  -e "create user repl;" \
  -e "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%' IDENTIFIED BY 'root';" \
  -e "GRANT ALL ON *.* TO 'root'@'%.%.%.%' identified by 'root';" \
  -e "GRANT ALL ON *.* TO 'root'@'localhost' identified by 'root';" \
  -e "GRANT ALL ON *.* TO 'repl'@'%.%.%.%' identified by 'root';" \
  -e "GRANT ALL ON *.* TO 'repl'@'localhost' identified by 'root';" \
  -e "flush privileges;" \
  -e "SET SQL_LOG_BIN=1;" \
  -e "change master to master_user='repl', master_password='root' for channel 'group_replication_recovery';" 
sleep 10
done



docker exec -it node1 mysql -uroot -proot \
  -e "SET GLOBAL group_replication_bootstrap_group=ON;" \
  -e "START GROUP_REPLICATION;" \
  -e "SET GLOBAL group_replication_bootstrap_group=OFF;" \
  -e "SELECT * FROM performance_schema.replication_group_members;" 
   
sleep 10


for N in 2 3
do docker exec -it node$N mysql -uroot -proot \
  -e "RESET MASTER;" \
  -e "START GROUP_REPLICATION;" \
  -e "SELECT * FROM performance_schema.replication_group_members;" 
sleep 7
done



docker exec -it node1 mysql -uroot -proot \
  -e "SELECT * FROM performance_schema.replication_group_members;" 

echo "creo database e inserisco un valore nella tabella test"
docker exec -it node1 mysql -uroot -proot  \
  -e "create database TEST; use TEST; CREATE TABLE t1 (id INT NOT NULL PRIMARY KEY) ENGINE=InnoDB; show tables;" \
  -e "INSERT INTO TEST.t1 VALUES(1);"
sleep 5
echo "select valore da tutti e 3 i nodi"

for N in 1 2 3
do docker exec -it node$N mysql -uroot -proot  \
  -e "SHOW VARIABLES WHERE Variable_name = 'hostname';" \
  -e "SELECT * FROM TEST.t1;"
done


for N in 1 2 3
do docker commit node$N stefanos87/mysqlclusterdb$N
docker push stefanos87/mysqlclusterdb$N:latest
done
