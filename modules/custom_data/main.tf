data "template_file" "init" {
  template = file("${path.module}/files/rke2-init.sh")

  vars = {
    type = var.agent ? "agent" : "server"

    server_url   = var.server_url
    vault_url    = var.vault_url
    token_secret = var.token_secret
    config       = var.config
    ccm          = var.ccm
    cloud        = var.cloud
    node_labels  = var.node_labels
    node_taints  = var.node_taints

    pre_userdata  = var.pre_userdata
    post_userdata = var.post_userdata
  }
}
