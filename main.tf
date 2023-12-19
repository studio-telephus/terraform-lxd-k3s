module "lxd_k3s_profile_privileged" {
  source = "./modules/profile-privileged"
  name   = local.profile_privileged_name
}

resource "null_resource" "container_environment" {
  triggers = {
    for item in local.env_ipv4_addresses :
    item.key => item.value
  }
}

resource "random_id" "rng" {
  keepers = {
    first = "${timestamp()}"
  }
  byte_length = 8
}

module "container_k3s_database" {
  source       = "./modules/container"
  for_each     = var.containers.database
  image        = "images:debian/bullseye"
  name         = each.key
  ipv4_address = each.value.ipv4_address
  profiles     = var.container_profiles
  nicparent    = var.nicparent
  mount_dirs   = concat(local.local_mount_dirs, var.mount_dirs)
  exec = concat(each.value.exec, [
    {
      entrypoint = "/mnt/install-database.sh"
      environment = merge(null_resource.container_environment.triggers, {
        RANDOM_STRING       = random_id.rng.hex
        MYSQL_K3S_USERNAME  = var.mysql_k3s_username
        MYSQL_K3S_PASSWORD  = var.mysql_k3s_password
        MYSQL_K3S_DATABASE  = var.mysql_k3s_database
        MYSQL_ROOT_PASSWORD = var.mysql_root_password
      })
    }
  ])
}

module "container_k3s_loadbalancer" {
  source       = "./modules/container"
  for_each     = var.containers.loadbalancer
  image        = "images:debian/bookworm"
  name         = each.key
  ipv4_address = each.value.ipv4_address
  profiles     = var.container_profiles
  nicparent    = var.nicparent
  mount_dirs   = concat(local.local_mount_dirs, var.mount_dirs)
  exec = concat(each.value.exec, [
    {
      entrypoint = "/mnt/install-loadbalancer.sh"
      environment = merge(null_resource.container_environment.triggers, {
        RANDOM_STRING = random_id.rng.hex
      })
    }
  ])
}

module "container_k3s_master" {
  source       = "./modules/container"
  for_each     = var.containers.master
  image        = "images:debian/bookworm"
  name         = each.key
  ipv4_address = each.value.ipv4_address
  profiles     = concat(var.container_profiles, [local.profile_privileged_name])
  nicparent    = var.nicparent
  mount_dirs   = concat(local.local_mount_dirs, var.mount_dirs)
  exec = concat(each.value.exec, [
    {
      entrypoint = "/mnt/install-master.sh"
      environment = merge(null_resource.container_environment.triggers, {
        RANDOM_STRING      = random_id.rng.hex
        MYSQL_K3S_USERNAME = var.mysql_k3s_username
        MYSQL_K3S_PASSWORD = var.mysql_k3s_password
        MYSQL_K3S_DATABASE = var.mysql_k3s_database
        K3S_TOKEN          = var.k3s_token
      })
    }
  ])
  depends_on = [
    module.container_k3s_database,
    module.container_k3s_loadbalancer,
    module.lxd_k3s_profile_privileged
  ]
}

module "container_k3s_worker" {
  source       = "./modules/container"
  for_each     = var.containers.worker
  image        = "images:debian/bookworm"
  name         = each.key
  ipv4_address = each.value.ipv4_address
  profiles     = concat(var.container_profiles, [local.profile_privileged_name])
  nicparent    = var.nicparent
  mount_dirs   = concat(local.local_mount_dirs, var.mount_dirs)
  exec = concat(each.value.exec, [
    {
      entrypoint = "/mnt/install-worker.sh"
      environment = merge(null_resource.container_environment.triggers, {
        RANDOM_STRING = random_id.rng.hex
        K3S_TOKEN     = var.k3s_token
      })
    }
  ])
  depends_on = [
    module.container_k3s_loadbalancer,
    module.container_k3s_master,
    module.lxd_k3s_profile_privileged
  ]
}
