resource "aws_iam_role" "state_machine_role" {
  name               = "${local.dsci_state_machine_role}"
  assume_role_policy = "${data.aws_iam_policy_document.state_machine_assume_role_policy_document.json}"

  tags = "${var.default_tags}"
}

resource "aws_iam_role_policy" "iam_policy_for_state_machine" {
  name   = "${local.dsci_state_machine_invoke_policy}"
  role   = "${aws_iam_role.state_machine_role.id}"
  policy = "${data.aws_iam_policy_document.state_machine_iam_policy_document.json}"
}

data "aws_iam_policy" "s3_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "aws_iam_policy" "sagemaker_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

data "aws_iam_policy_document" "state_machine_assume_role_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "state_machine_iam_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      "arn:aws:lambda:*:*:function:${local.name_prefix}-dsci-sagemaker-*",
    ]
  }
}

data "aws_iam_policy_document" "import_notes_rgs_training_assume_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "sagemaker.amazonaws.com"]
    }
  }
}

data "template_file" "sfn_definition" {
  template = "${file(var.step_function_definition_file)}"

  vars = {
    dsci-sagemaker-slack-lambda-arn                     = "${data.terraform_remote_state.base_config.lambda_app_notify_slack_arn}"
    dsci-sagemaker-create-training-job-lambda-arn       = "${data.terraform_remote_state.base_config.lambda_app_create_sagemaker_training_job_arn}"
    dsci-sagemaker-training-job-status-lambda-arn       = "${data.terraform_remote_state.base_config.lambda_app_get_sagemaker_training_status_output.arn}"
    dsci-sagemaker-create-model-lambda-arn              = "${data.terraform_remote_state.base_config.lambda_app_create_sagemaker_model_arn}"
    dsci-sagemaker-emr-prepare-training-data-lambda-arn = "${data.terraform_remote_state.base_config.lambda_app_run_emr_job_arn}"
    dsci-sagemaker-emr-get-status-lambda-arn            = "${data.terraform_remote_state.base_config.lambda_app_get_emr_cluster_status_arn}"
    dsci-sagemaker-create-endpoint-config-lambda-arn    = "${data.terraform_remote_state.base_config.lambda_app_create_sagemaker_endpoint_config_arn}"
    dsci-sagemaker-update-endpoint-lambda-arn           = "${data.terraform_remote_state.base_config.lambda_app_update_sagemaker_endpoint_arn}"
    dsci-sagemaker-get-endpoint-status-lambda-arn       = "${data.terraform_remote_state.base_config.lambda_app_get_sagemaker_endpoint_status_arn}"
    dsci-sagemaker-create-cloudwatch-alarms-lambda-arn  = "${data.terraform_remote_state.base_config.lambda_app_create_cloudwatch_alarm_sagemaker_arn}"
    dsci-sagemaker-invoke-endpoint-lambda-arn           = "${data.terraform_remote_state.base_config.lambda_app_invoke_sagemaker_endpoint_arn}"
    dsci-sagemaker-bookmark-endpoint-config-arn         = "${data.terraform_remote_state.base_config.lambda_app_bookmark_sagemaker_endpoint_config_arn}"
    dsci-sagemaker-rollback-endpoint-arn                = "${data.terraform_remote_state.base_config.lambda_app_rollback_sagemaker_endpoint_arn}"
    dsci-sagemaker-apply-auto-scaling-arn               = "${data.terraform_remote_state.base_config.lambda_app_sagemaker_apply_auto_scaling_arn}"
  }
}
