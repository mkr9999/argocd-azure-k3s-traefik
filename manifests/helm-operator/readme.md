Created with

```
helm template --create-namespace \
--set configureRepositories.enable=true \
--set configureRepositories.repositories[0].name=stable \
--set configureRepositories.repositories[0].url=https://kubernetes-charts.storage.googleapis.com \
--set helm.versions=v3 \
helm-operator fluxcd/helm-operator > helm-operator.yaml
