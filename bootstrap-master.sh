#!/bin/bash

# Install system-wide apps and libraries
sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y install nfs-common libgsl-dev libssl-dev libcurl4-openssl-dev libgit2-dev r-base

# Mount NFS share
mkdir /home/ubuntu/data
sudo mount -t nfs -o rw,user,exec $NFS_IP:/data /home/ubuntu/data
sudo chown -R ubuntu:ubuntu /home/ubuntu/data

# User R library in NFS share
mkdir -p /home/ubuntu/data/R/library
echo 'R_LIBS_USER="/home/ubuntu/data/R/library"' >  $HOME/.Renviron

# Install dependencies
Rscript -e 'install.packages(c("devtools", "data.table", "doParallel", "doRNG", "tidyr"))'
Rscript -e 'devtools::install_github("flr/FLCore")' -e 'devtools::install_github("flr/FLBRP")' -e 'devtools::install_github("flr/FLash")' -e 'devtools::install_github("flr/ggplotFL")' -e 'devtools::install_github("flr/FLAssess")' -e 'devtools::install_github("flr/FLa4a")' -e 'devtools::install_github("flr/mse")' -e 'devtools::install_github("fishfollower/SAM/stockassessment", ref="biomassindex")' -e 'devtools::install_github("shfischer/FLfse/FLfse")'

# Extract source and set working directory
mkdir -p /home/ubuntu/data/work
tar -xzf ns-saithe-mse.tgz -C /home/ubuntu/data/work
cd ~/data/work/ns-saithe-mse

# Create log directory
mkdir -p /home/ubuntu/data/logs

# Run OM only
Rscript -e 'no_run <- TRUE' -e 'source("run_mse_base.R")'