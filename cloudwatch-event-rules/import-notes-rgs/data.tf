data "aws_iam_policy_document" "cloudwatch_assume_role_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_start_execution_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "states:StartExecution",
    ]

    resources = [
      "${var.state_machine_arn}",
    ]
  }
}

data "template_file" "emr_step_input" {
  template = "${file("${path.module}/emr-step-input-template.json")}"

  vars {
    emr_generate_training_set_script    = "s3://${var.dsci_import_notes_bucket_name}/${aws_s3_bucket_object.import_notes_generate_training_set.id}"
    emr_install_dependencies_script     = "s3://${var.dsci_import_notes_bucket_name}/${aws_s3_bucket_object.import_notes_install_dependencies.id}"
    emr_data_collection_output_location = "s3://${var.dsci_import_notes_bucket_name}/EMR/output/data/"
    emr_data_collection_input_location  = "${var.emr_data_collection_input_location}"
    emr_log_output                      = "s3://${var.dsci_import_notes_bucket_name}/emr-logs/"
    emr_master_node_instance_type       = "${var.emr_master_node_instance_type}"
    emr_master_node_instance_count      = "${var.emr_master_node_instance_count}"
    emr_core_node_instance_type         = "${var.emr_core_node_instance_type}"
    emr_core_node_instance_count        = "${var.emr_core_node_instance_count}"
    ec2_subnet_id                       = "${var.ec2_subnet_id}"
  }
}

data "template_file" "event_input" {
  template = "${file(var.start_training_event_input_file)}"

  vars = {
    emr_step_input                     = "${data.template_file.emr_step_input.rendered}"
    emr_output_data                    = "s3://${var.dsci_import_notes_bucket_name}/EMR/output/data/ImportNotesTraining"
    vectorizer_output_data             = "s3://${var.dsci_import_notes_bucket_name}/EMR/output/data/VectorizedData"
    vectorizing_image                  = "428785023349.dkr.ecr.eu-west-1.amazonaws.com/dsci-sagemaker-inmapping:serve-tag-v2.6"
    training_image                     = "428785023349.dkr.ecr.eu-west-1.amazonaws.com/dsci-sagemaker-inmapping:train-tag-v2.6"
    prediction_image                   = "428785023349.dkr.ecr.eu-west-1.amazonaws.com/dsci-sagemaker-inmapping:serve-tag-v2.6.3"
    vectorizing_instance_type          = "${var.ml_m4_10xlarge}"
    vectorizing_instance_count         = "${var.vectorizing_instance_count}"
    training_instance_type             = "${var.ml_p3_2xlarge}"
    training_instance_count            = "${var.training_instance_count}"
    prediction_instance_type           = "${var.ml_serve_instance_type}"
    initial_prediction_instance_count  = "${var.initial_prediction_instance_count}"
    endpoint_name                      = "${var.endpoint_name}"
    sagemaker_training_role_arn        = "${var.sm_import_notes_training_role_arn}"
    sagemaker_prediction_role_arn      = "${var.sm_import_notes_training_role_arn}"
    model_output_path                  = "s3://${var.dsci_import_notes_bucket_name}/model"
    embedding_path                     = "s3://${var.dsci_import_notes_bucket_name}/reference/"
    log_path                           = "s3://${var.dsci_import_notes_bucket_name}/mltraining_log/"
    autoscaling_min_value              = "${var.autoscaling_min_value}"
    autoscaling_max_value              = "${var.autoscaling_max_value}"
    autoscaling_role_arn               = "${var.autoscaling_role_arn}"
    sagemaker_notify_slack_lambda_name = "${var.sagemaker_notify_slack_lambda_name}"
    is_autoscaling_enabled             = "${var.is_autoscaling_enabled}"
  }
}
