provider "aws" {
  region = "us-east-1"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com" # outra opção "https://ifconfig.me"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ou ["099720109477"] ID master com permissão para busca

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server*"] # exemplo de como listar um nome de AMI - 'aws ec2 describe-images --region us-east-1 --image-ids ami-09e67e426f25ce0d7' https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
  }
}

resource "aws_instance" "maquina_master" {
  ami = data.aws_ami.ubuntu.id
  root_block_device {
    encrypted   = true
    volume_size = 8
  }
  associate_public_ip_address = true
  subnet_id     = "subnet-0926d1d3dff8224c3"
  instance_type = "t2.medium"
  key_name      = "key-outdev-hugo"
  tags = {
    Name = "hugo-maquina-cluster-kubernetes-master"
  }
  vpc_security_group_ids = ["${aws_security_group.acessos_master.id}"]
  depends_on = [
    aws_instance.workers,
  ]
}

resource "aws_instance" "workers" {
  ami = data.aws_ami.ubuntu.id
  root_block_device {
    encrypted   = true
    volume_size = 8
  }
  associate_public_ip_address = true
  subnet_id     = "subnet-0926d1d3dff8224c3"
  instance_type = "t2.micro"
  key_name      = "key-outdev-hugo"
  tags = {
    Name = "hugo-maquina-cluster-kubernetes-${count.index}"
  }
  vpc_security_group_ids = ["${aws_security_group.acessos_workers.id}"]

  count = 2
}


resource "aws_security_group" "acessos_master" {
  name        = "acessos_master"
  description = "acessos_workers inbound traffic"
  vpc_id      = "vpc-0d48f0e5799777077"
  ingress = [
    {
               cidr_blocks      = [
                   "0.0.0.0/0",
                ]
               description      = "SSH from VPC"
               from_port        = 22
               ipv6_cidr_blocks = []
               prefix_list_ids  = []
               protocol         = "tcp"
               security_groups  = []
               self             = false
               to_port          = 22
            },
    {
               cidr_blocks      = []
               description      = ""
               from_port        = 0
               ipv6_cidr_blocks = []
               prefix_list_ids  = []
               protocol         = "tcp"
               security_groups  = [
                   "sg-05154555edaabd6e0",
                ]
               self             = false
               to_port          = 65535
            },
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"],
      prefix_list_ids  = null,
      security_groups : null,
      self : null,
      description : "Libera dados da rede interna"
    }
  ]

  tags = {
    Name = "acessos_master"
  }
}


resource "aws_security_group" "acessos_workers" {
  name        = "acessos_workers"
  description = "acessos_workers inbound traffic"
  vpc_id      = "vpc-0d48f0e5799777077"
  ingress = [
    {
               cidr_blocks      = [
                   "0.0.0.0/0",
                ]
               description      = "SSH from VPC"
               from_port        = 22
               ipv6_cidr_blocks = []
               prefix_list_ids  = []
               protocol         = "tcp"
               security_groups  = []
               self             = false
               to_port          = 22
            },
           {
               cidr_blocks      = []
               description      = ""
               from_port        = 0
               ipv6_cidr_blocks = []
               prefix_list_ids  = []
               protocol         = "tcp"
               security_groups  = [
                   "sg-07a347ce377988bc0",
                ]
               self             = false
               to_port          = 65535
            },
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"],
      prefix_list_ids  = null,
      security_groups : null,
      self : null,
      description : "Libera dados da rede interna"
    }
  ]

  tags = {
    Name = "acessos_workers"
  }
}


# terraform refresh para mostrar o ssh
output "maquina_master" {
  value = [
    "master - ${aws_instance.maquina_master.public_ip} - ssh -i ~/projetos/devops/id_rsa_itau_treinamento ubuntu@${aws_instance.maquina_master.public_dns}"
  ]
}

# terraform refresh para mostrar o ssh
output "aws_instance_e_ssh" {
  value = [
    for key, item in aws_instance.workers :
    "worker ${key + 1} - ${item.public_ip} - ssh -i ~/projetos/devops/id_rsa_itau_treinamento ubuntu@${item.public_dns}"
  ]
}
