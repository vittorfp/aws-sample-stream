
resource "aws_kinesis_stream" "trips_stream" {
	name		= "taxi-trips-stream"
	shard_count = 1
	shard_level_metrics = [
		"IncomingBytes",
		"OutgoingBytes",
		"OutgoingRecords",
		"ReadProvisionedThroughputExceeded",
		"WriteProvisionedThroughputExceeded",
		"IncomingRecords",
		"IteratorAgeMilliseconds",
	]
}


resource "aws_s3_bucket" "output_bucket" {
	bucket	= "tf-trips-bucket"
	acl		= "private"
}

resource "aws_kinesis_firehose_delivery_stream" "trips_stream" {
	name		= "kinesis-firehose-trips-stream"
	# destination	= "extended_s3"
	
	# extended_s3_configuration {
	# 	s3_backup_mode = "Enabled"

	# 	role_arn	= aws_iam_role.kinesis_firehose_stream_role.arn
	# 	bucket_arn	= aws_s3_bucket.output_bucket.arn

	# 	s3_backup_configuration {
	# 		role_arn	= aws_iam_role.kinesis_firehose_stream_role.arn
	# 		bucket_arn	= aws_s3_bucket.output_bucket.arn
	# 	}
	# }

	s3_configuration {
		role_arn	= aws_iam_role.kinesis_firehose_stream_role.arn
		bucket_arn	= aws_s3_bucket.output_bucket.arn
	}
	destination = "elasticsearch"

	elasticsearch_configuration {
		domain_arn = module.es.arn
		role_arn   = aws_iam_role.kinesis_firehose_stream_role.arn
		index_name = "taxi_trips"
		type_name  = "taxi_trips"

		processing_configuration {
			enabled = "true"
			processors {
				type = "Lambda"
				parameters {
					parameter_name  = "LambdaArn"
					parameter_value = "${aws_lambda_function.transform_lambda.arn}:$LATEST"
				}
			}
		}
	}

	kinesis_source_configuration {
		kinesis_stream_arn	= aws_kinesis_stream.trips_stream.arn
		role_arn			= aws_iam_role.kinesis_firehose_stream_role.arn
	}

}
