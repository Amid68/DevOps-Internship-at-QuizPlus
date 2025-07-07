resource "local_file" "file" {
    filename    = "${var.path}/${var.filename}"
    content     = var.content
}
