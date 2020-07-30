# Trigger:
#	SQS queue message
# Resources:
#	KMS
#	Secret manager secrets
#	SNS - naked, no topic for some instances if using AWS to send the SMS
#	SSM parameters
#	SQS queue

module "sms" {
  source = "./modules/lambda"
  enable = true
  name   = format("%s-sms", module.labels.id)

  aws_parameter_arns = [
    aws_ssm_parameter.db_database.arn,
    aws_ssm_parameter.db_host.arn,
    aws_ssm_parameter.db_port.arn,
    aws_ssm_parameter.db_reader_host.arn,
    aws_ssm_parameter.db_ssl.arn,
    aws_ssm_parameter.sms_region.arn,
    aws_ssm_parameter.sms_sender.arn,
    aws_ssm_parameter.sms_template.arn,
    aws_ssm_parameter.sms_url.arn
  ]
  aws_secret_arns                            = concat([data.aws_secretsmanager_secret_version.rds.arn], data.aws_secretsmanager_secret_version.sms.*.arn)
  config_var_prefix                          = local.config_var_prefix
  enable_sns_publish_for_sms_without_a_topic = var.enable_sms_publishing_with_aws
  handler                                    = "sms.handler"
  kms_reader_arns                            = [aws_kms_key.sqs.arn]
  log_retention_days                         = var.logs_retention_days
  security_group_ids                         = [module.lambda_sg.id]
  sqs_queue_arns_to_consume_from             = [aws_sqs_queue.sms.arn]
  subnet_ids                                 = module.vpc.private_subnets
  tags                                       = module.labels.tags
}

# Cannot create this in the module, will get a plan issue
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.sms.arn
  function_name    = module.sms.function_arn
}
