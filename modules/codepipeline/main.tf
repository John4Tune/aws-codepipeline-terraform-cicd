#This solution, non-production-ready template describes AWS Codepipeline based CICD Pipeline for terraform code deployment.
#© 2023 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
#This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
#http://aws.amazon.com/agreement or other written agreement between Customer and either
#Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

resource "aws_codepipeline" "terraform_pipeline" {

  name     = "${var.project_name}${var.environment}"
  role_arn = var.codepipeline_role_arn
  tags     = var.tags

  artifact_store {
    location = var.s3_bucket_name
    type     = "S3"
    encryption_key {
      id   = var.kms_key_arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeCommit"
      namespace        = "SourceVariables"
      output_artifacts = ["SourceOutput"]
      run_order        = 1

      configuration = {
        RepositoryName       = var.source_repo_name
        BranchName           = var.source_repo_branch
        PollForSourceChanges = "false"
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages

    content {
      name = stage.value["name"]
      dynamic "action" {
        for_each = stage.value["actions"]

        content {
          name             = action.value["action_name"]
          category         = action.value["category"]
          owner            = action.value["owner"]
          provider         = action.value["provider"]
          input_artifacts  = [action.value["input_artifacts"]]
          output_artifacts = [action.value["output_artifacts"]]
          version          = "1"
          run_order        = action.value["action_order"]

          configuration = action.value["configuration"]
        }
      }
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "pipeline_trigger" {
  name               = "${var.project_name}${var.environment}-${var.source_repo_branch}-codepipeline-event-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "pipeline_trigger" {
  statement {
    effect    = "Allow"
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = [aws_codepipeline.terraform_pipeline.arn]
  }
}
resource "aws_iam_role_policy" "pipeline_trigger" {
  name   = "execute_pipeline"
  role   = aws_iam_role.pipeline_trigger.id
  policy = data.aws_iam_policy_document.pipeline_trigger.json
}

resource "aws_cloudwatch_event_rule" "pipeline_trigger" {
  name        = "${var.project_name}${var.environment}-${var.source_repo_branch}-pipeline-trigger"
  description = "CodeCommit Change"

  event_pattern = jsonencode({
    "source" : [
      "aws.codecommit"
    ],
    "detail-type" : [
      "CodeCommit Repository State Change"
    ],
    "resources" : [
      "${var.source_repo_arn}"
    ],
    "detail" : {
      "event" : [
        "referenceCreated",
        "referenceUpdated"
      ],
      "referenceType" : [
        "branch"
      ],
      "referenceName" : [
        "${var.source_repo_branch}"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "pipeline_trigger" {
  rule      = aws_cloudwatch_event_rule.pipeline_trigger.name
  target_id = "ExecutePipeline"
  arn       = aws_codepipeline.terraform_pipeline.arn
  role_arn  = aws_iam_role.pipeline_trigger.arn
}
