output "aws_ips" {
  value = {
    private_ip = module.aws_servers.aws_ec2_private_ip
    public_ip  = module.aws_servers.aws_ec2_public_ip
  }
}
