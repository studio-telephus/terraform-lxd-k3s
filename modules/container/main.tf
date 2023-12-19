module "container" {
  source    = "github.com/studio-telephus/terraform-lxd-instance.git?ref=main"
  name      = var.name
  profiles  = var.profiles
  image     = var.image
  autostart = true
  nic = {
    name = var.nicname
    properties = {
      nictype        = var.nictype
      parent         = var.nicparent
      "ipv4.address" = var.ipv4_address
    }
  }
  mount_dirs   = var.mount_dirs
  exec_enabled = var.exec_enabled
  exec         = var.exec
}
