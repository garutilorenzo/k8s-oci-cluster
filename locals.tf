locals {
  public_lb_ip = [for interface in oci_network_load_balancer_network_load_balancer.k8s_public_lb.ip_addresses : interface.ip_address if interface.is_public == true]
  tags = {
    environment      = "${var.environment}"
    provisioner      = "terraform"
    terraform_module = "https://github.com/garutilorenzo/k8s-oci-cluster"
    k3s_cluster_name = "${var.cluster_name}"
    application      = "k8s"
  }
}