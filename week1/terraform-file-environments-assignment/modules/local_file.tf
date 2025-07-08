resource "local_file" "text_file" {
    for_each = var.text_files
    
    filename = "${each.value.path}/${each.value.filename}"
    content  = each.value.content
}
