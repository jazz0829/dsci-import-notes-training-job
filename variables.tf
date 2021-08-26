variable "step_function_name" {
  default = "dsci-import-notes-step-function"
}

variable "step_function_definition_file" {
  default = "step-function.json"
}

variable "ecr_repo_name" {
  default = "dsci-sagemaker-inmapping"
}

variable "emr_data_collection_input_location" {
  default = "s3://dsci-eol-data-bucket/prod/domain/"
}

variable "endpoint_name" {
  default = "dsci-import-notes-endpoint"
}

variable "default_tags" {
  description = "Map of tags to add to all resources"
  type        = "map"

  default = {
    Terraform   = "true"
    GitHub-Repo = "exactsoftware/dsci-import-notes-training-job"
    Project     = "import-notes-rgs-classification"
  }
}

variable "accountid" {}
variable "region" {}
variable "ml_serve_instance_type" {}
variable "training_event_rule_enabled" {}
variable "initial_prediction_instance_count" {}
variable "is_autoscaling_enabled" {}
variable "ec2_subnet_id" {}
