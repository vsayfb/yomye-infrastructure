variable "project_id" {
  type = string
}

variable "location" {
  type    = string
  default = "EU"
}

variable "name_prefix" {
  type    = string
  default = "yevmiye-production"
}

variable "state_prefix" {
  description = "Object prefix used by the root GCS backend."
  type        = string
  default     = "production"
}
