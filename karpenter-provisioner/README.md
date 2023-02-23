# Sak Karpenter provisioner module

Terraform module which creates Karpenter provisioner and karpenter AwsNodeTemplate resources. 

### External Documentation
- [Karpemter Provisioner](https://karpenter.sh/v0.24.0/concepts/provisioners/)
- [Karpenter Node Templates](https://karpenter.sh/v0.24.0/concepts/node-templates/)



## Usage
### ArgoCd enabled
Creates an argoCD Apllication and manifest files in argoCD path using local_file terraform resource. 
```hcl
module “provisioner” {
  source = “github.com/provectus/sak-karpenter-provisioner”
  cluster_name = var.cluster_name
  argocd_enabled = true
  argocd = module.argocd.state
  provisioners = {
    default = {
      requirements = [
        {
          key      = “karpenter.k8s.aws/instance-family”
          operator = “In”
          values   = [ “m5” ]
        },
        {
          key      = “karpenter.sh/capacity-type”
          operator = “In”
          values   = [“spot”, “on-demand”]
        },
        {
          key      = “karpenter.k8s.aws/instance-size”
          operator = “In”
          values   = [ “nano”, “micro”, “small”, “large”, “medium” ]
        },
      ]
      labels = {
        test = “true”
      }
      container_runtime = “containerd”
      consolidation_enabled = true
    },
  }
  depends_on = [
    helm_release.karpenter
  ]
}
```
### ArgoCd disabled
Creates the manifests and apply them using kubectl_manifest terraform resource
```hcl
module “provisioner” {
  source = “github.com/provectus/sak-karpenter-provisioner”
  cluster_name = var.cluster_name
  argocd_enabled = false
  provisioners = {
    default = {
      requirements = [
        {
          key      = “karpenter.k8s.aws/instance-family”
          operator = “In”
          values   = [ “m5” ]
        },
        {
          key      = “karpenter.sh/capacity-type”
          operator = “In”
          values   = [“spot”, “on-demand”]
        },
        {
          key      = “karpenter.k8s.aws/instance-size”
          operator = “In”
          values   = [ “nano”, “micro”, “small”, “large”, “medium” ]
        },
      ]
      labels = {
        test = “true”
      }
      container_runtime = “containerd”
      consolidation_enabled = true
    },
  }
  depends_on = [
    helm_release.karpenter
  ]
}
```
## Basic examples with diffrent NodeGroup types
Following examples will help you to set needed configuration for your environment:
### [General purpose instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/general-purpose-instances.html)
General purpose instances provide a balance of compute, memory, and networking resources, and can be used for a wide range of workloads.You can use instance family from [this](https://aws.amazon.com/ec2/instance-types/#General_Purpose) list but it also should be in [Instance types suported by Karpenter](https://karpenter.sh/v0.23.0/concepts/instance-types/).

Example
```hcl
provisioners = {
  general = {
    requirements = [
      {
        key      = “karpenter.k8s.aws/instance-family”
        operator = “In”
        values   = [ “m5”,"m4","t3"]
      },
    ]
    labels = {
      workflow-type = “general”
    }
    container_runtime = “containerd”
    consolidation_enabled = true
  },
}
```
### [Compute optimized instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/compute-optimized-instances.html)
Compute optimized instances are ideal for compute-bound applications that benefit from high-performance processors.You can use instance family from [this](https://aws.amazon.com/ec2/instance-types/#Compute_Optimized) list but it also should be in [Instance types suported by Karpenter](https://karpenter.sh/v0.23.0/concepts/instance-types/).

Example
```hcl
provisioners = {
  cpu-optimized = {
    requirements = [
      {
        key      = “karpenter.k8s.aws/instance-family”
        operator = “In”
        values   = [ “c5”,"c6i"]
      },
    ]
    labels = {
      workflow-type = cpu-optimized
    }
    container_runtime = “containerd”
    consolidation_enabled = true
  },
}
```

### [Memory optimized instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/memory-optimized-instances.html)
Memory optimized instances are designed to deliver fast performance for workloads that process large data sets in memory.You can use instance family from [this](https://aws.amazon.com/ec2/instance-types/#Memory_Optimized) list but it also should be in [Instance types suported by Karpenter](https://karpenter.sh/v0.23.0/concepts/instance-types/).

Example
```hcl
provisioners = {
  memory-optimized = {
    requirements = [
      {
        key      = “karpenter.k8s.aws/instance-family”
        operator = “In”
        values   = [ “r5”,"r6a"]
      },
    ]
    labels = {
      workflow-type = memory-optimized
    }
    container_runtime = “containerd”
    consolidation_enabled = true
  },
}
```

### [Accelerated computing instances(GPU optimized)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/accelerated-computing-instances.html)
If you require high processing capability, you'll benefit from using accelerated computing instances, which provide access to hardware-based compute accelerators such as Graphics Processing Units (GPUs), Field Programmable Gate Arrays (FPGAs), or AWS Inferentia.
- [GPU optimized instance types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/accelerated-computing-instances.html#gpu-instances)

An instance with an attached NVIDIA GPU, such as a P3 or G4dn instance, must have the appropriate NVIDIA driver installed. Depending on the instance type, you can either download a public NVIDIA driver, download a driver from Amazon S3 that is available only to AWS customers, or use an AMI with the driver pre-installed.
- [Available drivers by instance type](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-nvidia-driver.html#:~:text=for%20video%20decoding-,Available%20drivers%20by%20instance%20type,-The%20following%20table)
- [AMIs with the NVIDIA drivers installed](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-nvidia-driver.html#:~:text=Option%201%3A%20AMIs%20with%20the%20NVIDIA%20drivers%20installed)
- [Public NVIDIA drivers](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-nvidia-driver.html#:~:text=Option%202%3A%20Public%20NVIDIA%20drivers)
- [GRID drivers (G5, G4dn, and G3 instances)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-nvidia-driver.html#:~:text=Option%203%3A%20GRID%20drivers%20(G5%2C%20G4dn%2C%20and%20G3%20instances))
- [NVIDIA gaming drivers (G5 and G4dn instances)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-nvidia-driver.html#:~:text=Option%204%3A%20NVIDIA%20gaming%20drivers%20(G5%20and%20G4dn%20instances))

An instance with an attached AMD GPU, such as a G4ad instance, must have the appropriate AMD driver installed. Depending on your requirements, you can either use an AMI with the driver preinstalled or download a driver from Amazon S3.
- [AMIs with the AMD driver installed](https://aws.amazon.com/marketplace/search/results?searchTerms=AMD+Radeon+Pro+Driver&CREATOR=e6a5002c-6dd0-4d1e-8196-0a1d1857229b&filters=CREATOR)
- [AMD driver download and install](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-amd-driver.html#amd-radeon-pro-software-for-enterprise-driver:~:text=.-,AMD%20driver%20download,-If%20you%20aren%27t)

Also you need to deploy an appropriate GPU device plugin daemonset for those nodes. Without the daemonset running, Karpenter will not see those nodes as initialized. Refer to general [Kubernetes GPU](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/#deploying-amd-gpu-device-plugin) docs and the following specific GPU docs:
- nvidia.com/gpu: [NVIDIA device plugin for Kubernetes](https://github.com/NVIDIA/k8s-device-plugin)
- amd.com/gpu: [AMD GPU device plugin for Kubernetes](https://github.com/RadeonOpenCompute/k8s-device-plugin)
- aws.amazon.com/neuron: [Kubernetes environment setup for Neuron](https://github.com/aws-neuron/aws-neuron-sdk/tree/master/src/k8)
- habana.ai/gaudi: [Habana device plugin for Kubernetes](https://docs.habana.ai/en/latest/Orchestration/Gaudi_Kubernetes/Habana_Device_Plugin_for_Kubernetes.html)

Example
```hcl
provisioners = {
  gpu-optimized = {
    requirements = [
      {
        key      = “karpenter.k8s.aws/instance-family”
        operator = “In”
        values   = [ “g5"]
      },
    ]
    labels = {
      workflow-type = gpu-optimized
    }
    taints = [
      {
        key = "nvidia.com/gpu"
        value = true
        effect = "NoSchedule"
      }
    ]
    resources_limits = {
      cpu = 1000 
      memory = 1000Gi
      "nvidia.com/gpu" = 2
    }
    container_runtime = “containerd”
    consolidation_enabled = true
  },
}
```

## Requirements

| Name | Version |
|------|---------|
|[terraform](#requirement\_terraform) | >= 1.0 |
|[local](#requirement\_local) | >= 2.2.3 |
|[gavinbunney/kubectl](#requirement\_kubectl) | >= 1.14 |

## Providers

| Name | Version |
|------|---------|
|[local](#provider\_local) | >= 2.10 |
|[kubectl](#provider\_kubectl) | >= 1.14 |
## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="provisioners"></a> [provisioners](#provisioners) | ./modules/provisioners | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.provisioner_app](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | A name of the Amazon EKS cluster | `string` | `null` | yes |
| argocd_enabled | A name of the Amazon EKS cluster | `bool` | `true` | no |
| application_name | A name of the Argocd application recource | `string` | `"provisioners"` | yes (if argocd_enabled = true) |
| argocd | A set of values for enabling deployment through ArgoCD | `map(string)` | `null` | yes (if argocd_enabled = true) |
| provisioners | Map of provisioner definitions to create | `any` | `{}` | yes |

## Provisioner Inputs
- [requirements](https://karpenter.sh/v0.24.0/concepts/provisioners/#specrequirements)
  - Karpenter supports [AWS-specific labels](https://karpenter.sh/v0.24.0/concepts/scheduling/#well-known-labels) and [Kubernetes Well-Known labels](https://kubernetes.io/docs/reference/labels-annotations-taints/), for more advanced scheduling.These well-known labels may be specified at the provisioner level, or in a workload definition (e.g., nodeSelector on a pod.spec). Nodes are chosen using both the provisioner’s and pod’s requirements. If there is no overlap, nodes will not be launched. In other words, a pod’s requirements must be within the provisioner’s requirements. If a requirement is not defined for a well known label, any value available to the cloud provider may be chosen.
  ```hcl 
  requirements = [
        {
          key      = “karpenter.k8s.aws/instance-family”
          operator = “In”
          values   = [ “m5” ]
        },
        {
          key      = “karpenter.sh/capacity-type”
          operator = “In”
          values   = [“spot”, “on-demand”]
        }
      ]
  ```
- [taints](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
  - Provisioned nodes will have these taints.Taints may prevent pods from scheduling if they are not tolerated by the pod.
  ```hcl 
  taints = [
    {
      key = "example.com/special-taint"
      effect = "NoSchedule"
    },
  ]
  ```
- [startup_taints](https://karpenter.sh/v0.24.0/concepts/provisioners/#cilium-startup-taint)
  - StartupTaints are taints that are applied to nodes upon startup which are expected to be removed automatically within a short period of time, typically by a DaemonSet that tolerates the taint. These are commonly used by daemonsets to allow initialization and enforce startup ordering.  StartupTaints are ignored for provisioning purposes in that pods are not required to tolerate a StartupTaint in order to have nodes provisioned for them.
  ```hcl 
  startup_taints = [
    {
      key = "example.com/special-taint"
      effect = "NoSchedule"
    },
  ]
  ```
- [labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
  - Labels are arbitrary key-values that are applied to all nodes.
  ```hcl 
  labels = {
    billing-team = my-team
  }
  ```
- [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
  - Annotations are arbitrary key-values that are applied to all nodes.
  ```hcl 
  annotations = {
    example.com/owner = "my-team"
  }
  ```
- [resources_limits](https://karpenter.sh/v0.24.0/concepts/provisioners/#speclimitsresources)
  - constrains the maximum amount of resources that the provisioner will manage.
  ```hcl 
  resources_limits = {
    cpu = 1000 
    memory = 1000Gi
    "nvidia.com/gpu" = 2
  }
  ```
- [consolidation_enabled](https://karpenter.sh/v0.24.0/concepts/deprovisioning/#consolidation)
  - You can configure Karpenter to deprovision instances through your Provisioner in multiple ways. You can use ttl_secondes_after_empty, spec.ttl_seconds_untill_expierd or consolidation_enabled.
  ```hcl 
  consolidation_enabled = true
  ```
- [ttl_secondes_after_empty](https://karpenter.sh/v0.24.0/concepts/deprovisioning/#methods:~:text=provisioner%20is%20deleted.-,Emptiness,-%3A%20Karpenter%20notes%20when)
  - If omitted, the feature is disabled, nodes will never scale down due to low utilization
  ```hcl 
  ttl_secondes_after_empty = 30
  ```
- [ttl_seconds_untill_expierd](https://karpenter.sh/v0.24.0/concepts/deprovisioning/#methods:~:text=used%20for%20workloads.-,Expiration,-%3A%20Karpenter%20requests%20to)
  - If omitted, the feature is disabled and nodes will never expire. If set to less time than it requires for a node to become ready, the node may expire before any pods successfully start.
  ```hcl 
  ttl_seconds_untill_expierd = 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
  ```
- [weight](https://karpenter.sh/v0.24.0/concepts/scheduling/#weighting-provisioners)
  - Priority given to the provisioner when the scheduler considers which provisioner to select. Higher weights indicate higher priority when comparing provisioners.Specifying no weight is equivalent to specifying a weight of 0.
  ```hcl 
  weight = 10
  ```
- [container_runtime](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
  - You can specify the container runtime to be either dockerd or containerd.containerd is the only valid container runtime when using the Bottlerocket AMI Family or when using the AL2 AMI Family and K8s version 1.24+
  ```hcl 
  container_runtime = containerd
  ```
- [cluster_dns](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/)
  - You can specify the container runtime to be either dockerd or containerd.containerd is the only valid container runtime when using the Bottlerocket AMI Family or when using the AL2 AMI Family and K8s version 1.24+
  ```hcl 
  cluster_dns = ["10.0.1.100"]
  ```
- [kubelet_system_reserved](https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/#system-reserved)
  - Override the --system-reserved configuration
  ```hcl 
  kubelet_system_reserved = {
      cpu = "100m"
      memory = "100Mi"
      ephemeral-storage = "1Gi"
  }
  ```
- [kubelet_kube_reserved](https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/#kube-reserved)
  - Override the --kube-reserved configuration
  ```hcl 
  kubelet_kube_reserved = {
      cpu = "200m"
      memory = "100Mi"
      ephemeral-storage = "3Gi"
  }
  ```
- [kubelet_eviction_hard](https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/#hard-eviction-thresholds)
  - A hard eviction threshold has no grace period. When a hard eviction threshold is met, the kubelet kills pods immediately without graceful termination to reclaim the starved resource.[Supported Eviction Signals](https://karpenter.sh/v0.23.0/concepts/provisioners/#supported-eviction-signals)
  ```hcl 
  kubelet_eviction_hard = {
    "memory.available = "500Mi"
    "nodefs.available = "10%"
    "nodefs.inodesFree = "10%"
    "imagefs.available" = "5%"
    "imagefs.inodesFree" = "5%"
    "pid.available" = "7%"
  }
  ```
- [kubelet_eviction_soft](https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/#soft-eviction-thresholds)
  - A soft eviction threshold pairs an eviction threshold with a required administrator-specified grace period. The kubelet does not evict pods until the grace period is exceeded. The kubelet returns an error on startup if there is no specified grace period.[Supported Eviction Signals](https://karpenter.sh/v0.23.0/concepts/provisioners/#supported-eviction-signals)
  ```hcl 
  kubelet_eviction_hard = {
    "memory.available = "500Mi"
    "nodefs.available = "10%"
    "nodefs.inodesFree = "10%"
    "imagefs.available" = "5%"
    "imagefs.inodesFree" = "5%"
    "pid.available" = "7%"
  }
  ```
- [kubelet_eviction_soft_grace_period](https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/#:~:text=eviction%2Dsoft%2Dgrace%2Dperiod)
  - A set of eviction grace periods that define how long a soft eviction threshold must hold before triggering a Pod eviction.
  ```hcl 
  kubelet_eviction_soft_grace_period = {
    "memory.available = "1m"
    "nodefs.available = "1m30s"
    "nodefs.inodesFree = "2m"
    "imagefs.available" = "1m30s"
    "imagefs.inodesFree" = "2m"
    "pid.available" = "2m"
  }
  ```
- [kubelet_eviction_max_pod_grace_period](https://kubernetes.io/docs/concepts/scheduling-eviction/node-pressure-eviction/#:~:text=a%20Pod%20eviction.-,eviction%2Dmax%2Dpod%2Dgrace%2Dperiod,-%3A%20The%20maximum%20allowed)
  - The administrator-specified maximum pod termination grace period to use during soft eviction.
  ```hcl 
  kubelet_eviction_max_grace_period = "3m"
  ```
- [kubelet_max_pods](https://karpenter.sh/v0.23.0/concepts/provisioners/#max-pods)
  - This value will be used during Karpenter pod scheduling and passed through to --max-pods on kubelet startup.
  ```hcl 
  kubelet_max_pods = "20"
  ```
- [kubelet_pods_per_core](https://karpenter.sh/v0.23.0/concepts/provisioners/#pods-per-core)
  - This value will also be passed through to the --pods-per-core value on kubelet startup to configure the number of allocatable pods the kubelet can assign to the node instance.
  ```hcl 
  kubelet_pods_per_core = "2"
  ```
- [ami_family](https://karpenter.sh/v0.23.0/concepts/node-templates/#specamifamily)
  - Resolves a default ami and userdata. Currently, Karpenter supports amiFamily values AL2, Bottlerocket, Ubuntu and Custom. GPUs are only supported with AL2 and Bottlerocket.
  ```hcl 
  ami_family = "AL2"
  ```
- [block_device_mappings](https://karpenter.sh/v0.23.0/concepts/node-templates/#specblockdevicemappings)
  - Used to control the Elastic Block Storage (EBS) volumes that Karpenter attaches to provisioned nodes.
  ```hcl 
  block_device_mappings = [
    {
        deviceName = "/dev/xvda"
        ebs = {
            volumeSize = "100Gi"
            volumeType = "gp3"
            iops = 10000
            encrypted = true
            kmsKeyID = "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
            deleteOnTermination = true
            throughput = 125
            snapshotID = "snap-0123456789"
        }
    },
    ]
  ```
- [metadata_options](https://karpenter.sh/v0.23.0/concepts/node-templates/#specmetadataoptions)
  - Control the exposure of [Instance Metadata Service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) on EC2 Instances launched by this provisioner using a generated launch template.
  ```hcl 
  metadata_options = {
    httpEndpoint = "enabled"
    httpProtocolIPv6 = "disabled"
    httpPutResponseHopLimit = 2
    httpTokens = "required"
  }
  ```
- [instace_profile](https://karpenter.sh/v0.23.0/concepts/node-templates/#specinstanceprofile)
  - An InstanceProfile is a way to pass a single IAM role to EC2 instance launched the provisioner. A default profile is configured in global settings, but may be overridden here. The AWSNodeTemplate will not create an InstanceProfile automatically. The InstanceProfile must refer to a Role that has permission to connect to the cluster. Overrides the node's identity from global settings.
  ```hcl 
  instace_profile = "MyInstanceProfile"
  ```
- [detailed_monitoring_enabled](https://karpenter.sh/v0.23.0/concepts/node-templates/#specdetailedmonitoring)
  - Enabling detailed monitoring on the node template controls the [EC2 detailed monitoring](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-cloudwatch-new.html) feature. If you enable this option, the Amazon EC2 console displays monitoring graphs with a 1-minute period for the instances that Karpenter launches.
  ```hcl 
  detailed_monitoring_enabled = true
  ```
- [tags](https://karpenter.sh/v0.23.0/concepts/node-templates/#spectags)
  - Karpenter adds tags to all resources it creates, including EC2 Instances, EBS volumes, and Launch Templates. The default set of AWS tags are listed below.The following tag ("karpenter.sh/discovery" = "YOUR_CLUSTER_NAME") is attached by default for Karpenter to be able to launche instances.
  ```hcl 
  tags = {
    "InternalAccountingTag" = "1234"
    "dev.corp.net/app" = "Calculator"
    "dev.corp.net/team" = "MyTeam"
  }
  ```
- [subnet_selector](https://karpenter.sh/v0.23.0/concepts/node-templates/#specsubnetselector)
  - Discovers subnets using AWS tags. Subnets may be specified by any AWS tag, including Name. Selecting tag values using wildcards (*) is supported. Subnet IDs may be specified by using the key aws-ids and then passing the IDs as a comma-separated string value. When launching nodes, a subnet is automatically chosen that matches the desired zone. If multiple subnets exist for a zone, the one with the most available IP addresses will be used.
  ```hcl 
  subnet_selector = {
    "Name" = "*Public*"
    "MyTag" = "" # matches all resources with the tag
    "aws-ids" = "subnet-09fa4a0a8f233a921,subnet-0471ca205b8a129ae"
  }
  ```
- [sg_selector](https://karpenter.sh/v0.23.0/concepts/node-templates/#specsecuritygroupselector)
  - Security groups may be specified by any AWS tag, including “Name”. Selecting tags using wildcards (*) is supported.
  ```hcl 
  sg_selector = {
    "Name" = "*Public*"
    "MyTag" = "" # matches all resources with the tag
    "aws-ids" = "sg-063d7acfb4b06c82c,sg-06e0cf9c198874591"
  }
  ```
- [ami_selector](https://karpenter.sh/v0.23.0/concepts/node-templates/#specamiselector)
  - ami_selector is used to configure custom AMIs for Karpenter to use, where the AMIs are discovered through AWS tags, similar to subnetSelector. This field is optional, and Karpenter will use the latest EKS-optimized AMIs if an ami_selector is not specified.
  ```hcl 
  ami_selector = {
    "Name" = "*Public*"
    "MyTag" = "" # matches all resources with the tag
    "aws-ids" = "ami-123,ami-456"
  }
  ```
- [user_data](https://karpenter.sh/v0.23.0/concepts/node-templates/#specuserdata)
  - You can control the UserData that is applied to your worker nodes via this field.
  ```hcl 
  user_data = <<EOF
  #!/bin/bash
    mkdir -p ~ec2-user/.ssh/
    touch ~ec2-user/.ssh/authorized_keys
    cat >> ~ec2-user/.ssh/authorized_keys <<EOF
    {{ insertFile "../my-authorized_keys" | indent 4  }}
    EOF
    chmod -R go-w ~ec2-user/.ssh/authorized_keys
    chown -R ec2-user ~ec2-user/.ssh
  EOF
  ```