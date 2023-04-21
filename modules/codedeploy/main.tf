resource "aws_codedeploy_app" "codedeploy_application" {
  count            = var.create_new_codedeploy_application ? 1 : 0
  compute_platform = "Server"
  name             = var.codedeploy_application_name
}

resource "aws_codedeploy_deployment_group" "deployment_group" {
  count = length(var.deployment_groups)

  app_name               = var.codedeploy_application_name
  deployment_group_name  = element(var.deployment_groups, count.index)["name"]
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn       = var.role_arn

  deployment_style {
    deployment_type   = element(var.deployment_groups, count.index)["style"]
    deployment_option = element(var.deployment_groups, count.index)["style"] == "BLUE_GREEN" ? "WITH_TRAFFIC_CONTROL" : "WITHOUT_TRAFFIC_CONTROL"
  }

  dynamic "ec2_tag_set" {
    for_each = element(var.deployment_groups, count.index)["instance_target"]
    content {
      ec2_tag_filter {
        key   = "Name"
        type  = "KEY_AND_VALUE"
        value = ec2_tag_set.value
      }
    }
  }

  autoscaling_groups = element(var.deployment_groups, count.index)["asg_target"]

  dynamic "on_premises_instance_tag_filter" {
    for_each = element(var.deployment_groups, count.index)["onprem_target"]

    content {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = on_premises_instance_tag_filter.value
    }
  }

  dynamic "load_balancer_info" {
    for_each = element(var.deployment_groups, count.index)["lb_tg"] != "" ? [element(var.deployment_groups, count.index)["lb_tg"]] : []
    content {
      target_group_info {
        name = load_balancer_info.value
      }
    }

  }

  dynamic "blue_green_deployment_config" {
    for_each = element(var.deployment_groups, count.index)["style"] == "BLUE_GREEN" ? [1] : []
    content {
      deployment_ready_option {
        action_on_timeout = "CONTINUE_DEPLOYMENT"
      }

      green_fleet_provisioning_option {
        action = "COPY_AUTO_SCALING_GROUP"
      }

      terminate_blue_instances_on_deployment_success {
        action                           = "TERMINATE"
        termination_wait_time_in_minutes = var.bluegreen_termination_wait_time_in_minutes
      }
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      autoscaling_groups
    ]
  }
}
