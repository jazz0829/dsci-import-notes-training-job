resource "aws_cloudwatch_metric_alarm" "step_function_failure_cloudwatch_metric_alarm" {
  alarm_name          = "${var.step_function_name}_execution_failure"
  namespace           = "AWS/States"
  metric_name         = "ExecutionsFailed"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 1
  period              = 60
  alarm_description   = "${var.failure_description}"

  alarm_actions      = ["${var.notification_topic_arn}"]
  ok_actions         = ["${var.notification_topic_arn}"]
  treat_missing_data = "notBreaching"

  dimensions {
    StateMachineArn = "${var.step_function_arn}"
  }

  tags = "${var.tags}"
}
