locals {
  name                 = "portworx"
  namespace            = "kube-system"
  service_account_name = ""

  set_values = try(length(var.aws_access_key_id) > 0, false) ? concat([
      {
        name  = "envVars"
        value = "AWS_ACCESS_KEY_ID=${var.aws_access_key_id};AWS_SECRET_ACCESS_KEY=${var.aws_secret_access_key}"
      }
    ],var.set_values): var.set_values

  set_sensitive_values = var.set_sensitive_values

  default_helm_config = {
    name                       = local.name
    description                = "A Helm chart for portworx"
    chart                      = "portworx"
    repository                 = "https://raw.githubusercontent.com/portworx/helm/eks-blueprint/repo/staging"
    version                    = "2.11.0"
    namespace                  = local.namespace
    values                     = local.default_helm_values
    set_values                 = []
    set_sensitive_values       = null
  }

  helm_config = merge(
    local.default_helm_config,
    var.helm_config
  )

  irsa_config = {
    create_kubernetes_namespace = false
    kubernetes_namespace        = local.namespace
    create_kubernetes_service_account = true
    kubernetes_service_account        = "${local.name}-sa"
    # irsa_iam_policies = concat([aws_iam_policy.pradyuman_policy_one.arn], var.irsa_policies)
  }

  argocd_gitops_config = {
    enable             = false
    serviceAccountName = local.name
  }

  default_helm_values = [templatefile("${path.module}/values.yaml", merge({
        clusterName                 = "mycluster"      
        useInternalKVDB             = true
        drives                      = "type=gp2,size=200"  
        kvdbDevice                  = "type=gp2,size=150"
        maxStorageNodesPerZone      = 3 
        envVars                     = ""
        eksServiceAccount           = "${local.name}-sa"
        imageVersion                = "2.11.0"
    },var.chart_values)
  )]
}


