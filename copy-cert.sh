#!/bin/bash
#Automatically copy certs between minio nodes
#By Poli Systems
While=1

read -p "Please provide your ssh key location (root only):" SSHKey
read -p "Enter the machines IP or hostnames seperated by a space :" MachinesIP

NMachines=$(echo "$MachinesIP" | wc -w)

for X in $MachinesIP
do
        key=${key}"| "$(ssh -p 22 -i "${SSHKey}"  -x -l root ${X} "cat /etc/minio/certs/public.crt" 2>&1)
done

export IFS="|"
for publicCRT in $key; do
    export IFS=" "
    for X in $MachinesIP
    do
        ssh -p 22 -i "${SSHKey}"  -x -l root ${X} "echo \"${publicCRT}\" >> /etc/minio/certs/CAs/minio-${While}.crt" 2>&1
        let "While=While+1"
    done
    export IFS="|"
done

echo "Finished"
