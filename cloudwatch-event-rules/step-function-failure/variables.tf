variable "failure_description" {
  default = "Cloudwatch event rule to detect failure of Import Notes RGS classification step function"
}

variable "step_function_name" {}
variable "step_function_arn" {}
variable "notification_topic_arn" {}

variable "tags" {
  type = "map"
}
