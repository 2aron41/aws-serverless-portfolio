mock_provider "aws" {
  override_data {
    target = module.static_site.data.aws_iam_policy_document.cloudfront_s3_read[0]

    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  override_data {
    target = module.static_site.data.aws_iam_policy_document.cloudfront_s3_read_explicit[0]

    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

run "inquiry_can_be_explicitly_disabled" {
  command = plan

  variables {
    enable_inquiry                    = false
    enable_inquiry_operational_alarms = false
  }

  assert {
    condition     = output.inquiry_enabled == false
    error_message = "Production inquiry must report disabled when explicitly disabled."
  }

  assert {
    condition     = output.inquiry_api_endpoint == null
    error_message = "Explicitly disabled production inquiry must not expose an API endpoint."
  }

  assert {
    condition     = output.inquiry_lambda_function_name == null
    error_message = "Explicitly disabled production inquiry must not expose a Lambda function."
  }

  assert {
    condition     = output.inquiry_sns_topic_arn == null
    error_message = "Explicitly disabled production inquiry must not expose an SNS topic."
  }


  assert {
    condition     = output.inquiry_operational_alarms_enabled == false
    error_message = "Operational alarms must remain disabled when the production inquiry is disabled."
  }

  assert {
    condition     = output.inquiry_operational_alarm_topic_arn == null
    error_message = "Disabled production monitoring must not expose an operations SNS topic."
  }

  assert {
    condition     = length(output.inquiry_operational_alarm_arns) == 0
    error_message = "Disabled production monitoring must expose no inquiry operational alarm ARNs."
  }
}
