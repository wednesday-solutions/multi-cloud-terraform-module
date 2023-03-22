## AWS EC2 NGINX module

> Spin up NGINX server in Ubuntu EC2 instance

## Variables

- `vpc_id` - VPC ID
- `subnet_id` - Public subnet ID
- `instance_name` - EC2 instance name
- `instance_type` - EC2 instance type
- `auto_create_security_group` - Auto create SG for SSH and HTTP access
- `security_group_ids` - Security group IDs
- `nginx_conf` - Basic NGINX configuration
  - `port` - port
  - `servers` - Server IPs/hostnames to load balance

## Outputs

- `aws_instance_public_dns` - Public DNS of EC2 instance
- `private_key` - (Sensitive) Private key for SSH access into EC2 instance

## Usage

```hcl
module "ec2_nginx" {
  source = "git@github.com:wednesday-solutions/multi-cloud-terraform-module/modules/aws-ec2-nginx"

  vpc_id                     = "vpc-xxxxxxx"
  subnet_id                  = "subnet-xxxxxxxx"
  instance_name              = "nginx-lb"
  instance_type              = "t2.micro"
  auto_create_security_group = true
  nginx_conf = {
    port = 80
    servers = [
      "1.2.3.4",
      "example1.com",
      "example2.com"
    ]
  }
}
```

## Providers

- `terraform-provider-aws`
- `terraform-provider-tls`

## Resources

- `aws_security_group` - Security Group
- `tls_private_key` - Private Key
- `aws_key_pair` - AWS key pair
- `aws_instance` - AWS Ec2 instance
