resource "oci_core_instance_pool" "k8s_workers" {

  depends_on = [
    oci_network_load_balancer_network_load_balancer.k8s_load_balancer,
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, freeform_tags]
  }

  display_name              = "k8s-workers"
  compartment_id            = var.compartment_ocid
  instance_configuration_id = oci_core_instance_configuration.k8s_worker_template.id

  placement_configurations {
    availability_domain = var.availability_domain
    primary_subnet_id   = oci_core_subnet.default_oci_core_subnet10.id
    fault_domains       = var.fault_domains
  }

  size = var.k8s_worker_pool_size

  freeform_tags = merge(
    local.tags,
    {
      k8s-instance-type = "k8s-worker"
    }
  )
}