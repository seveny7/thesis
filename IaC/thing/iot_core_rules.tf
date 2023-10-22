resource "aws_iot_topic_rule" "inbound" {
  name        = "${var.name}_inbound"
  enabled     = true
  sql         = "SELECT * FROM '${var.name}/inbound'"
  sql_version = "2016-03-23"

  s3 {
    bucket_name = var.s3_bucket_name
    role_arn    = aws_iam_role.this.arn
    key         = "$${topic()}/$${timestamp()}"
  }

  dynamic lambda {
    for_each = toset(
      compact([var.execute_lambda_on_inbound_arn])
    )

    content {
        function_arn = lambda.key
    }
  }

  dynamic cloudwatch_metric {
    for_each = toset(["moisture"])

    content {
        metric_name = "${var.name}/inbound/${cloudwatch_metric.key}"
        metric_namespace = "IOT"
        metric_unit = "Count"
        metric_value  = "$${${cloudwatch_metric.key}}"
        role_arn    = aws_iam_role.this.arn
    }
  }

  timestream {
    database_name = var.timestreamdb_database_name
    role_arn = aws_iam_role.this.arn
    table_name = "inbound"

    dimension {
      name ="thing_name"
      value = var.name
    }
  }
}

resource "aws_iot_topic_rule" "outbound" {
  name        = "${var.name}_outbound"
  enabled     = true
  sql         = "SELECT * FROM '${var.name}/outbound'"
  sql_version = "2016-03-23"

  dynamic cloudwatch_metric {
    for_each = toset(["watering_count"])

    content {
        metric_name = "${var.name}/outbound/${cloudwatch_metric.key}"
        metric_namespace = "IOT"
        metric_unit = "Count"
        metric_value  = "$${${cloudwatch_metric.key}}"
        role_arn    = aws_iam_role.this.arn
    }
  }

  s3 {
    bucket_name = var.s3_bucket_name
    role_arn    = aws_iam_role.this.arn
    key         = "$${topic()}/$${timestamp()}"
  }

  timestream {
    database_name = var.timestreamdb_database_name
    role_arn = aws_iam_role.this.arn
    table_name = "outbound"

    dimension {
      name ="thing_name"
      value = var.name
    }
  }
}