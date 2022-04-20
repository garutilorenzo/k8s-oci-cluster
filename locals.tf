locals {
  k8s_int_lb_dns_name = format("%s.%s.%s.oraclevcn.com", replace(var.k8s_load_balancer_name, " ", "-"), var.oci_core_subnet_dns_label11, var.oci_core_vcn_dns_label)
  tags = {
    "environment"           = "${var.environment}"
    "provisioner"           = "terraform"
    "scope"                 = "k8s-cluster"
    "uuid"                  = "${var.uuid}"
    "${var.unique_tag_key}" = "${var.unique_tag_value}"
  }
}