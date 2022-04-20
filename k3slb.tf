resource "oci_network_load_balancer_network_load_balancer" "k8s_load_balancer" {
  compartment_id = var.compartment_ocid
  display_name   = var.k8s_load_balancer_name
  subnet_id      = oci_core_subnet.oci_core_subnet11.id

  is_private                     = true
  is_preserve_source_destination = false

  freeform_tags = local.tags
}

resource "oci_network_load_balancer_listener" "k8s_kube_api_listener" {
  default_backend_set_name = oci_network_load_balancer_backend_set.k8s_kube_api_backend_set.name
  name                     = "k8s kube api listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k8s_load_balancer.id
  port                     = var.kube_api_port
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "k8s_kube_api_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = var.kube_api_port
  }

  name                     = "k8s kube api backend"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k8s_load_balancer.id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = false
}

resource "oci_network_load_balancer_backend" "k8s_kube_api_backend" {
  depends_on = [
    oci_core_instance_pool.k8s_servers,
  ]

  count                    = var.k8s_server_pool_size
  backend_set_name         = oci_network_load_balancer_backend_set.k8s_kube_api_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k8s_load_balancer.id
  port                     = var.kube_api_port

  target_id = data.oci_core_instance_pool_instances.k8s_servers_instances.instances[count.index].id
}