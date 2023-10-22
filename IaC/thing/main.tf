resource "aws_iot_thing" "this" {
  name = var.name
}

resource "aws_iot_certificate" "this" {
  active = true
}

resource "aws_iot_thing_principal_attachment" "this" {
  principal = aws_iot_certificate.this.arn
  thing     = aws_iot_thing.this.name
}

resource "local_file" "pem" {
  content  = aws_iot_certificate.this.certificate_pem
  filename = "${path.module}/${var.name}/certificate.pem"
}

resource "local_file" "public_key" {
  content  = aws_iot_certificate.this.public_key
  filename = "${path.module}/${var.name}/public_key.cert"
}

resource "local_file" "private_key" {
  content  = aws_iot_certificate.this.private_key
  filename = "${path.module}/${var.name}/private_key.cert"
}

data "aws_caller_identity" "current" {
}


resource "aws_iot_policy" "this" {
  name = var.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iot:Publish"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iot:eu-central-1:${data.aws_caller_identity.current.account_id}:topic/${var.name}/inbound"
      },
      {
        Action = [
          "iot:Subscribe"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iot:eu-central-1:${data.aws_caller_identity.current.account_id}:topicfilter/${var.name}/outbound"
      },
      {
        Action = [
          "iot:Receive"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iot:eu-central-1:${data.aws_caller_identity.current.account_id}:topic/${var.name}/outbound"
      },
      {
        Action = [
          "iot:Connect"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iot:eu-central-1:${data.aws_caller_identity.current.account_id}:client/${var.name}"
      }
    ]
  })
}


resource "aws_iot_policy_attachment" "this" {
  policy = var.name
  target = aws_iot_certificate.this.arn
}