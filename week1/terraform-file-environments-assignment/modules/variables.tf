variable "text_files" {
    description = "Map of text files to create"
    type        = map(object({
        filename = string
        content  = string
        path     = string
    }))
}
