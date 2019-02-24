#!/bin/bash

# Include global variables
source globalvar.in

## Get the mster IP
MASTER_IP=`gcloud compute instances describe master --project=$project_name --format="value(networkInterfaces[0].accessConfigs[0].natIP)"`

# Copy results
mkdir results
rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" ubuntu@$MASTER_IP:/home/ubuntu/data/work/ns-saithe-mse/output/runs/pok results/

# Print result
nofil=`find results/ -type f | wc -l`
echo "Done! $nofil file(s) synced."

# Print status from all workers
echo "Getting completion status..."
workers=11
sum=0
for (( id = 1; id <= $workers; id++ )) 
do
  num=`ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ubuntu@$MASTER_IP" ubuntu@worker-$id "cat /home/ubuntu/worker-boostrap.out | grep HCR_comb= | wc -l"`
  sum=$(($sum + $num))
done

echo "Received $sum replies from $workers workers"