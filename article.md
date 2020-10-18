---
title: Managing multiple clusters with ArgoCD in Azure/k3s secured w/ Traefik&Let’s Encrypt
published: true
description: 
tags: Argoproj,Traefik,Kubernetes,Azure
cover_image: https://cdn-images-1.medium.com/max/2400/1*bGU7mCw45eS3mdbIuFWQRw.jpeg
---

*Easily deploy ArgoCD in Azure to manage multiple clusters in a GitOps way.*

*Code available at [https://github.com/ams0/argocd-azure-k3s-traefik](https://github.com/ams0/argocd-azure-k3s-traefik)*

I heard about [ArgoCD](https://argoproj.github.io/argo-cd/) many times (recently from my friends at Fullstaq [here](https://www.meetup.com/Cloud-Native-Kubernetes-Netherlands/events/270457327/)) but never came around to kick its tires until now. If you don’t know, ArgoCD is a platform for declarative continuous deployment of Kubernetes applications, and it’s becoming quickly an exceedingly popular (and now it’s an [incubated CNCF project](https://www.cncf.io/blog/2020/04/07/toc-welcomes-argo-into-the-cncf-incubator/?fbclid=IwAR0uGLZVEJxyAUKAPC5Q4ZlDAt2xbkX-kh9zuXLL4n5i-KUUFPKEI43JWZA)) choice to deploy and manage applications at scale on *multiple* clusters.

Since I want to use it for deploying to a cluster, my plan is to have an ArgoCD instance outside my clusters that can manage them independently from the clusters’ lifecycle; hence, I devise this method of deploying ArgoCD into a VM in azure running the lightweight distribution of Kubernetes from Rancher Labs, [k3s](https://k3s.io/) (deployed using the [k3d helper tool](https://github.com/rancher/k3d)) and exposed via the [Traefik ingress controller](https://traefik.io/) and secured with Let’s Encrypt certificates. Let’s get to it!

Start by cloning the [repo ](https://github.com/ams0/argocd-azure-k3s-traefik)and entering it:

    git clone [*https://github.com/ams0/argocd-azure-k3s-traefik](https://github.com/ams0/argocd-azure-k3s-traefik)
    cd argocd-azure-k3s-traefik*

Now some prerequisites:

* Azure CLI

* Azure subscription (already logged in)

* kubectl and jq installed

Let’s create the infrastructure (one VM with some extra ports open to access the Kubernetes APIs and 80/443 to expose our application):

    ./deploy.sh <rg> <dns_name> <location> <size>

*dns_name* should be unique in the region of choice. After a couple of minutes, you’ll have the *config* file for the k3s cluster (of one VM, with two virtual nodes inside as docker containers).

You may have noticed that I skipped the installation of k3s’ built-in Traefik ingress; that’s because it still packs the 1.7 branch and I want to use the newer 2.x branch that introduced the IngressRoute CRD (you can follow the progress on this [issue](https://github.com/rancher/k3s/issues/1141)). Let’s now install traefik with this [script](https://github.com/ams0/argocd-azure-k3s-traefik/blob/main/install-traefik.sh) (you’ll need to pass your email for the Let’sEncrypt certificate authority):

    ./install-traefik <email>

Finally, install ArgoCD passing the same dns_name/region and a password of your choice:

    ./install-argo.sh <dns_name> <region> <password>

That’s it! The script will patch argocd-server to run over http (SSL termination is done by Traefik) and will patch the secret with the bcrypt-encoded version of your password. Navigate to [*https://dns_name.region.cloudapp.azure.com](https://dns_name.region.cloudapp.azure.com)* and login in ArgoCD. You can also [download the CLI](https://github.com/argoproj/argo-cd/releases/download) and login with:

    argocd login --username admin \
    --password Password \
    dns_name.region.cloudapp.azure.com

Finally you can add one or more clusters to be managed by argo with (provided you already have the kubeconfig file available, for example using the azure cli to retrieve it):

    az aks get-credentials -g rg -n *cluster_name* -f kubeconfig
    argocd cluster add --kubeconfig  ./kubeconfig manageme

Note that the last option on the above command line must match the context inside the *kubeconfig* configuration.

Now, let’s deploy some apps!

I’m a big fan of the [Helm-controller](https://github.com/fluxcd/helm-controller) project and I wanted to use it with ArgoCD. In a nutshell, the controller lets you create objects of kind *HelmRelease *in your cluster (representing Helm releases) and manages the lifecycle of those helm releases programmatically (create/update/destroy). So in the *manifests/* folder in my repository, you’ll find the templates to deploy an helm-controller that will in turn deploy helmreleases also present in the same folder.

Fork the repository I provided at the top of this post and head over to the Argo UI tocreate a new app (call it to your liking, and choose the default project) pointing to the your fork and to the *manifests/* path.

![](https://cdn-images-1.medium.com/max/3078/1*z-ZKpKiNIu85SAKxCZmZSw.png)

Importantly, make sure that directory recurse is on. You can also create an object of type “Application” inside your Argo/k3s cluster to achieve the same result:

 <iframe src="https://medium.com/media/f4ed314520fce851567a51bde9fdfb06" frameborder=0></iframe>

The app will start syncing right away, installing the Helm operator first and then an nginx ingress controller and you’ll see the tree of resources being created.

![](https://cdn-images-1.medium.com/max/3940/1*OMbojl19nbrfb1K1yw6Opg.png)

That’s it! Now every change to the github repo will be reflected in your cluster.

In conclusion, you might be tempted to ask: is this production ready? Absolutely not, there are still some aspects of the deployment I want to improve (AAD authentication for Argo, for instance, and persistence of data as well). However, it’s a quickstart with ArgoCD in Azure and it will help me learn more in the future. I hope you enjoy it too!

*Originally published on [Medium](https://medium.com/cooking-with-azure/managing-multiple-clusters-with-argocd-in-azure-k3s-secured-w-traefik-lets-encrypt-2de7daabbefa)*
