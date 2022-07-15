variable "namespaces" {
  description = "Vault namespace names"
  type        = map(any)
}

variable "group" {
  description = "A group for authorization purposes"
  type        = string
}

variable "metadata" {
  description = "Group metadata"
  type        = map(string)
  default     = {}
}
