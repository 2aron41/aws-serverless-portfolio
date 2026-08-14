from __future__ import annotations

import importlib.util
import json
import os
import pathlib
import sys
import unittest
from unittest.mock import MagicMock, patch

from botocore.exceptions import (
    ClientError,
    EndpointConnectionError,
)


MODULE_PATH = (
    pathlib.Path(__file__).resolve().parents[1]
    / "lambda_src"
    / "inquiry_handler.py"
)

SPEC = importlib.util.spec_from_file_location(
    "inquiry_handler",
    MODULE_PATH,
)

handler = importlib.util.module_from_spec(SPEC)

sys.modules[SPEC.name] = handler

assert SPEC.loader is not None
SPEC.loader.exec_module(handler)


def make_event(
    body: object,
    method: str = "POST",
    *,
    base64_encoded: bool = False,
) -> dict:
    if isinstance(body, str):
        encoded_body = body
    else:
        encoded_body = json.dumps(body)

    return {
        "version": "2.0",
        "requestContext": {
            "http": {
                "method": method,
            }
        },
        "isBase64Encoded": base64_encoded,
        "body": encoded_body,
    }


def valid_payload() -> dict[str, str]:
    return {
        "name": "Aaron Visitor",
        "email": "visitor@example.com",
        "message": (
            "I would like to discuss a cloud engineering opportunity."
        ),
    }


class TestParseRequest(unittest.TestCase):
    def test_valid_request_is_trimmed(self):
        payload = {
            "name": "  Aaron Visitor  ",
            "email": "  visitor@example.com  ",
            "message": (
                "  I would like to discuss a cloud opportunity.  "
            ),
        }

        result = handler.parse_request(
            make_event(payload)
        )

        self.assertEqual(
            result,
            {
                "name": "Aaron Visitor",
                "email": "visitor@example.com",
                "message": (
                    "I would like to discuss a cloud opportunity."
                ),
            },
        )

    def test_rejects_malformed_json(self):
        event = make_event(
            '{"name":',
        )

        with self.assertRaises(handler.ValidationError):
            handler.parse_request(event)

    def test_rejects_missing_field(self):
        payload = valid_payload()
        del payload["email"]

        with self.assertRaises(handler.ValidationError):
            handler.parse_request(
                make_event(payload)
            )

    def test_rejects_extra_field(self):
        payload = valid_payload()
        payload["admin"] = "true"

        with self.assertRaises(handler.ValidationError):
            handler.parse_request(
                make_event(payload)
            )

    def test_rejects_non_string_field(self):
        payload = valid_payload()
        payload["name"] = 123

        with self.assertRaises(handler.ValidationError):
            handler.parse_request(
                make_event(payload)
            )

    def test_rejects_invalid_email(self):
        payload = valid_payload()
        payload["email"] = "not-an-email"

        with self.assertRaises(handler.ValidationError):
            handler.parse_request(
                make_event(payload)
            )

    def test_rejects_short_message(self):
        payload = valid_payload()
        payload["message"] = "Too short"

        with self.assertRaises(handler.ValidationError):
            handler.parse_request(
                make_event(payload)
            )

    def test_rejects_oversized_message(self):
        payload = valid_payload()
        payload["message"] = "x" * (
            handler.MESSAGE_MAX_LENGTH + 1
        )

        with self.assertRaises(handler.ValidationError):
            handler.parse_request(
                make_event(payload)
            )

    def test_rejects_base64_body(self):
        event = make_event(
            valid_payload(),
            base64_encoded=True,
        )

        with self.assertRaises(handler.ValidationError):
            handler.parse_request(event)

    def test_rejects_multiline_name(self):
        payload = valid_payload()
        payload["name"] = "Aaron\nVisitor"

        with self.assertRaises(handler.ValidationError):
            handler.parse_request(
                make_event(payload)
            )


class TestLambdaHandler(unittest.TestCase):
    def test_wrong_method_returns_405_without_sns(self):
        event = make_event(
            valid_payload(),
            method="GET",
        )

        with patch.object(
            handler.boto3,
            "client",
        ) as client:
            response = handler.lambda_handler(
                event,
                None,
            )

        self.assertEqual(
            response["statusCode"],
            405,
        )

        client.assert_not_called()

    def test_valid_request_publishes_and_returns_202(self):
        topic_arn = (
            "arn:aws:sns:us-east-1:"
            "510497448584:portfolio-test-inquiries"
        )

        sns = MagicMock()

        with (
            patch.dict(
                os.environ,
                {
                    handler.INQUIRY_TOPIC_ENV:
                        topic_arn,
                },
                clear=True,
            ),
            patch.object(
                handler.boto3,
                "client",
                return_value=sns,
            ) as client,
        ):
            response = handler.lambda_handler(
                make_event(valid_payload()),
                None,
            )

        self.assertEqual(
            response["statusCode"],
            202,
        )

        body = json.loads(response["body"])

        self.assertEqual(
            body,
            {
                "message": "Inquiry received.",
            },
        )

        client.assert_called_once_with("sns")
        sns.publish.assert_called_once()

        publish = sns.publish.call_args.kwargs

        self.assertEqual(
            publish["TopicArn"],
            topic_arn,
        )

        self.assertEqual(
            publish["Subject"],
            "New portfolio inquiry",
        )

        self.assertIn(
            "Aaron Visitor",
            publish["Message"],
        )

        self.assertIn(
            "visitor@example.com",
            publish["Message"],
        )

        self.assertIn(
            "cloud engineering opportunity",
            publish["Message"],
        )

    def test_missing_topic_returns_500_without_sns_client(self):
        with (
            patch.dict(
                os.environ,
                {},
                clear=True,
            ),
            patch.object(
                handler.boto3,
                "client",
            ) as client,
        ):
            response = handler.lambda_handler(
                make_event(valid_payload()),
                None,
            )

        self.assertEqual(
            response["statusCode"],
            500,
        )

        client.assert_not_called()

        body = json.loads(response["body"])

        self.assertEqual(
            body,
            {
                "message": "Unable to process inquiry.",
            },
        )

    def test_client_error_returns_500(self):
        sns = MagicMock()

        sns.publish.side_effect = ClientError(
            {
                "Error": {
                    "Code": "AccessDeniedException",
                    "Message": "denied",
                }
            },
            "Publish",
        )

        with (
            patch.dict(
                os.environ,
                {
                    handler.INQUIRY_TOPIC_ENV:
                        "arn:aws:sns:us-east-1:"
                        "510497448584:test",
                },
                clear=True,
            ),
            patch.object(
                handler.boto3,
                "client",
                return_value=sns,
            ),
        ):
            response = handler.lambda_handler(
                make_event(valid_payload()),
                None,
            )

        self.assertEqual(
            response["statusCode"],
            500,
        )

        body = json.loads(response["body"])

        self.assertEqual(
            body,
            {
                "message": "Unable to process inquiry.",
            },
        )

    def test_sdk_error_returns_500(self):
        sns = MagicMock()

        sns.publish.side_effect = (
            EndpointConnectionError(
                endpoint_url=(
                    "https://sns.us-east-1.amazonaws.com"
                )
            )
        )

        with (
            patch.dict(
                os.environ,
                {
                    handler.INQUIRY_TOPIC_ENV:
                        "arn:aws:sns:us-east-1:"
                        "510497448584:test",
                },
                clear=True,
            ),
            patch.object(
                handler.boto3,
                "client",
                return_value=sns,
            ),
        ):
            response = handler.lambda_handler(
                make_event(valid_payload()),
                None,
            )

        self.assertEqual(
            response["statusCode"],
            500,
        )

        body = json.loads(response["body"])

        self.assertEqual(
            body,
            {
                "message": "Unable to process inquiry.",
            },
        )


class TestPrivacyBoundaries(unittest.TestCase):
    def test_invalid_request_returns_generic_400_without_sns(self):
        payload = valid_payload()
        payload["email"] = "private-invalid-email"

        with patch.object(
            handler.boto3,
            "client",
        ) as client:
            response = handler.lambda_handler(
                make_event(payload),
                None,
            )

        self.assertEqual(
            response["statusCode"],
            400,
        )

        body = json.loads(response["body"])

        self.assertEqual(
            body,
            {
                "message": "Invalid inquiry request.",
            },
        )

        self.assertNotIn(
            "private-invalid-email",
            response["body"],
        )

        client.assert_not_called()

    def test_aws_failure_log_excludes_visitor_content(self):
        canary = "PRIVATE-CANARY-DO-NOT-LOG"

        payload = {
            "name": "Private Visitor",
            "email": "private@example.com",
            "message": (
                "Please keep this private "
                + canary
            ),
        }

        sns = MagicMock()

        sns.publish.side_effect = ClientError(
            {
                "Error": {
                    "Code": "AccessDeniedException",
                    "Message": "denied",
                }
            },
            "Publish",
        )

        with (
            patch.dict(
                os.environ,
                {
                    handler.INQUIRY_TOPIC_ENV:
                        "arn:aws:sns:us-east-1:"
                        "510497448584:test",
                },
                clear=True,
            ),
            patch.object(
                handler.boto3,
                "client",
                return_value=sns,
            ),
            self.assertLogs(
                handler.LOGGER.name,
                level="ERROR",
            ) as captured,
        ):
            response = handler.lambda_handler(
                make_event(payload),
                None,
            )

        logs = "\n".join(captured.output)

        self.assertEqual(
            response["statusCode"],
            500,
        )

        self.assertEqual(
            json.loads(response["body"]),
            {
                "message": "Unable to process inquiry.",
            },
        )

        self.assertIn(
            "AccessDeniedException",
            logs,
        )

        self.assertNotIn(
            "Private Visitor",
            logs,
        )

        self.assertNotIn(
            "private@example.com",
            logs,
        )

        self.assertNotIn(
            canary,
            logs,
        )


if __name__ == "__main__":
    unittest.main()
