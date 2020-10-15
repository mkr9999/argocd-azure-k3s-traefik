#!/bin/bash

#usage: ./deploy.sh <rg> <dns_name> <location> <size>

RG=${1:-k3s}
DNS_NAME=${2:-argocds}
REGION=${3:-westeurope}
SIZE=${4:-Standard_B8ms}

echo "Creating a Resource group.."
az group create -n $RG
echo "..done!"

echo "Creating the k3s VM.."
az vm create -g $RG --image UbuntuLTS --size $SIZE --admin-username ubuntu --ssh-key-values ~/.ssh/id_rsa.pub -n $RG --public-ip-address-dns-name $DNS_NAME --custom-data install-k3d.sh -l ${REGION}
echo "..done!"

az network nsg rule create -g $RG --nsg-name ${RG}NSG --priority 1001 --access Allow --protocol Tcp --destination-port-ranges 443 -n https
az network nsg rule create -g $RG --nsg-name ${RG}NSG --priority 1002 --access Allow --protocol Tcp --destination-port-ranges 80 -n http
az network nsg rule create -g $RG --nsg-name ${RG}NSG --priority 1003 --access Allow --protocol Tcp --destination-port-ranges 6443 -n api
echo "..done!"

echo "Waiting two minutes to let the k3s installtion complete.."
sleep 120

echo "Retrieving the kubeconfig file"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${DNS_NAME}.${REGION}.cloudapp.azure.com:/home/ubuntu/.kube/config ./config
sed -i "s/0.0.0.0/${DNS_NAME}.${REGION}.cloudapp.azure.com/g" config
export KUBECONFIG=./config

echo "Checking if everything works"
kubectl get pods -A
kubectl cluster-info
