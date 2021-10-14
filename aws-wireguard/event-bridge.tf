module "eventbridge" {
  providers = {
    aws = aws.us-east-1
  }
  role_name  = "${local.name}-eventbridge"
  source     = "terraform-aws-modules/eventbridge/aws"
  create_bus = false
  rules = {
    "${local.name}-add-remove-user" = {
      description = "Trigger wg-manage lambda"
      event_pattern = jsonencode(
        {
          "source" : ["aws.iam"],
          "detail-type" : ["AWS API Call via CloudTrail"],
          "detail" : {
            "eventSource" : ["iam.amazonaws.com"],
            "eventName" : ["AddUserToGroup", "RemoveUserFromGroup"],
            "requestParameters" : {
              "groupName" : [var.wg_group_name]
            }
          }
        }
      )
      enabled = true
    }
  }

  targets = {
    "${local.name}-add-remove-user" = [
      {
        name = "Trigger wireguard manage lambda"
        arn  = aws_sns_topic.wireguard_group_change_notification.arn
      }
    ]
  }
}

resource "aws_sns_topic_policy" "default" {
  provider = aws.us-east-1
  arn      = aws_sns_topic.wireguard_group_change_notification.arn
  policy   = data.aws_iam_policy_document.wg_group_change_sns_topic_policy.json
}

data "aws_iam_policy_document" "wg_group_change_sns_topic_policy" {
  policy_id = "__default_policy_ID"
  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        local.account
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.wireguard_group_change_notification.arn
    ]

    sid = "__default_statement_ID"
  }
  statement {
    sid = "__publish_from_eventbridge"

    actions = [
      "sns:Publish"
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.wireguard_group_change_notification.arn
    ]
  }
}

resource "aws_sns_topic" "wireguard_group_change_notification" {
  provider     = aws.us-east-1
  name         = "${local.name}-group-change-notification"
  display_name = "${local.name}-group-change-notification"
}

resource "aws_sns_topic_subscription" "trigger_wg_manage_lambda" {
  provider  = aws.us-east-1
  topic_arn = aws_sns_topic.wireguard_group_change_notification.arn
  protocol  = "lambda"
  endpoint  = module.wg_manage.lambda_function_arn
}