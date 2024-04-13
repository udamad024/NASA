# Instance type
variable "instance_type" {
  default = "t2.micro"
}

# Default tags
variable "default_tags" {
  default = {
    "Owner" = "CAAacs730"
    "App"   = "Web"
  }
  type        = map(any)
  description = "Default tags to be appliad to all AWS resources"
}

# Prefix to identify resources
variable "prefix" {
  default     = "Prod"
  type        = string
  description = "Name prefix"
}


# Variable to signal the current environment 
variable "env" {
  default     = "Prod"
  type        = string
  description = "Deployment Environment"
}
