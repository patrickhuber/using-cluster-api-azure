variable subject {
    type = list(string)
}

variable audiences {
    type = list(string)
    default = [ "api://AzureADTokenExchange" ]
}

variable issuer {
    type = string
    default = "https://token.actions.githubusercontent.com"
}

variable description {
    type = string  
}

variable "resource_group_name" {
    type = string    
}

variable "location" {
    type = string
}

variable "name" {
    type = string  
}

variable "roles" {
    type = list(object({
        role = string
        scope = string
    }))
    default = [ ]
}