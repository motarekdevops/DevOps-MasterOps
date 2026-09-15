output "record_fqdns" {
  description = "Fully qualified domain names created"
  value       = [for r in aws_route53_record.this : r.fqdn]
}
