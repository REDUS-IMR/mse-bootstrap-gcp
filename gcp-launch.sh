#!/bin/bash

# Include global variables
source globalvar.in

# Get the NFS IP
NFS_IP=`gcloud beta filestore instances describe nfs-server --location=$project_loc --format="value(networks.ipAddresses[0])"`

## Get the mster IP
MASTER_IP=`gcloud compute instances describe master --project=$project_name --format="value(networkInterfaces[0].accessConfigs[0].natIP)"`

# Create worker instances
workers=10
for (( id = 1; id <= $workers; id++ )) 
do 
    gcloud compute instances create worker-$id \
      --project=$project_name \
      --source-instance-template=workers

    echo "Waiting until the instance is ready..."
    sleep 25

    WORKER_IP=`gcloud compute instances describe worker-$id --project=$project_name --format="value(networkInterfaces[0].networkIP)"`
    while ! scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ubuntu@$MASTER_IP" bootstrap-workers.sh ubuntu@$WORKER_IP:/home/ubuntu/bootstrap-workers.sh
    do
        sleep 10
        echo "Trying again..."
    done

    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ubuntu@$MASTER_IP" ubuntu@$WORKER_IP sh -c "cd /home/ubuntu; \
        export NFS_IP=$NFS_IP; \
        echo $NFS_IP; \
        nohup bash /home/ubuntu/bootstrap-workers.sh > /home/ubuntu/worker-bootstrap.out 2>/home/ubuntu/worker-bootstrap.err < /dev/null &"
done
