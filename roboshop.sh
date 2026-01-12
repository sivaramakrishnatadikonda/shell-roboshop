#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0ffc883b3a356e316"
INSTANCES=("mongodb" "catalogue" "forntend")
ZONE_ID="Z092734529C8LBQP3M7WP"
DOMAIN_NAME="tadikondadevops.site"

for instance in ${INSTANCES[@]}
do

aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro 
--security-group-ids sg-0ffc883b3a356e316 --tag-specifications "ResourceType=instance,
Tags=[{key=Name, Value=test}]" --query "Instances[0].InstanceId" --output text

if [ $instance -ne frontend ]
aws

done
