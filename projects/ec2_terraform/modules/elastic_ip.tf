resource "aws_eip" "proc_mon" {
  domain = "vpc"
  instance = aws_instance.proc_mon.id

  depends_on = [aws_instance.proc_mon]
}
