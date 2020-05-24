resource "aws_lambda_function" "transform_lambda" {
	filename		= "function.zip"
	function_name	= "transform_trips_data"
	role			= aws_iam_role.iam_for_lambda.arn
	handler			= "transform.handler"
	runtime = "nodejs12.x"
	depends_on = [
		aws_iam_role_policy_attachment.lambda_logs,
		aws_cloudwatch_log_group.lambda_group
	]

}