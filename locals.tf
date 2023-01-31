locals {
  k8s_int_lb_dns_name = format("%s.%s.%s.oraclevcn.com", replace(var.k8s_load_balancer_name, " ", "-"), var.oci_core_subnet_dns_label11, var.oci_core_vcn_dns_label)
  tags = {
    environment      = "${var.environment}"
    provisioner      = "terraform"
    terraform_module = "https://github.com/garutilorenzo/k8s-oci-cluster"
    k3s_cluster_name = "${var.cluster_name}"
    application      = "k8s"
  }
}