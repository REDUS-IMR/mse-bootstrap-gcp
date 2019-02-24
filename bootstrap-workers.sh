#!/bin/bash

# Install system-wide apps and libraries
sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y install nfs-common libgsl-dev libssl-dev libcurl4-openssl-dev libgit2-dev r-base

# Mount NFS share
mkdir /home/ubuntu/data
sudo mount -t nfs -o rw,user,exec $NFS_IP:/data /home/ubuntu/data

# User R library in NFS share
echo 'R_LIBS_USER="/home/ubuntu/data/R/library"' >  $HOME/.Renviron

# Extract source and set working directory
cd /home/ubuntu/data/work/ns-saithe-mse

# Run script
./run_google.sh