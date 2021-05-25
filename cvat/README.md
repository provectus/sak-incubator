# CVAT

This chart bootstraps the Computer Vision Annotation Tool deployment on a Kubernetes cluster using Helm.

CVAT GitHub repository: https://github.com/openvinotoolkit/cvat  
The Helm chart is based on the chart from CVAT repository: https://github.com/openvinotoolkit/cvat/tree/develop/helm-chart

## Usage:
1. Execute `helm dependency update` in `./helm` directory to download Helm charts for PostgreSQL and Redis.
2. Integrate the module into your project. The following snippet is an example of the integration that uses Nginx as ingress:  
```terraform
module cvat {
  depends_on      = [module.kubernetes, module.nginx]
  source          = "github.com/provectus/sak-incubator/cvat"

  cluster_name    = local.cluster_name
  domains         = local.domain
}
```
3. Create admin account for CVAT. It can be created by creating an account and adding admin rights in Postgres. You can access Postgres via port-forwarding using the following command:
```bash
kubectl port-forward service/cvat-postgresql -n cvat 5432:5432
 ```
