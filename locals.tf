locals {
  profile_privileged_name = "k3s-privileged-${var.env}"
  local_mount_dirs = [
    "${path.cwd}/filesystem",
  ]
  env_ipv4_addresses = flatten([for ctype, cmap in var.containers :
    flatten(
      [for name, c in cmap :
        {
          key : replace("${upper(name)}_IP", "-", "_"),
          value : c.ipv4_address
        }
    ])
  ])
}
