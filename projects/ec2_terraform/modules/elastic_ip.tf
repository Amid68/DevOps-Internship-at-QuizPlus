resource "aws_eip" "this" {
  domain = "vpc"
  instance = aws_instance.this.id

  depends_on = [aws_instance.this]
}
