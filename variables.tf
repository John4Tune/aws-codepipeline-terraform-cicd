#This solution, non-production-ready template describes AWS Codepipeline based CICD Pipeline for terraform code deployment.
#© 2023 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
#This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
#http://aws.amazon.com/agreement or other written agreement between Customer and either
#Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

variable "project_name" {
  description = "Unique name for this project"
  type        = string
}

variable "create_new_repo" {
  description = "Whether to create a new repository. Values are true or false. Defaulted to true always."
  type        = bool
  default     = true
}

variable "create_new_role" {
  description = "Whether to create a new IAM Role. Values are true or false. Defaulted to true always."
  type        = bool
  default     = true
}

variable "codepipeline_iam_role_name" {
  description = "Name of the IAM role to be used by the Codepipeline"
  type        = string
  default     = "codepipeline-role"
}

variable "source_repo_name" {
  description = "Source repo name of the CodeCommit repository"
  type        = string
}

variable "source_repo_branch" {
  description = "Default branch in the Source repo for which CodePipeline needs to be configured"
  type        = string
}

variable "repo_approvers_arn" {
  description = "ARN or ARN pattern for the IAM User/Role/Group that can be used for approving Pull Requests"
  type        = string
}

variable "environment" {
  description = "Environment in which the script is run. Eg: dev, prod, etc"
  type        = string
}

variable "stage_input" {
  description = "Tags to be attached to the CodePipeline"
  type = list(object({
    name = string,
    actions = list(object({
      action_order     = number,
      action_name      = string,
      category         = string,
      owner            = string,
      provider         = string,
      input_artifacts  = string,
      output_artifacts = string,
      configuration    = map(any),
    }))
  }))
}

variable "build_projects" {
  description = "Tags to be attached to the CodePipeline"
  type        = list(string)
}

variable "buildspecs" {
  type = list(string)
}

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

variable "builder_compute_type" {
  description = "Relative path to the Apply and Destroy build spec file"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "builder_image" {
  description = "Docker Image to be used by codebuild"
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
}

variable "builder_type" {
  description = "Type of codebuild run environment"
  type        = string
  default     = "LINUX_CONTAINER"
}

variable "builder_image_pull_credentials_type" {
  description = "Image pull credentials type used by codebuild project"
  type        = string
  default     = "CODEBUILD"
}

variable "build_project_source" {
  description = "Type of codebuild project source"
  type        = string
  default     = "CODEPIPELINE"
}

variable "create_new_codedeploy_application" {}
variable "bluegreen_termination_wait_time_in_minutes" {}
