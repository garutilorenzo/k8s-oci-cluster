resource "oci_core_instance_pool" "k8s_servers" {
  depends_on = [
    oci_identity_dynamic_group.compute_dynamic_group,
    oci_identity_policy.compute_dynamic_group_policy,
    oci_vault_secret.cert_secret,
    oci_vault_secret.token_secret,
    oci_vault_secret.hash_secret,
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, freeform_tags]
  }

  display_name              = "k8s-servers"
  compartment_id            = var.compartment_ocid
  instance_configuration_id = oci_core_instance_configuration.k8s_server_template.id

  placement_configurations {
    availability_domain = var.availability_domain
    primary_subnet_id   = oci_core_subnet.default_oci_core_subnet10.id
    fault_domains       = var.fault_domains
  }

  size = var.k8s_server_pool_size

  freeform_tags = merge(
    local.tags,
    {
      k8s-instance-type = "k8s-server"
    }
  )

}