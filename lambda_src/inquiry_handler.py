"""Portfolio inquiry Lambda handler."""

from __future__ import annotations

import json
import logging
import os
import re
from typing import Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError


LOGGER = logging.getLogger(__name__)

INQUIRY_TOPIC_ENV = "INQUIRY_TOPIC_ARN"

ALLOWED_FIELDS = {
    "name",
    "email",
    "message",
}

NAME_MIN_LENGTH = 2
NAME_MAX_LENGTH = 100

EMAIL_MIN_LENGTH = 3
EMAIL_MAX_LENGTH = 254

MESSAGE_MIN_LENGTH = 10
MESSAGE_MAX_LENGTH = 2000

EMAIL_PATTERN = re.compile(
    r"^[^@\s]+@[^@\s]+\.[^@\s]+$"
)


class ValidationError(ValueError):
    """Raised when an inquiry request is invalid."""


def json_response(
    status_code: int,
    message: str,
) -> dict[str, Any]:
    """Create an API Gateway-compatible JSON response."""

    return {
        "statusCode": status_code,
        "headers": {
            "content-type": "application/json",
        },
        "body": json.dumps(
            {
                "message": message,
            }
        ),
    }


def request_method(
    event: dict[str, Any],
) -> str | None:
    """Return the HTTP method from an HTTP API v2 event."""

    request_context = event.get("requestContext")

    if not isinstance(request_context, dict):
        return None

    http = request_context.get("http")

    if not isinstance(http, dict):
        return None

    method = http.get("method")

    if not isinstance(method, str):
        return None

    return method.upper()


def parse_request(
    event: dict[str, Any],
) -> dict[str, str]:
    """Parse and validate an inquiry request."""

    if event.get("isBase64Encoded") is True:
        raise ValidationError(
            "Base64-encoded request bodies are not supported."
        )

    body = event.get("body")

    if not isinstance(body, str) or not body.strip():
        raise ValidationError(
            "Request body must contain JSON."
        )

    try:
        payload = json.loads(body)
    except json.JSONDecodeError as exc:
        raise ValidationError(
            "Request body must contain valid JSON."
        ) from exc

    if not isinstance(payload, dict):
        raise ValidationError(
            "Request JSON must be an object."
        )

    if set(payload) != ALLOWED_FIELDS:
        raise ValidationError(
            "Request must contain exactly name, email, and message."
        )

    if not all(
        isinstance(payload[field], str)
        for field in ALLOWED_FIELDS
    ):
        raise ValidationError(
            "Inquiry fields must be strings."
        )

    name = payload["name"].strip()
    email = payload["email"].strip()
    message = payload["message"].strip()

    if not NAME_MIN_LENGTH <= len(name) <= NAME_MAX_LENGTH:
        raise ValidationError(
            "Name length is invalid."
        )

    if "\n" in name or "\r" in name:
        raise ValidationError(
            "Name must be a single line."
        )

    if not EMAIL_MIN_LENGTH <= len(email) <= EMAIL_MAX_LENGTH:
        raise ValidationError(
            "Email length is invalid."
        )

    if not EMAIL_PATTERN.fullmatch(email):
        raise ValidationError(
            "Email format is invalid."
        )

    if not MESSAGE_MIN_LENGTH <= len(message) <= MESSAGE_MAX_LENGTH:
        raise ValidationError(
            "Message length is invalid."
        )

    return {
        "name": name,
        "email": email,
        "message": message,
    }


def format_notification(
    inquiry: dict[str, str],
) -> str:
    """Create the owner notification body."""

    return (
        "New portfolio inquiry\n\n"
        f"Name: {inquiry['name']}\n"
        f"Email: {inquiry['email']}\n\n"
        "Message:\n"
        f"{inquiry['message']}"
    )


def publish_inquiry(
    inquiry: dict[str, str],
) -> None:
    """Publish a validated inquiry to the configured SNS topic."""

    topic_arn = os.environ.get(
        INQUIRY_TOPIC_ENV,
        "",
    ).strip()

    if not topic_arn:
        raise RuntimeError(
            "Inquiry SNS topic is not configured."
        )

    sns = boto3.client("sns")

    sns.publish(
        TopicArn=topic_arn,
        Subject="New portfolio inquiry",
        Message=format_notification(inquiry),
    )


def lambda_handler(
    event: dict[str, Any],
    _context: Any,
) -> dict[str, Any]:
    """Handle a portfolio inquiry request."""

    if request_method(event) != "POST":
        return json_response(
            405,
            "Method not allowed.",
        )

    try:
        inquiry = parse_request(event)
    except ValidationError as exc:
        LOGGER.warning(
            "Inquiry request failed validation: %s",
            exc,
        )

        return json_response(
            400,
            "Invalid inquiry request.",
        )

    try:
        publish_inquiry(inquiry)
    except RuntimeError:
        LOGGER.error(
            "Inquiry notification configuration is unavailable."
        )

        return json_response(
            500,
            "Unable to process inquiry.",
        )
    except ClientError as exc:
        error_code = (
            exc.response
            .get("Error", {})
            .get("Code", "ClientError")
        )

        LOGGER.error(
            "SNS publish failed with AWS error code: %s",
            error_code,
        )

        return json_response(
            500,
            "Unable to process inquiry.",
        )
    except BotoCoreError as exc:
        LOGGER.error(
            "SNS publish failed with SDK error type: %s",
            type(exc).__name__,
        )

        return json_response(
            500,
            "Unable to process inquiry.",
        )

    return json_response(
        202,
        "Inquiry received.",
    )
