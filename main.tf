# create the RDS or DynamoDB database

# resource "aws_db_instance" "db1" {
#   allocated_storage    = 10
#   db_name              = "test"
#   engine               = "postgres"
#   instance_class       = "db.t3.micro"
#   username             = "test"
#   password             = "test"
#   skip_final_snapshot  = true
# }

resource "aws_dynamodb_table" "test" {
  name           = "UserScores"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Name"
  range_key      = "Score"

  attribute {
    name = "Name"
    type = "S"
  }

  attribute {
    name = "Score"
    type = "S"
  }
}

# create the filter lambda

resource "aws_lambda_function" "func" {
  # instead of deploying the lambda from a zip file,
  # we can also deploy it using local code mounting
  s3_bucket = var.is_local ? "hot-reload" : null
  s3_key    = var.is_local ? "${path.cwd}/lambda" : null

  filename      = var.is_local ? null : "lambda.zip"

  function_name = "test_lambda_rds"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda.handler"
  runtime       = "python3.9"

  environment {
    variables = {
#       DB_ADDRESS = aws_db_instance.db1.address
#       DB_PORT = aws_db_instance.db1.port
    }
  }
}


# create an IAM role for the lambda

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# define the API Gateway

resource "aws_apigatewayv2_api" "test" {
  name          = "test-apigw"
  protocol_type = "HTTP"

  tags = {
    "_custom_id_": "testapi"
  }
}

resource "aws_apigatewayv2_integration" "this" {
  api_id                 = aws_apigatewayv2_api.test.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_uri        = aws_lambda_function.func.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "this" {
  api_id             = aws_apigatewayv2_api.test.id
  route_key          = "GET /"
  authorization_type = "NONE"
#   authorizer_id      = var.authorizer_id
  target             = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_stage" "test" {
  api_id = aws_apigatewayv2_api.test.id
  name   = "$default"
}

resource "aws_apigatewayv2_deployment" "test" {
  api_id      = aws_apigatewayv2_api.test.id
  description = "Test deployment"
}

# allow API Gateway to invoke the lambda

resource "aws_lambda_permission" "allow_api_gw_invoke" {
  statement_id  = "allowInvokeFromAPIGatewayRoute"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.func.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.test.execution_arn}/*/*/*/*"
}

# variable configuration
variable "is_local" {
  type = bool
  default = true
}