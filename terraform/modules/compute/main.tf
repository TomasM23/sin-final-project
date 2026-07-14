resource "aws_instance" "app" {
  iam_instance_profile        = var.iam_instance_profile
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.app_security_group_id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-app-ec2"
    }
  )
}