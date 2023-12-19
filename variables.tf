#variable "cni" {
#  type        = string
#  default     = "flannel"
#  description = "CNI driver"
#}
#
#variable "kubeconfig" {
#  type        = string
#  default     = "kubeconfig.local"
#  description = "Local kubeconfig file"
#}
#
#variable "manifests" {
#  type        = list(string)
#  default     = []
#  description = "List of manifests to load after setting up the first master"
#}

variable "env" {
  type    = string
  default = "dev"
}

variable "nicparent" {
  type = string
}

variable "containers" {
  type = map(map(object({
    ipv4_address = string
    exec = list(object({
      entrypoint  = string
      environment = map(any)
    }))
  })))
}

variable "container_profiles" {
  type    = list(string)
  default = []
}

variable "mount_dirs" {
  type    = list(string)
  default = []
}

variable "mysql_k3s_username" {
  type = string
}

variable "mysql_k3s_password" {
  type      = string
  sensitive = true
}

variable "mysql_k3s_database" {
  type = string
}

variable "mysql_root_password" {
  type      = string
  sensitive = true
}

variable "k3s_token" {
  type      = string
  sensitive = true
}
