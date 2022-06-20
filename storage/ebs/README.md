## Overview

The [Amazon Elastic Block Store](https://aws.amazon.com/ebs/) Container Storage Interface (CSI) Driver provides a [CSI](https://github.com/container-storage-interface/spec/blob/master/spec.md) interface used by Container Orchestrators to manage the lifecycle of Amazon EBS volumes.

## Features
* **Static Provisioning** - Associate an externally-created EBS volume with a [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) (PV) for consumption within Kubernetes.
* **Dynamic Provisioning** - Automatically create EBS volumes and associated [PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) (PV) from [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#PersistentVolumeClaim:~:text=PersistentVolumeClaim%20(PVC)) (PVC). Parameters can be passed via a [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/#the-storageclass-resource) for fine-grained control over volume creation.
* **Mount Options** - Mount options could be specified in the [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) (PV) resource to define how the volume should be mounted.
* **NVMe Volumes** - Consume [NVMe](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nvme-ebs-volumes.html) volumes from EC2 [Nitro instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#ec2-nitro-instances).
* **Block Volumes** - Consume an EBS volume as a [raw block device](https://kubernetes-csi.github.io/docs/raw-block.html).
* **Volume Snapshots** - Create and restore [snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/) taken from a volume in Kubernetes.
* **Volume Resizing** - Expand the volume size by specifying a new size in the [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#PersistentVolumeClaim:~:text=PersistentVolumeClaim%20(PVC)) (PVC).

# Examples


## Requirements

```
terraform >= 0.15
 ```

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0 |
| helm | >= 1.0 |
| kubernetes | >= 1.11 |
