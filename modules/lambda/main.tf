resource "aws_iam_role" "default" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policies" {
  for_each   = toset(var.required_role_policy_arns)
  role       = aws_iam_role.default.name
  policy_arn = each.key
}

resource "aws_iam_role_policy_attachment" "logs_policy" {
  count      = var.include_logging == true ? 1 : 0
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "func" {
  filename         = var.filename
  function_name    = var.function_name
  role             = aws_iam_role.default.arn
  handler          = var.handler
  runtime          = var.runtime
  source_code_hash = filebase64sha256(var.filename)

  environment {
    variables = var.environment_variables
  }
}

resource "aws_lambda_permission" "permissions" {
  count         = length(var.permissions)
  function_name = aws_lambda_function.func.function_name
  action        = "lambda:InvokeFunction"
  statement_id  = var.permissions[count.index].statement_id
  principal     = var.permissions[count.index].principal
  source_arn    = var.permissions[count.index].source_arn

}
