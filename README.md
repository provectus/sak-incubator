[![tflint](https://github.com/provectus/sak-incubator/actions/workflows/tflint.yml/badge.svg)](https://github.com/provectus/sak-incubator/actions/workflows/tflint.yml)

> :warning: working on the readme in progress

# SAK-incubator 

The [sak-incubator](https://github.com/provectus/sak-incubator/tree/main) repository contains Terraform modules that pass the verification and evaluation stage. After adapting the module to the project, it will get its own repository of the form sak - < module name> and a fixed version. You can offer your modules here

## Using SAK Modules

To use modules in your cluster, include some in your project by uncommenting them in the `modules.tf` file, set variables for these modules in the `example.tfvars` file, and deploy your cluster.
To add or destroy a module, add/remove it in the modules.tf file and run: 
```
terraform plan -out plan && terraform apply plan
```
## All SAK Modules

SAK Modules: 

* [Core Modules](#core)
* [Optional Modules](#optional)

Some of the SAK modules are core - you can't deploy a cluster without them. Core modules are in bold in the list below. Other modules are optional.

*  [airflow](./airflow) 
*  [cicd](./cicd)
    + [argo](./cicd/argo)
    + [jenkins](./cicd/jenkins)
    + [github-actions](./cicd/github-actions)
*  [ingress](./ingress)
    + [oauth](./oauth)
*   [kfserving](./kfserving)
*   [kubeflow-operator](./kubeflow-operator)
*   [kubeflow-prod-default](./kubeflow-prod-default)
*   [kubeflow-profiles](./kubeflow-profiles)
*   **[kubernetes](https://github.com/provectus/sak-kubernetes)**
*   [logging](./logging)
    + [efk](./logging/efk)
    + [loki](./logging/loki)
    + [aws-for-fluent-bit](./logging/aws-for-fluent-bit)
*   [mlflow](./mlflow)
*   [monitoring](./monitoring)
    + [prometheus](https://github.com/provectus/sak-prometheus)
*   **[network](https://github.com/provectus/sak-vpc)**
*   [rds](./rds) 
*   [registry-mirror](./registry-mirror)
*   [scaling](https://github.com/provectus/sak-scaling)
*   [storage](./storage)
    + [efs](https://github.com/provectus/swiss-army-kube/tree/master/modules/storage/efs)
    + [fsx](https://github.com/provectus/swiss-army-kube/tree/master/modules/storage/fsx)
*  **[system](https://github.com/provectus/swiss-army-kube/tree/master/modules/system)**

<a name="core"></a>
### Core Modules
 
#### 1. Kubernetes 

Kubernetes module is used to deploy the EKS cluster in Amazon. It creates an autoscaling group (ASG) of EC2 instances in selected accessibility zones and runs containers on those instances, maintaining and scaling them. 

#### 2. Network

Network module is a VPC module for creating networks, load balancers, and gateways.

#### 3. System

>:warning: some modules migrate to their repository (like sak-cert-manager, sak-external-dns)


System module configures an EKS cluster with addons and Helm charts - cert-manager (ExternalDNS), external-dns, saled-secrets, kube-state-metrics. Cert-manager is a native Kubernetes certificate management addon to automate issuance and management of TLS certificates. ExternalDNS addon makes Kubernetes resources discoverable via public DNS servers. kube-state-metrics Helm Chart listens to the Kubernetes API server and generates metrics about the state of the objects (deployments, nodes and pods). sealed-secrets manages secretes. 

<a name="optional"></a>
### Optional Modules   

Other (non-core) modules are optional. You can include them in your project by uncommenting them in the `modules.tf` file and setting variables for them in the `example.tfvars` file. You can also add your own modules to include in your cluster deployments.
