variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "account_tier" {
  type = string
  default =  "Standard"
}

variable "account_replication_type"{
  type = string
  default = "LRS"
}

variable "containers" {
  type = list(object({
    name = string
    access_type = string
  }))  
  validation {
    condition = alltrue([
      for o in var.containers : contains(["private", "container", "blob"], lower(o.access_type))
    ])
    error_message = "Containers must specify 'private', 'container' or 'blob' access types"
  }
  default = [ ]
}