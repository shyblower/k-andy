data "template_file" "ccm_manifest" {
  template = file("${path.module}/manifests/ccm-networks.yaml")
  vars = {
    hcloud_ccm_version = var.hcloud_ccm_version
  }
}

data "http" "hcloud_csi_driver_manifest" {
  url = "https://raw.githubusercontent.com/hetznercloud/csi-driver/${var.hcloud_csi_driver_version}/deploy/kubernetes/hcloud-csi.yml"
}
