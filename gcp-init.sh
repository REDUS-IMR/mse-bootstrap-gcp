#!/bin/bash

# Include global variables
source globalvar.in

# Prepare latest source codes from GIT
git clone --depth=1 git@github.com:ices-taf/wk_WKNSMSE_pok.27.3a46.git ns-saithe-mse
tar czvf ns-saithe-mse.tgz ns-saithe-mse/

# CREATE PROJECT AND ADD SSH AS META...

# From this point, Assuming project is created, ssh keys are setup and quota for CPUs, etc. are set
gcloud config set project $project_name

# Create NAT (for ext. ip address-less workers to connect to internet)
gcloud compute routers create nat-router \
    --network default \
    --region $project_region

# Create NAT config
gcloud compute routers nats create nat-config \
    --router-region $project_region \
    --router nat-router \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips

# Create template (no external IPs)
gcloud compute instance-templates create workers \
  --custom-cpu=90 \
  --custom-memory=160GB \
  --image-family=ubuntu-1810  \
  --image-project=ubuntu-os-cloud \
  --project=$project_name \
  --no-address

# Create filestore (NFS) instance
gcloud beta filestore instances create nfs-server \
  --project=$project_name \
  --location=$project_loc \
  --tier=STANDARD \
  --file-share=name="data",capacity=1TB \
  --network=name="default"

# Get the NFS IP
NFS_IP=`gcloud beta filestore instances describe nfs-server --location=$project_loc --format="value(networks.ipAddresses[0])"`

# Create init instance
gcloud compute instances create master \
  --image-family=ubuntu-1810 \
  --image-project=ubuntu-os-cloud \
  --project=$project_name \
  --machine-type=n1-highcpu-4

echo "Waiting until master is ready..."
sleep 25

# Initial setup on the master node
## Get IP
MASTER_IP=`gcloud compute instances describe master --project=$project_name --format="value(networkInterfaces[0].accessConfigs[0].natIP)"`
## Copy files
while ! scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $project_name.tgz ubuntu@$MASTER_IP:/home/ubuntu/ns-saithe-mse.tgz
do
  sleep 10
  echo "Trying again..."
done

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null bootstrap-master.sh ubuntu@$MASTER_IP:/home/ubuntu/bootstrap-master.sh
## Execute commands
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@$MASTER_IP sh -c "cd /home/ubuntu; \
    export NFS_IP=$NFS_IP; \
    echo $NFS_IP; \
    nohup bash /home/ubuntu/bootstrap-master.sh > master-bootstrap.out 2>master-bootstrap.err < /dev/null &"
