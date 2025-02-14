locals {
  control_plane_name_base = "${var.name}-control-plane-"
}

resource "hcloud_server" "control_plane" {
  for_each = { for i in range(1, var.control_plane_server_count) : "#${i}" => i }
  name     = "${local.control_plane_name_base}${each.value}"

  image       = data.hcloud_image.ubuntu.name
  server_type = var.control_plane_server_type
  location    = element(var.server_locations, each.value)

  ssh_keys = [hcloud_ssh_key.provision_public.id]
  labels = merge({
    node_type = "control-plane"
  }, local.common_labels)

  # Join cluster as server after first boot
  user_data = format("%s\n%s", "#cloud-config", yamlencode(
    {
      runcmd = [
        "curl -sfL https://get.k3s.io | K3S_TOKEN='${random_password.k3s_cluster_secret.result}' INSTALL_K3S_VERSION='${var.k3s_version}' sh -s - server --server 'https://${local.first_control_plane_ip}:6443' --node-ip ${cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, each.value + 1)} ${local.k3s_setup_args}"
      ]
      packages = concat(local.server_base_packages, var.server_additional_packages)
    }
  ))

  network {
    network_id = local.network_id
    ip         = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, each.value + 1)
  }

  provisioner "remote-exec" {
    inline = [
      "until systemctl is-active --quiet k3s.service; do sleep 1; done",
      "until kubectl get node ${self.name}; do sleep 1; done",
      # Disable workloads on master node
      "kubectl taint node ${self.name} node-role.kubernetes.io/master=true:NoSchedule",
      "kubectl taint node ${self.name} CriticalAddonsOnly=true:NoExecute",
    ]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }

  depends_on = [
    hcloud_server.first_control_plane
  ]
}
