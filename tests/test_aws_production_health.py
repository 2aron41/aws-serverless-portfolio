from __future__ import annotations

import importlib.util
import pathlib
import sys
import unittest
from unittest.mock import MagicMock, patch


MODULE_PATH = (
    pathlib.Path(__file__).resolve().parents[1]
    / "scripts"
    / "aws_production_health.py"
)

SPEC = importlib.util.spec_from_file_location(
    "aws_production_health",
    MODULE_PATH,
)

health = importlib.util.module_from_spec(SPEC)

sys.modules[SPEC.name] = health

assert SPEC.loader is not None
SPEC.loader.exec_module(health)


class TestRequiredTags(unittest.TestCase):
    def test_required_tags_pass(self):
        actual = {
            "Project": "aws-serverless-portfolio",
            "Environment": "prod",
            "ManagedBy": "Terraform",
            "Owner": "2aron41",
            "Purpose": "Production portfolio website",
        }

        passed, detail = health.check_required_tags(
            actual,
            health.EXPECTED_S3_TAGS,
        )

        self.assertTrue(passed)
        self.assertEqual(
            detail,
            "5 required tags present",
        )

    def test_required_tags_fail_on_wrong_value(self):
        actual = dict(health.EXPECTED_S3_TAGS)
        actual["Environment"] = "dev"

        passed, detail = health.check_required_tags(
            actual,
            health.EXPECTED_S3_TAGS,
        )

        self.assertFalse(passed)
        self.assertIn("Environment='dev'", detail)
        self.assertIn("expected 'prod'", detail)


class TestS3PublicAccess(unittest.TestCase):
    def test_public_access_block_passes(self):
        s3 = MagicMock()

        s3.get_public_access_block.return_value = {
            "PublicAccessBlockConfiguration": {
                "BlockPublicAcls": True,
                "IgnorePublicAcls": True,
                "BlockPublicPolicy": True,
                "RestrictPublicBuckets": True,
            }
        }

        result = health.check_s3_public_access(s3)

        self.assertTrue(result.passed)
        self.assertEqual(
            result.detail,
            "all four controls enabled",
        )

    def test_public_access_block_fails_when_control_disabled(self):
        s3 = MagicMock()

        s3.get_public_access_block.return_value = {
            "PublicAccessBlockConfiguration": {
                "BlockPublicAcls": True,
                "IgnorePublicAcls": True,
                "BlockPublicPolicy": False,
                "RestrictPublicBuckets": True,
            }
        }

        result = health.check_s3_public_access(s3)

        self.assertFalse(result.passed)
        self.assertIn(
            "BlockPublicPolicy",
            result.detail,
        )


class TestCloudFront(unittest.TestCase):
    def test_distribution_passes_when_deployed_and_enabled(self):
        cloudfront = MagicMock()

        cloudfront.get_distribution.return_value = {
            "Distribution": {
                "Status": "Deployed",
                "DistributionConfig": {
                    "Enabled": True,
                },
            }
        }

        result = health.check_cloudfront(cloudfront)

        self.assertTrue(result.passed)

    def test_distribution_fails_when_disabled(self):
        cloudfront = MagicMock()

        cloudfront.get_distribution.return_value = {
            "Distribution": {
                "Status": "Deployed",
                "DistributionConfig": {
                    "Enabled": False,
                },
            }
        }

        result = health.check_cloudfront(cloudfront)

        self.assertFalse(result.passed)
        self.assertIn("disabled", result.detail)


class TestAlarm(unittest.TestCase):
    def test_alarm_passes_when_ok_and_enabled(self):
        cloudwatch = MagicMock()

        cloudwatch.describe_alarms.return_value = {
            "MetricAlarms": [
                {
                    "StateValue": "OK",
                    "ActionsEnabled": True,
                }
            ]
        }

        result = health.check_alarm(cloudwatch)

        self.assertTrue(result.passed)

    def test_alarm_fails_when_in_alarm(self):
        cloudwatch = MagicMock()

        cloudwatch.describe_alarms.return_value = {
            "MetricAlarms": [
                {
                    "StateValue": "ALARM",
                    "ActionsEnabled": True,
                }
            ]
        }

        result = health.check_alarm(cloudwatch)

        self.assertFalse(result.passed)
        self.assertIn("ALARM", result.detail)


class TestHttpChecks(unittest.TestCase):
    @patch.object(
        health,
        "http_status",
        return_value=200,
    )
    def test_cloudfront_http_passes(self, _mock_status):
        result = health.check_cloudfront_http()

        self.assertTrue(result.passed)

    @patch.object(
        health,
        "http_status",
        return_value=403,
    )
    def test_direct_s3_http_passes(self, _mock_status):
        result = health.check_direct_s3_http()

        self.assertTrue(result.passed)

    @patch.object(
        health,
        "http_status",
        return_value=200,
    )
    def test_direct_s3_http_fails_if_public(self, _mock_status):
        result = health.check_direct_s3_http()

        self.assertFalse(result.passed)
        self.assertIn("expected 403", result.detail)


class TestSafeCheck(unittest.TestCase):
    def test_unexpected_exception_becomes_failed_check(self):
        def explode():
            raise RuntimeError("boom")

        result = health.safe_check(
            "example",
            explode,
        )

        self.assertFalse(result.passed)
        self.assertIn("unexpected error", result.detail)
        self.assertIn("boom", result.detail)


class TestMainExitCodes(unittest.TestCase):
    def make_session(self, account=None):
        session = MagicMock()

        credentials = MagicMock()
        credentials.method = "test"
        session.get_credentials.return_value = credentials

        sts = MagicMock()
        sts.get_caller_identity.return_value = {
            "Account": account or health.EXPECTED_ACCOUNT,
            "Arn": (
                "arn:aws:iam::"
                f"{account or health.EXPECTED_ACCOUNT}:"
                "user/test"
            ),
        }

        clients = {
            "sts": sts,
            "s3": MagicMock(),
            "cloudfront": MagicMock(),
            "cloudwatch": MagicMock(),
        }

        session.client.side_effect = (
            lambda service: clients[service]
        )

        return session

    def test_main_returns_zero_when_all_checks_pass(self):
        session = self.make_session()

        passing = [
            health.pass_result(
                name,
                "simulated pass",
            )
            for name in [
                "S3 bucket",
                "S3 public access block",
                "S3 governance tags",
                "CloudFront distribution",
                "CloudFront governance tags",
                "CloudWatch 5xx alarm",
                "CloudFront public website",
                "Direct S3 access",
            ]
        ]

        with (
            patch.object(
                health.boto3,
                "Session",
                return_value=session,
            ),
            patch.object(
                health,
                "safe_check",
                side_effect=passing,
            ),
        ):
            result = health.main()

        self.assertEqual(result, 0)

    def test_main_returns_one_when_health_check_fails(self):
        session = self.make_session()

        results = [
            health.fail_result(
                "S3 bucket",
                "simulated failure",
            )
        ]

        results.extend(
            health.pass_result(
                name,
                "simulated pass",
            )
            for name in [
                "S3 public access block",
                "S3 governance tags",
                "CloudFront distribution",
                "CloudFront governance tags",
                "CloudWatch 5xx alarm",
                "CloudFront public website",
                "Direct S3 access",
            ]
        )

        with (
            patch.object(
                health.boto3,
                "Session",
                return_value=session,
            ),
            patch.object(
                health,
                "safe_check",
                side_effect=results,
            ),
        ):
            result = health.main()

        self.assertEqual(result, 1)

    def test_main_returns_two_without_credentials(self):
        session = MagicMock()
        session.get_credentials.return_value = None

        with patch.object(
            health.boto3,
            "Session",
            return_value=session,
        ):
            result = health.main()

        self.assertEqual(result, 2)

    def test_main_returns_two_for_wrong_account(self):
        session = self.make_session(
            account="000000000000"
        )

        with patch.object(
            health.boto3,
            "Session",
            return_value=session,
        ):
            result = health.main()

        self.assertEqual(result, 2)


if __name__ == "__main__":
    unittest.main()
