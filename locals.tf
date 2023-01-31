locals {
  tags = {
    environment      = "${var.environment}"
    provisioner      = "terraform"
    terraform_module = "https://github.com/garutilorenzo/k8s-oci-cluster"
    k3s_cluster_name = "${var.cluster_name}"
    application      = "k8s"
  }
}