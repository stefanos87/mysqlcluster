#!/bin/bash

docker stop node1 node2 node3
docker rm node1 node2 node3
sudo rm -rf d1 d2 d3
docker network rm groupnet
# docker rmi stefanos87/sugar9mysql57:1.0