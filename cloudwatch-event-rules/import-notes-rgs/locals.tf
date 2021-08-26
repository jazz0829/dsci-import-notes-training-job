locals {
  start_training_event_rule_name = "${var.name_prefix}-dsci-import-notes-rgs-classification-training-rule"
  start_training_role_name       = "${var.name_prefix}-dsci-import-notes-rgs-training-allow-start-execution"
  start_training_policy_name     = "${local.start_training_role_name}-policy"
}
