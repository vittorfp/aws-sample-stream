data "aws_iam_policy_document" "kinesis_firehose_stream_assume_role" {
	statement {
		effect  = "Allow"
		actions = ["sts:AssumeRole"]
		principals {
			type		= "Service"
			identifiers = ["firehose.amazonaws.com"]
		}
	}
}


resource "aws_iam_role" "kinesis_firehose_stream_role" {
	name				= "kinesis_firehose_stream_role"
	assume_role_policy	= data.aws_iam_policy_document.kinesis_firehose_stream_assume_role.json
}


# Allow firehose to consume Kinesis Stream
resource "aws_iam_policy" "firehose_kinesis_policy" {
  name        = "firehose_kinesis_policy"
  description = "Acesso irrestrito aos streams."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": [
		"kinesis:*"
	  ],
	  "Effect": "Allow",
	  "Resource": "*"
	}
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "kinesis-attach" {
	name       = "kinesis-permission-attachment"
	roles      = [
		aws_iam_role.kinesis_firehose_stream_role.name
	]
	policy_arn = aws_iam_policy.firehose_kinesis_policy.arn
}


# Allow firehose to save files in S3
resource "aws_iam_policy" "firehose_s3_policy" {
  name        = "firehose_s3_policy"
  description = "Acesso aos buckets."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": [
		"s3:*"
	  ],
	  "Effect": "Allow",
	  "Resource": "*"
	}
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "s3-attach" {
	name       = "s3-permission-attachment"
	roles      = [
		aws_iam_role.kinesis_firehose_stream_role.name
	]
	policy_arn = aws_iam_policy.firehose_s3_policy.arn
}


# Allow firehose to write in ElasticSearch Service
resource "aws_iam_policy" "firehose_es_policy" {
  name        = "firehose_es_policy"
  description = "Acesso irrestrito ao elastic."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": [
		"es:*"
	  ],
	  "Effect": "Allow",
	  "Resource": "*"
	}
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "es-attach" {
	name       = "es-permission-attachment"
	roles      = [
		aws_iam_role.kinesis_firehose_stream_role.name
	]
	policy_arn = aws_iam_policy.firehose_es_policy.arn
}

# resource "aws_iam_policy" "firehose_lambda_policy" {
#   name        = "firehose_lambda_policy"
#   description = "Acesso à lambda."
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
# 	{
# 	  "Action": [
# 		"lambda:*"
# 	  ],
# 	  "Effect": "Allow",
# 	  "Resource": "*"
# 	}
#   ]
# }
# EOF
# }



# resource "aws_iam_policy_attachment" "lambda-attach" {
# 	name       = "lambda-permission-attachment"
# 	roles      = [
# 		aws_iam_role.kinesis_firehose_stream_role.name
# 	]
# 	policy_arn = aws_iam_policy.firehose_lambda_policy.arn
# }




# Allow lambda calls from firehose

data "aws_iam_policy_document" "lambda_assume_policy" {
	statement {
		effect = "Allow"

		actions = [
			"lambda:InvokeFunction",
			"lambda:GetFunctionConfiguration",
		]

		resources = [
			aws_lambda_function.transform_lambda.arn,
			"${aws_lambda_function.transform_lambda.arn}:*",
		]
	}
}

resource "aws_iam_role_policy" "lambda_policy" {
	name   = "lambda_function_policy"
	role   = aws_iam_role.kinesis_firehose_stream_role.name
	policy = data.aws_iam_policy_document.lambda_assume_policy.json
}

# Allow logging in lambda

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
			"Effect": "Allow",
			"Sid": ""
		}
	]
}
EOF
}

resource "aws_cloudwatch_log_group" "lambda_group" {
  name              = "/aws/lambda/transform_trips_data"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}