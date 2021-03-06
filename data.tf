data "template_cloudinit_config" "k8s_server_tpl" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/files/install_k8s_utils.sh", { k8s_version = var.k8s_version, install_longhorn = var.install_longhorn, })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/install_k8s.sh", {
      is_k8s_server             = true,
      compartment_ocid          = var.compartment_ocid,
      availability_domain       = var.availability_domain,
      k8s_version               = var.k8s_version,
      k8s_dns_domain            = var.k8s_dns_domain,
      k8s_pod_subnet            = var.k8s_pod_subnet,
      k8s_service_subnet        = var.k8s_service_subnet,
      oci_bucket_name           = var.oci_bucket_name,
      kube_api_port             = var.kube_api_port,
      control_plane_url         = local.k8s_int_lb_dns_name,
      install_longhorn          = var.install_longhorn,
      longhorn_release          = var.longhorn_release,
      install_nginx_ingress     = var.install_nginx_ingress,
      extlb_listener_http_port  = var.extlb_listener_http_port,
      extlb_listener_https_port = var.extlb_listener_https_port,
    })
  }
}

data "template_cloudinit_config" "k8s_worker_tpl" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/files/install_k8s_utils.sh", { k8s_version = var.k8s_version, install_longhorn = var.install_longhorn })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/install_k8s_worker.sh", {
      is_k8s_server     = false,
      oci_bucket_name   = var.oci_bucket_name,
      kube_api_port     = var.kube_api_port,
      control_plane_url = local.k8s_int_lb_dns_name,
    })
  }
}


data "oci_core_instance_pool_instances" "k8s_workers_instances" {
  compartment_id   = var.compartment_ocid
  instance_pool_id = oci_core_instance_pool.k8s_workers.id
}

data "oci_core_instance" "k8s_workers_instances_ips" {
  count       = var.k8s_worker_pool_size
  instance_id = data.oci_core_instance_pool_instances.k8s_workers_instances.instances[count.index].id
}

data "oci_core_instance_pool_instances" "k8s_servers_instances" {
  depends_on = [
    oci_core_instance_pool.k8s_servers,
  ]
  compartment_id   = var.compartment_ocid
  instance_pool_id = oci_core_instance_pool.k8s_servers.id
}

data "oci_core_instance" "k8s_servers_instances_ips" {
  count       = var.k8s_server_pool_size
  instance_id = data.oci_core_instance_pool_instances.k8s_servers_instances.instances[count.index].id
}