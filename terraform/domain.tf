# Domain is managed separately from the rest of the infrastructure, since it 
# has a different lifecycle and to avoid accidental changes.

resource "aws_route53_zone" "qop" {
  name = "queensofpain.cc"
}