data "template_file" "ccm_manifest" {
  template = file("${path.module}/manifests/hcloud-ccm-net.yaml")
  vars = {
    hcloud_ccm_version = var.hcloud_ccm_version
    cluster_cidr = var.cluster_cidr
  }
}

data "http" "hcloud_csi_driver_manifest" {
  url = "https://raw.githubusercontent.com/hetznercloud/csi-driver/${var.hcloud_csi_driver_version}/deploy/kubernetes/hcloud-csi.yml"
}
