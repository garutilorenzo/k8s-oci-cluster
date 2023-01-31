resource "oci_core_instance_pool" "k8s_workers" {

  depends_on = [
    oci_load_balancer_load_balancer.k8s_load_balancer,
    oci_vault_secret.cert_secret,
    oci_vault_secret.token_secret,
    oci_vault_secret.hash_secret,
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

resource "oci_core_instance" "k8s_extra_worker_node" {
  count = var.k8s_extra_worker_node ? 1 : 0
  depends_on = [
    oci_load_balancer_load_balancer.k8s_load_balancer,
    oci_core_instance_pool.k8s_workers
  ]

  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = "k8s extra worker node"

  agent_config {
    is_management_disabled = "false"
    is_monitoring_disabled = "false"

    plugins_config {
      desired_state = "DISABLED"
      name          = "Vulnerability Scanning"
    }

    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }

    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
  }

  shape = var.compute_shape
  shape_config {
    memory_in_gbs = "6"
    ocpus         = "1"
  }

  source_details {
    source_id   = var.os_image_id
    source_type = "image"
  }

  create_vnic_details {
    assign_private_dns_record = true
    assign_public_ip          = true
    subnet_id                 = oci_core_subnet.default_oci_core_subnet10.id
    nsg_ids                   = [oci_core_network_security_group.lb_to_instances_http.id]
    hostname_label            = "k8s-extra-worker-node"
  }

  metadata = {
    "ssh_authorized_keys" = file(var.PATH_TO_PUBLIC_KEY)
    "user_data"           = data.cloudinit_config.k8s_worker_tpl.rendered
  }

  freeform_tags = merge(
    local.tags,
    {
      k8s-instance-type = "k8s-worker"
    }
  )
}