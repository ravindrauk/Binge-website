# Output the public IP of the instance
output "instance_public_ip1" {
  value = aws_instance.web1.public_ip
}

output "instance_public_ip2" {
  value = aws_instance.web2.public_ip
}

output "instance_private_ip1" {
  value = aws_instance.web3.public_ip
}

output "instance_private_ip2" {
  value = aws_instance.web4.public_ip
}

#output Hosted zone id
output "hosted_zone_id" {
    value = aws_route53_zone.my_zone.zone_id
}

output "s3_website_url" {
    value = aws_s3_bucket_website_configuration.example.website_endpoint
  
}
output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "route53_record" {
  value = aws_route53_record.cloudfront_record.name
}