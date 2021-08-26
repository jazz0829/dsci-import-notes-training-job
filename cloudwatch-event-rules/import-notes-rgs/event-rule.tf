resource "aws_cloudwatch_event_rule" "cloudwatch_start_training_event_rule" {
  name                = "${local.start_training_event_rule_name}"
  schedule_expression = "${var.start_training_schedule}"
  description         = "${var.start_training_event_rule_description}"
  is_enabled          = "${var.training_event_rule_enabled}"

  tags = "${var.tags}"
}

resource "aws_cloudwatch_event_target" "start_training_event_target" {
  target_id = "${var.start_training_event_target_id}"
  rule      = "${aws_cloudwatch_event_rule.cloudwatch_start_training_event_rule.name}"
  arn       = "${var.state_machine_arn}"
  role_arn  = "${aws_iam_role.cloudwatch_start_training_job_role.arn}"

  input = "${data.template_file.event_input.rendered}"
}
