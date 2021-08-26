variable "start_training_event_rule_description" {
  default = "Cloudwatch event rule to schedule training of the Import Notes RGS class prediction model"
}

variable "start_training_schedule" {
  default = "rate(14 days)"
}

variable "start_training_event_target_id" {
  default = "TraingImportNotesRgsModel"
}

variable "start_training_event_input_file" {
  default = "cloudwatch-event-rules/import-notes-rgs/input.json"
}

// Sagemaker Vectorizing job settings
variable "vectorizing_instance_count" {
  default = 1
}

variable "ml_m4_10xlarge" {
  default = "ml.m4.10xlarge"
}

// Sagemaker Training job settings

variable "training_instance_count" {
  default = 1
}

variable "ml_p3_2xlarge" {
  default = "ml.p3.2xlarge"
}

variable "initial_prediction_instance_count" {}

variable "tags" {
  type = "map"
}

//EMR cluster settings for data collection step

variable "emr_master_node_instance_type" {
  default = "m4.xlarge"
}

variable "emr_master_node_instance_count" {
  default = 1
}

variable "emr_core_node_instance_type" {
  default = "r5.4xlarge"
}

variable "emr_core_node_instance_count" {
  default = 6
}

variable "ec2_subnet_id" {}

variable "autoscaling_min_value" {
  default = 2
}

variable "autoscaling_max_value" {
  default = 4
}

variable "sagemaker_notify_slack_lambda_name" {}
variable "autoscaling_role_arn" {}
variable "endpoint_name" {}
variable "ml_serve_instance_type" {}
variable "accountid" {}
variable "name_prefix" {}
variable "state_machine_arn" {}
variable "step_function_name" {}
variable "dsci_import_notes_bucket_name" {}
variable "emr_data_collection_input_location" {}
variable "sm_import_notes_training_role_arn" {}
variable "training_event_rule_enabled" {}
variable "is_autoscaling_enabled" {}
