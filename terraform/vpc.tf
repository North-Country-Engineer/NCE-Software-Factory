resource "aws_vpc" "nce_pipelines_vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = var.vpc_name
    }
}

resource "aws_subnet" "nce_pipelines_subnet_1" {
    vpc_id     = aws_vpc.nce_pipelines_vpc.id
    cidr_block = var.subnet_1_cidr_block
    tags = {
        Name = var.subnet_1_name
    }
}

resource "aws_subnet" "nce_pipelines_subnet_2" {
    vpc_id     = aws_vpc.nce_pipelines_vpc.id
    cidr_block = var.subnet_2_cidr_block
    tags = {
        Name = var.subnet_2_name
    }
}

resource "aws_security_group" "nce_pipelines_security_group" {
    name_prefix = var.security_group_name_prefix
    vpc_id      = aws_vpc.nce_pipelines_vpc.id
    ingress {
        from_port   = var.security_group_ingress_from_port
        to_port     = var.security_group_ingress_to_port
        protocol    = var.security_group_ingress_protocol
        cidr_blocks = [var.vpc_cidr_block]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = var.security_group_name
    }
}

resource "aws_network_acl" "nce_pipelines_network_acl" {
    vpc_id = aws_vpc.nce_pipelines_vpc.id
    ingress {
        rule_no    = 100
        action     = "allow"
        protocol   = var.network_acl_ingress_protocol
        cidr_block = var.vpc_cidr_block
        from_port  = var.network_acl_ingress_from_port
        to_port    = var.network_acl_ingress_to_port
    }
    egress {
        rule_no    = 100
        action     = "allow"
        protocol   = "-1"
        cidr_block = "0.0.0.0/0"
        from_port  = 0
        to_port    = 0
    }
    tags = {
        Name = var.network_acl_name
    }
}

resource "aws_network_acl_association" "nce_pipelines_subnet_1_association" {
    subnet_id      = aws_subnet.nce_pipelines_subnet_1.id
    network_acl_id = aws_network_acl.nce_pipelines_network_acl.id
}

resource "aws_network_acl_association" "nce_pipelines_subnet_2_association" {
    subnet_id      = aws_subnet.nce_pipelines_subnet_2.id
    network_acl_id = aws_network_acl.nce_pipelines_network_acl.id
}