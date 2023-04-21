variable "codedeploy_application_name" {}
variable "environment" {}
variable "create_new_codedeploy_application" {}
variable "role_arn" {}
variable "deployment_groups" {
  type = list(object({
    name            = string,
    style           = string,
    instance_target = list(string),
    asg_target      = list(string),
    onprem_target   = list(string),
    lb_tg           = string
  }))
}
variable "bluegreen_termination_wait_time_in_minutes" {
  default = 60
}
