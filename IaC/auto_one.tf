data "aws_iam_policy_document" "auto_one"{
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "archive_file" "auto_one" {  
  type = "zip"  
  source_file = "${path.module}/auto_one/lambda_function.py" 
  output_path = "auto_one.zip"
}

resource "aws_iam_role" "auto_one" {  
  name = "lambda-auto_one"  
  assume_role_policy = data.aws_iam_policy_document.auto_one.json


   inline_policy {
    name = "allow_iot"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["iot:Publish"]
          Effect   = "Allow"
          Resource = "arn:aws:iot:eu-central-1:${data.aws_caller_identity.current.account_id}:topic/strategy_auto_one/outbound"
        }
      ]
    })
  }
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "auto_one" {
    statement_id = "AllowExecutionFromIotEvents"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.auto_one.function_name
    principal = "iot.amazonaws.com"
}

resource "aws_lambda_function" "auto_one" {
        function_name = "auto_one"
        filename      = "auto_one.zip"
        source_code_hash = data.archive_file.auto_one.output_base64sha256
        role          = aws_iam_role.auto_one.arn
        runtime       = "python3.9"
        handler       = "lambda_function.lambda_handler"
        timeout       = 10
}