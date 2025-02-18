data "aws_ami" "amis" {
  for_each    = var.aws_config.amis
  owners      = [each.value["owner"]]
  most_recent = true
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "name"
    values = [each.value["ami"]]
  }
}

resource "aws_instance" "ec2s" {
  for_each                    = var.aws_config.ec2Instances
  ami                         = data.aws_ami.amis[each.value["ami"]].id
  instance_type               = each.value["type"]
  subnet_id                   = var.aws_subnets[each.value["subnet"]].id
  vpc_security_group_ids      = [var.aws_security_groups[each.value["vpc"]].id]
  associate_public_ip_address = each.value["publicIP"]
  key_name                    = each.value["vpc"]
  private_ip                  = contains(keys(each.value), "staticIP") ? cidrhost(var.aws_subnets[each.value["subnet"]].cidr_block,each.value["staticIP"]) : null
  root_block_device {
    delete_on_termination = true
    volume_size           = each.value["volSizeGb"]
  }
  lifecycle {
    ignore_changes = [user_data, ami]
  }
  user_data = each.value["tags"]["type"] == "windowsWkld" ? templatefile("windows-setup.tpl", { admin_password = var.aws_config.windowsAdminPwd } ) : file("${path.module}/../../userdata.sh")
  tags = merge(each.value.tags, {Name = each.key})
}