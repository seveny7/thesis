variable "name" {
    type = string
}

variable "s3_bucket_name" {
    type = string
}

variable "timestreamdb_database_name" {
    type = string
}

variable "execute_lambda_on_inbound_arn" {
    type = string
    default = ""
}

variable "table_arns" {
    type = list(string)
}

variable "s3_bucket_arn" {
    type = string
}