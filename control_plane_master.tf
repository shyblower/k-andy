locals {
  first_control_plane_name = "${local.control_plane_name_base}0"
}

resource "hcloud_server" "first_control_plane" {
  name = local.first_control_plane_name

  image       = data.hcloud_image.ubuntu.name
  server_type = var.control_plane_server_type
  location    = var.server_locations[0]

  ssh_keys = [hcloud_ssh_key.provision_public.id]
  labels = merge({
    node_type = "control-plane"
  }, local.common_labels)

  user_data = format("%s\n%s", "#cloud-config", yamlencode(
    {
      runcmd = [
        "curl -sfL https://get.k3s.io | K3S_TOKEN='${random_password.k3s_cluster_secret.result}' INSTALL_K3S_VERSION='${var.k3s_version}' sh -s - server --cluster-init --node-ip ${local.first_control_plane_ip} ${local.k3s_setup_args}"
      ]
      packages = concat(local.server_base_packages, var.server_additional_packages)
    }
  ))

  network {
    network_id = local.network_id
    ip         = local.first_control_plane_ip
  }

  provisioner "remote-exec" {
    inline = [
      "until systemctl is-active --quiet k3s.service; do sleep 1; done",
      "until kubectl get node ${self.name}; do sleep 1; done",
      # Disable workloads on master node
      "kubectl taint node ${self.name} node-role.kubernetes.io/master=true:NoSchedule",
      "kubectl taint node ${self.name} CriticalAddonsOnly=true:NoExecute",
      # Install hetzner CCM
      "kubectl -n kube-system create secret generic hcloud --from-literal=token=${var.hcloud_token} --from-literal=network=${local.network_name}",
      "kubectl apply -f -<<EOF\n${data.template_file.ccm_manifest.rendered}\nEOF",
      # Install hetzner CSI plugin
      "kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${var.hcloud_token}",
      "kubectl apply -f -<<EOF\n${data.http.hcloud_csi_driver_manifest.body}\nEOF",
    ]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = local.ssh_private_key
    }
  }

}
