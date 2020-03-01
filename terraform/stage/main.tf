variable "cluster_name" {}
variable "cluster_region" {}
variable "cluster_version" {}

variable "cluster_nodes_name" {}
variable "cluster_nodes_size" {}
variable "cluster_nodes_count" {}
variable "cluster_nodes_tag" {}

variable "docker_image" {}

variable "domain_name" {}
variable "subdomain_name" {}
variable "acme_email" {}

resource "digitalocean_kubernetes_cluster" "cluster" {
  name    = var.cluster_name
  region  = var.cluster_region
  version = var.cluster_version

  node_pool {
    name       = var.cluster_nodes_name
    size       = var.cluster_nodes_size
    node_count = var.cluster_nodes_count
    tags       = [var.cluster_nodes_tag]
  }
}

provider "kubernetes" {
  load_config_file = false
  host  = digitalocean_kubernetes_cluster.cluster.endpoint
  token = digitalocean_kubernetes_cluster.cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
  )
}

provider "kubectl" {
  load_config_file = false
  host  = digitalocean_kubernetes_cluster.cluster.endpoint
  token = digitalocean_kubernetes_cluster.cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
  )
}

data "kubectl_path_documents" "manifiests_build" {
  pattern = "./manifests/build/*.yaml"
  vars = {
    docker_image = var.docker_image
  }
}

resource "kubectl_manifest" "build" {
    count = length(data.kubectl_path_documents.manifiests_build.documents)
    yaml_body = element(data.kubectl_path_documents.manifiests_build.documents, count.index)
}

// https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/aws/service-nlb.yaml
resource "kubernetes_service" "nginx_ingress_controller_k8s_lb" {
  metadata {
    name      = "ingress-nginx"
    namespace = "ingress-nginx"

    labels = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/part-of"    = "ingress-nginx"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    type = "LoadBalancer"
    selector = {
      "app.kubernetes.io/name"    = "ingress-nginx"
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }

    external_traffic_policy = "Cluster"

    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }

    port {
      name        = "https"
      port        = 443
      target_port = "https"
    }
  }
}

resource "digitalocean_record" "cluster_subdomain" {
  domain = var.domain_name
  type   = "A"
  name   = var.subdomain_name
  value  = kubernetes_service.nginx_ingress_controller_k8s_lb.load_balancer_ingress.0.ip
}

data "kubectl_path_documents" "manifiests_deploy" {
  pattern = "./manifests/deploy/*.yaml"
  vars = {
    domain_name = var.domain_name
    subdomain_name = var.subdomain_name
    acme_email = var.acme_email
  }
}

resource "kubectl_manifest" "deploy" {
    count = length(data.kubectl_path_documents.manifiests_deploy.documents)
    yaml_body = element(data.kubectl_path_documents.manifiests_deploy.documents, count.index)
}



