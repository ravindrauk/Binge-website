resource "aws_s3_bucket" "mys3bucket"  {
  bucket = var.aws_s3_bucket

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.mys3bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
locals {
  s3_origin_id ="mys3Origin"
}
resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.mys3bucket.id
  acl    = "private"
}
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.mys3bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
  resource "aws_s3_object" "index" {
    key = "index.html"
    bucket = aws_s3_bucket.mys3bucket.id
    source = "index.html"
    acl = "private"
    content_type = "text/html"
  }

   resource "aws_s3_object" "error" {
    key = "error.html"
    bucket = aws_s3_bucket.mys3bucket.id
    source = "error.html"
    acl = "private"
    content_type = "text/html"
  }

  resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.mys3bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
  }


#Vpc creation
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "BingeVpc"
  }

}

#Internet gate way
resource "aws_internet_gateway" "Igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "IGw"
  }
}

#Route table 
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/16"
    gateway_id = aws_internet_gateway.Igw.id
  }
  tags = {
    Name = "Routetable"
  }
}

# Routes Association with private subnet
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.publicsubnet1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "Rta2" {
  subnet_id      = aws_subnet.publicsubnet2.id
  route_table_id = aws_route_table.RT.id
}

#Security groups & allow traffics
resource "aws_security_group" "Sg" {
    name = var.sgname

    description = "Allow all TCP And HTTP access and all outbound traffic"
    vpc_id = aws_vpc.vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "Allow Sg"
    }
}

#subnet creations
resource "aws_subnet" "publicsubnet1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "Publicsubnet1"
  }
}
resource "aws_subnet" "privatesubnet1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "Privatesubnet1"
  }
}
resource "aws_subnet" "publicsubnet2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "Publicsubnet2"
  }
}
resource "aws_subnet" "privatesubnet2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "Privatesubnet2"
  }
}
#Instance1 in publicsubnet1
  resource "aws_instance" "web1" {
    ami = var.ami
    instance_type = var.instance_type
    vpc_security_group_ids = [ aws_security_group.Sg.id ]
    subnet_id = aws_subnet.publicsubnet1.id 
    associate_public_ip_address = true

    tags = {
      Name = "BingeServer1"
    }
  }
#Instance2 in pulic subnet2
    resource "aws_instance" "web2" {
    ami = var.ami
    instance_type = var.instance_type
    vpc_security_group_ids = [ aws_security_group.Sg.id ]
    subnet_id = aws_subnet.publicsubnet2.id 
    associate_public_ip_address = true

    tags = {
      Name = "BingeServer2"
    }
  }

  #Instance3 in private subnet1
    resource "aws_instance" "web3" {
    ami = var.ami
    instance_type = var.instance_type
    vpc_security_group_ids = [ aws_security_group.Sg.id ]
    subnet_id = aws_subnet.privatesubnet1.id 
    associate_public_ip_address = true

    tags = {
      Name = "BingeServer3"
    }
  }
   #Instance4 in private subnet2
    resource "aws_instance" "web4" {
    ami = var.ami
    instance_type = var.instance_type
    vpc_security_group_ids = [ aws_security_group.Sg.id ]
    subnet_id = aws_subnet.privatesubnet2.id 
    associate_public_ip_address = true

    tags = {
      Name = "BingeServer4"
    }
  }



   
# Create a CloudFront Distribution for the S3 Website
resource "aws_cloudfront_distribution" "cdn" {
    
     restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  origin {
    domain_name = aws_s3_bucket.mys3bucket.bucket_regional_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


# Create a Route 53 Hosted Zone
resource "aws_route53_zone" "my_zone" {
  name = "binge.com"  # Replace with your domain name
}

# Create a Route 53 Record to Point to CloudFront
resource "aws_route53_record" "cloudfront_record" {
  zone_id = aws_route53_zone.my_zone.zone_id
  name    = "www.binge.com"  # Replace with your subdomain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}



