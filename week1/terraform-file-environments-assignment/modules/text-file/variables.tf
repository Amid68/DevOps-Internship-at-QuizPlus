variable "filename" {
    description = "Name of the file to create"
    type        = string
}

variable "content" {
    description = "Content of the file"
    type        = string
}

variable "path" {
    description = "Path where the file will be created"
    type        = string
    default     = "."
}
