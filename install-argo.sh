#!/bin/bash

PASSWORD=${1:-"verysecurepassword"}
BCRYPT_PASSWORD=`htpasswd -bnBC 10 "" $PASSWORD | tr -d ':\n'`

export KUBECONFIG=./config

echo "Installing ArgoCD in argocd namespace"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Patching ArgoCD to disable SSL and use the latest image"
kubectl patch -n argocd deployment/argocd-server --patch "$(cat patch.yaml)"

echo "Creating the IngressRoute for ArgoCD.."
sed "s/DNS_NAME.REGION/${DNS_NAME}.${REGION}.cloudapp.azure.com/g" ingressroute-argo-template.yaml > ingressroute-argo.yaml
kubectl apply -f ingressroute-argo.yaml
rm ingressroute-argo.yaml
echo "..done!"


echo "Setting the ArgoCD password..."

PASSWORD64=`echo ${BCRYPT_PASSWORD}| base64 -w0`
kubectl get secret -n argocd argocd-secret -o json \
  | jq ".data[\"admin.password\"]|= \"$PASSWORD64\"" \
  | kubectl apply -f -

echo "..done"

#you'll need the argocd binary from https://github.com/argoproj/argo-cd/releases/download/

echo "Logging in argo.."
argocd login --username admin --password ${PASSWORD} ${DNS_NAME}.${REGION}.cloudapp.azure.com

echo "All done! You can add cluster configurations with:"
echo "argocd cluster add --kubeconfig  /home/alessandro/.kube/config external_cluster"