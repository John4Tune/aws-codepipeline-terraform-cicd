project_name       = "TestProject"
environment        = "Prod"
source_repo_name   = "terraform-sample-repo"
source_repo_branch = "main"
create_new_repo    = true
repo_approvers_arn = "arn:aws:sts::123456789012:assumed-role/CodeCommitReview/*" #Update ARN (IAM Role/User/Group) of Approval Members
create_new_role    = true
#codepipeline_iam_role_name = <Role name> - Use this to specify the role name to be used by codepipeline if the create_new_role flag is set to false.
build_projects = ["TestProjectProd"]

create_new_codedeploy_application = true
deployment_groups = [
  { name = "TestProjectProd", style = "BLUE_GREEN", instance_target = [], asg_target = ["TestProject"], onprem_target = [], lb_tg = "TestProject" }
]
bluegreen_termination_wait_time_in_minutes = 60

stage_input = [
  { name = "Build", actions = [
    { action_order = 1, action_name = "BuildProd", category = "Build", owner = "AWS", provider = "CodeBuild", input_artifacts = "SourceOutput", output_artifacts = "BuildOutput", configuration = { ProjectName = "TestProjectProd" } }
  ] },
  { name = "Approval", actions = [
    { action_order = 1, action_name = "Approval", category = "Approval", owner = "AWS", provider = "Manual", input_artifacts = "", output_artifacts = "", configuration = {} }
  ] },
  { name = "DeployProd", actions = [
    { action_order = 1, action_name = "Deploy", category = "Deploy", owner = "AWS", provider = "CodeDeploy", input_artifacts = "BuildOutput", output_artifacts = "", configuration = { ApplicationName = "TestProject", DeploymentGroupName = "tfTestrojectProd" } }
  ] }
]
