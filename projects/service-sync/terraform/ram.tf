# resource "aws_ram_principal_association" "route53" {
#   principal          = "111111111111"
#   resource_share_arn = aws_ram_resource_share.example.arn
# }

# resource "aws_ram_resource_share" "example" {
#   name                      = "example"
#   allow_external_principals = true

#   tags = {
#     Environment = "Production"
#   }
# }