# Drone on Google Kubernetes Engine

This directory contains various example deployments of Drone on [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/).

**Note: While Drone supports a variety of different remotes, this demo assumes
that the projects you'll be building are on GitHub.**

## Prep work

**Before continuing on to one of the example setups below, you'll need to create a GKE cluster**, plus a persistent disk for the DB. Here's a rough run-down of that process:

### Create a Kubernetes Engine Cluster

There are a few different ways to create your cluster:

* If you don't have a strong preference, make sure your `gcloud` client is pointed at the GCP project you'd like the cluster created within. Next, run the `create-gke-cluster.sh` script in this directory. You'll end up with a cluster and a persistent disk for your DB. Your `gcloud` client will point `kubectl` at your new cluster for you.
* The Google Cloud Platform web console makes cluster creation very easy as well. See the [GKE docs](https://cloud.google.com/kubernetes-engine/docs/quickstart)), on how to go about this. You'll want to use an g1-small machine type or larger. If you create the cluster through the web console, you'll need to manually point your `kubectl` client at the cluster (via `gcloud container clusters get-credentials`).

### Create a persistent disk for your sqlite DB

By default, these manifests will store all Drone state on a Google Cloud persistent disk via sqlite. As a consequence, we need an empty persistent disk before running the installer.

You can either do this in the GCP web console or via the `gcloud` command. In the case of the latter, you can use our `create-disk.sh` script after you open it up and verify that the options make sense for you.

In either case, make sure the persistent disk is named `drone-server-sqlite-db`. Also make sure that it is in the same availability zone as the GKE cluster.

## Installation

Create Kubernetes Engine Cluster and persistent disk

```sh
# Create Kubernetes Engine Cluster
./create-gke-cluster.sh
# Create persistent disk
./create-disk.sh
```

## Remove Cluster

Remove kubernetes cluster and persistent disk

```sh
# Remove Kubernetes Engine Cluster
./remove-gke-cluster.sh
# Remove persistent disk
./remove-disk.sh
```
