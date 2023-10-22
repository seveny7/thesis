locals {
  stations = toset(["strategy_auto_one", "strategy_auto_two", "strategy_manual"])
}

module "esp32" {
  for_each = local.stations

  source = "./thing"
  name   = each.key

  s3_bucket_name = aws_s3_bucket.cold_storage.bucket
  timestreamdb_database_name = aws_timestreamwrite_database.analytics.database_name
  execute_lambda_on_inbound_arn = each.key == "strategy_auto_one" ? aws_lambda_function.auto_one.arn : ""
  table_arns = [aws_timestreamwrite_table.inbound.arn, aws_timestreamwrite_table.outbound.arn]
  s3_bucket_arn = aws_s3_bucket.cold_storage.arn
}

resource "aws_s3_bucket" "cold_storage" {
  bucket = "cold.storage"
}

resource "aws_timestreamwrite_database" "analytics" {
  database_name = "analytics"
}


resource "aws_timestreamwrite_table" "inbound" {
  database_name = aws_timestreamwrite_database.analytics.database_name
  table_name    = "inbound"
}

resource "aws_timestreamwrite_table" "outbound" {
  database_name = aws_timestreamwrite_database.analytics.database_name
  table_name    = "outbound"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.0"
    }
  }
}