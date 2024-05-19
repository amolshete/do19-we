terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "terraform-state-file-737327732"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

#in case if you are using region variable in that case you can use below command
# region = var.region
#terraform.exe apply -var-file=dev-parameter.tfvars

# resource "aws_instance" "ec2_machine" {
#   ami = "ami-0f58b397bc5c1f2e8"
#   instance_type = "t2.micro"
#   key_name = "ubuntu-key-111"


#   tags = {
#     Name = "terraform-1"
#   }
# }

#creating the aws vpc

resource "aws_vpc" "webapp-vpc" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Webapp-vpc"
  }
}

#creating the subnets

resource "aws_subnet" "webapp_subnet_1a" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Webapp-Subnet-1a"
  }
}

resource "aws_subnet" "webapp_subnet_1b" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Webapp-Subnet-1b"
  }
}

resource "aws_subnet" "webapp_subnet_1c" {
  vpc_id     = aws_vpc.webapp-vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1c"

  tags = {
    Name = "Webapp-Subnet-1c"
  }
}


resource "aws_instance" "webapp-ec2-machine" {
  ami = var.ami
  instance_type = "t2.micro"
  key_name = aws_key_pair.webapp-key.id
  subnet_id = aws_subnet.webapp_subnet_1a.id
  associate_public_ip_address = true
  vpc_security_group_ids=[aws_security_group.allow_ssh_http.id]

  tags = {
    Name = "Webapp-1"
  }
}


resource "aws_instance" "webapp-ec2-machine-2" {
  ami = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  key_name = aws_key_pair.webapp-key.id
  subnet_id = aws_subnet.webapp_subnet_1b.id
  associate_public_ip_address = true
  vpc_security_group_ids=[aws_security_group.allow_ssh_http.id]

  tags = {
    Name = "Webapp-1"
  }
}

# creating the keypair
resource "aws_key_pair" "webapp-key" {
  key_name   = "webapp-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0VZRTB/JKMxtJHwjbPFl46FNkF6d2UShWy2vZmO8X/VNFu14kbiLYqcOhQ9AcGrSXK7h5a6aSjvu7u4Wiko2dNiPghSucbcah0FlApiJHGTBUBe4JuugUunYUVRWumS4DKZ+5OtHxwpONzAfFYUtyADxpw3JtetCKP1LbJTO8wtCygSNdodsGyZ/3T2ARU3LDp8z5/GGYqwMkSJp2Qx8/9gmhEccu72gyu4T+Vw9YNMyY9/bpwuVnFY5yK5cEtSrNRUAFGEbcGj0NX8XUUqs9W8JfE+AmJYgYesLVFQWRBbprv7ML5EsaEDr9wxYv0o50Ax/POQ671dPwjwFhbfnRwNVOMMQUKhUJN14zwUJ1CmwRh2M0JhUsbcpltxEqr6pzpkIEBQvcVNl0ggTbihb4QXSiTn3XwYWIH6IWAPD+KiwWkg/y3+VCv/MhGxfQkdPibAEsrzPfoHgVLf/apz6Hc6oSp13v8AA0my/lUYD7OiMl8aCKyeBUZ9y3COoRTEs= Amol@DESKTOP-2MVQBON"
}

#creating the internet GW

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.webapp-vpc.id

  tags = {
    Name = "webapp-IGW"
  }
}

#create the public RT

resource "aws_route_table" "webapp-public-RT" {
  vpc_id = aws_vpc.webapp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "webapp-public-RT"
  }
}



resource "aws_route_table" "webapp-private-RT" {
  vpc_id = aws_vpc.webapp-vpc.id

  tags = {
    Name = "webapp-private-RT"
  }
}

#route table association with subnets

resource "aws_route_table_association" "RT_asso_1" {
  subnet_id      = aws_subnet.webapp_subnet_1a.id
  route_table_id = aws_route_table.webapp-public-RT.id
}

resource "aws_route_table_association" "RT_asso_2" {
  subnet_id      = aws_subnet.webapp_subnet_1b.id
  route_table_id = aws_route_table.webapp-public-RT.id
}

resource "aws_route_table_association" "RT_asso_3" {
  subnet_id      = aws_subnet.webapp_subnet_1c.id
  route_table_id = aws_route_table.webapp-private-RT.id
}

#create the SG

resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow port 22 and 80 inbound traffic"
  vpc_id      = aws_vpc.webapp-vpc.id

  tags = {
    Name = "allow_ssh_http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_22_ipv4" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_80_ipv4" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#create the target group

resource "aws_lb_target_group" "webapp_TG" {
  name     = "webapp-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.webapp-vpc.id
}


#create LB and listerner

resource "aws_lb" "webapp_LB" {
  name               = "webapp-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh_http.id]
  subnets            = [aws_subnet.webapp_subnet_1a.id, aws_subnet.webapp_subnet_1b.id]


  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "webapp_listener" {
  load_balancer_arn = aws_lb.webapp_LB.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_TG.arn
  }
}

#create LT

resource "aws_launch_template" "webapp_LT" {
  name = "webapp-LT"
  image_id = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  key_name = aws_key_pair.webapp-key.id
 
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "webapp_LT"
    }
  }
  user_data = filebase64("userdata.sh")
}


# create asg

resource "aws_autoscaling_group" "webapp_ASG" {  
  name_prefix   = "webapp-asg"  
  vpc_zone_identifier = [aws_subnet.webapp_subnet_1a.id, aws_subnet.webapp_subnet_1b.id]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  target_group_arns = [aws_lb_target_group.webapp_TG.arn]

  launch_template {
    id      = aws_launch_template.webapp_LT.id
    version = "$Latest"
  }
}
