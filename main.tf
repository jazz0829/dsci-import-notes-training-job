module "dsci-import-notes-rgs-cloudwatch-event-rule" {
  source                             = "./cloudwatch-event-rules/import-notes-rgs"
  step_function_name                 = "${local.dsci_import_notes_state_machine_name}"
  state_machine_arn                  = "${aws_sfn_state_machine.sfn_state_machine.id}"
  emr_data_collection_input_location = "${var.emr_data_collection_input_location}"
  sm_import_notes_training_role_arn  = "${aws_iam_role.import_notes_rgs_training.arn}"
  dsci_import_notes_bucket_name      = "${local.dsci_import_notes_bucket_name}"
  accountid                          = "${var.accountid}"
  endpoint_name                      = "${local.dsci_endpoint_name}"
  initial_prediction_instance_count  = "${var.initial_prediction_instance_count}"
  ml_serve_instance_type             = "${var.ml_serve_instance_type}"
  training_event_rule_enabled        = "${var.training_event_rule_enabled}"
  name_prefix                        = "${local.name_prefix}"
  autoscaling_role_arn               = "${data.terraform_remote_state.base_config.lambda_app_sagemaker_apply_auto_scaling_role_arn}"
  sagemaker_notify_slack_lambda_name = "${data.terraform_remote_state.base_config.lambda_app_notify_slack_function_name}"
  is_autoscaling_enabled             = "${var.is_autoscaling_enabled}"
  ec2_subnet_id                      = "${var.ec2_subnet_id}"

  tags = "${var.default_tags}"
}

module "step-function-training-failure-event-rule" {
  source                 = "./cloudwatch-event-rules/step-function-failure"
  step_function_name     = "${local.dsci_import_notes_state_machine_name}"
  step_function_arn      = "${aws_sfn_state_machine.sfn_state_machine.id}"
  notification_topic_arn = "${data.terraform_remote_state.base_config.dsci_notifications_sns_topic_arn}"

  tags = "${var.default_tags}"
}
