It is a etrraform module to deploy keycloak to EKS with ArgoCD.
to integrate this module with our swiss-army-kube project, we add the module in main terraform file:

   
  
To retrive keyclock password:
aws --region <your-region> ssm get-parameter  --with-decryption --name /<your-cluster-name>/keyclock/password | jq -r '.Parameter.Value' 

