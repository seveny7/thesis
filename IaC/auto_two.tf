data "aws_iam_policy_document" "auto_two"{
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "archive_file" "auto_two" {  
  type = "zip"  
  source_file = "${path.module}/auto_two/lambda_function.py" 
  output_path = "auto_two.zip"
}

resource "aws_iam_role" "auto_two" {  
  name = "lambda-auto_two"  
  assume_role_policy = data.aws_iam_policy_document.auto_two.json


   inline_policy {
    name = "allow_iot"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["iot:Publish"]
          Effect   = "Allow"
          Resource = "arn:aws:iot:eu-central-1:${data.aws_caller_identity.current.account_id}:topic/strategy_auto_two/outbound"
        }
      ]
    })
  }
}


resource "aws_cloudwatch_event_rule" "auto_two" {
  name                  = "run-lambda-auto_two"
  description           = "Schedule lambda function"
  schedule_expression   = "cron(0 0,8,16 * * ? *)"
}

resource "aws_cloudwatch_event_target" "auto_two" {
  target_id = "auto_two-target"
  rule      = aws_cloudwatch_event_rule.auto_two.name
  arn       = aws_lambda_function.auto_two.arn
}

resource "aws_lambda_permission" "auto_two" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.auto_two.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.auto_two.arn
}

resource "aws_lambda_function" "auto_two" {
        function_name = "auto_two"
        filename      = "auto_two.zip"
        source_code_hash = data.archive_file.auto_two.output_base64sha256
        role          = aws_iam_role.auto_two.arn
        runtime       = "python3.9"
        handler       = "lambda_function.lambda_handler"
        timeout       = 10
}