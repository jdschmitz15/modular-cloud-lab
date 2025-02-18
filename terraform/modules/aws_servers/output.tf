
output "aws_instance_ids" {
  value = [ for k, v in aws_instance.ec2s : v.id ]
}
output "aws_ec2_private_ip" {
  value = { for k, v in aws_instance.ec2s : k => v.private_ip }
}