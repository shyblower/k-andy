data "http" "ccm_manifest" {
  url = "https://raw.githubusercontent.com/hetznercloud/hcloud-cloud-controller-manager/${var.hcloud_ccm_version}/deploy/ccm-networks.yaml"
}

data "http" "hcloud_csi_driver_manifest" {
  url = "https://raw.githubusercontent.com/hetznercloud/csi-driver/${var.hcloud_csi_driver_version}/deploy/kubernetes/hcloud-csi.yml"
}
