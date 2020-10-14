#!/bin/sh

#usage ./install-traefik.sh <email>

EMAIL=$1

export KUBECONFIG=./config

echo "Adding the traefik helm repository"
helm repo add traefik https://helm.traefik.io/traefik
helm repo update

echo "Installing Traefik with Let's Encrypt resolver"
helm upgrade --install \
--create-namespace -n ingress \
--set rbac.enabled=true \
--set metrics.prometheus.enabled=true \
--set="additionalArguments={--certificatesresolvers.default.acme.httpChallenge.entryPoint=web,--certificatesresolvers.default.acme.storage=/data/acme.json,--certificatesresolvers.default.acme.email=${EMAIL},--certificatesresolvers.default.acme.httpChallenge=true,--providers.kubernetesingress.ingressclass=traefik,--log.level=DEBUG}" traefik traefik/traefik

echo "To acces the dashboard, run:"
echo 'kubectl port-forward -n ingress $(kubectl get pods -n ingress --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000'
echo 'and open http://127.0.0.1:9000/dashboard/#/ in the browser'