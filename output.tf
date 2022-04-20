output "k8s_servers_ips" {
  depends_on = [
    data.oci_core_instance_pool_instances.k8s_servers_instances,
  ]
  value = data.oci_core_instance.k8s_servers_instances_ips.*.public_ip
}

output "k8s_workers_ips" {
  depends_on = [
    data.oci_core_instance_pool_instances.k8s_workers_instances,
  ]
  value = data.oci_core_instance.k8s_workers_instances_ips.*.public_ip
}

output "public_lb_ip" {
  value = oci_load_balancer_load_balancer.k8s_public_lb[0].ip_addresses
}