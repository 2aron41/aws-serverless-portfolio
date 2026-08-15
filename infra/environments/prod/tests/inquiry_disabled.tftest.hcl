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

run "inquiry_disabled_by_default" {
  command = plan

  assert {
    condition     = output.inquiry_enabled == false
    error_message = "Production inquiry must remain disabled by default."
  }

  assert {
    condition     = output.inquiry_api_endpoint == null
    error_message = "Disabled production inquiry must not expose an API endpoint."
  }

  assert {
    condition     = output.inquiry_lambda_function_name == null
    error_message = "Disabled production inquiry must not expose a Lambda function."
  }

  assert {
    condition     = output.inquiry_sns_topic_arn == null
    error_message = "Disabled production inquiry must not expose an SNS topic."
  }
}
