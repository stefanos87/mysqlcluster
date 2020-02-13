

  
 
#!/bin/bash

#-v $PWD/d$N:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root \

for N in 1 2 3
do docker run -d --name=mysql$N --hostname=mysql$N \
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
  --group-replication-local-address="mysql$N:33060" \
  --group-replication-group-seeds='mysql1:33060,mysql2:33060,mysql3:33060' \
  --loose-group-replication-single-primary-mode='OFF' \
  --loose-group-replication-enforce-update-everywhere-checks='ON'
echo "container $N instanziato"
sleep 7
done


docker ps


for N in 1 2 3
do docker commit mysql$N stefanos87/mysqlclusterdb$N
docker push stefanos87/mysqlclusterdb$N:latest
done
