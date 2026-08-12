#!/usr/bin/env python3

"""Read-only production health checks for the AWS portfolio site."""

from __future__ import annotations

import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Callable

import boto3
from botocore.exceptions import BotoCoreError, ClientError


EXPECTED_ACCOUNT = "510497448584"
REGION = "us-east-1"

BUCKET = "2aron41-aws-portfolio-20260713"
DISTRIBUTION_ID = "EUWNERX790PYN"
DISTRIBUTION_DOMAIN = "d1wnw5kep14m5j.cloudfront.net"

ALARM_NAME = (
    "2aron41-aws-portfolio-20260713-"
    "cloudfront-5xx-error-rate"
)

EXPECTED_S3_TAGS = {
    "Project": "aws-serverless-portfolio",
    "Environment": "prod",
    "ManagedBy": "Terraform",
    "Owner": "2aron41",
    "Purpose": "Production portfolio website",
}

EXPECTED_CLOUDFRONT_TAGS = {
    **EXPECTED_S3_TAGS,
    "Name": "aaron-portfolio-cdn",
}


@dataclass
class CheckResult:
    name: str
    passed: bool
    detail: str


def pass_result(name: str, detail: str) -> CheckResult:
    return CheckResult(name=name, passed=True, detail=detail)


def fail_result(name: str, detail: str) -> CheckResult:
    return CheckResult(name=name, passed=False, detail=detail)


def check_required_tags(
    actual: dict[str, str],
    required: dict[str, str],
) -> tuple[bool, str]:
    problems = []

    for key, expected_value in required.items():
        actual_value = actual.get(key)

        if actual_value != expected_value:
            problems.append(
                f"{key}={actual_value!r}, expected {expected_value!r}"
            )

    if problems:
        return False, "; ".join(problems)

    return True, f"{len(required)} required tags present"


def check_s3_bucket(s3) -> CheckResult:
    name = "S3 bucket"

    try:
        s3.head_bucket(Bucket=BUCKET)
    except (BotoCoreError, ClientError) as exc:
        return fail_result(name, str(exc))

    return pass_result(name, f"{BUCKET} reachable")


def check_s3_public_access(s3) -> CheckResult:
    name = "S3 public access block"

    try:
        config = s3.get_public_access_block(
            Bucket=BUCKET
        )["PublicAccessBlockConfiguration"]
    except (BotoCoreError, ClientError) as exc:
        return fail_result(name, str(exc))

    required = (
        "BlockPublicAcls",
        "IgnorePublicAcls",
        "BlockPublicPolicy",
        "RestrictPublicBuckets",
    )

    disabled = [
        key
        for key in required
        if config.get(key) is not True
    ]

    if disabled:
        return fail_result(
            name,
            "not enabled: " + ", ".join(disabled),
        )

    return pass_result(
        name,
        "all four controls enabled",
    )


def check_s3_tags(s3) -> CheckResult:
    name = "S3 governance tags"

    try:
        tag_set = s3.get_bucket_tagging(
            Bucket=BUCKET
        )["TagSet"]
    except (BotoCoreError, ClientError) as exc:
        return fail_result(name, str(exc))

    actual = {
        item["Key"]: item["Value"]
        for item in tag_set
    }

    passed, detail = check_required_tags(
        actual,
        EXPECTED_S3_TAGS,
    )

    if not passed:
        return fail_result(name, detail)

    return pass_result(name, detail)


def check_cloudfront(cloudfront) -> CheckResult:
    name = "CloudFront distribution"

    try:
        distribution = cloudfront.get_distribution(
            Id=DISTRIBUTION_ID
        )["Distribution"]
    except (BotoCoreError, ClientError) as exc:
        return fail_result(name, str(exc))

    status = distribution["Status"]
    enabled = distribution["DistributionConfig"]["Enabled"]

    if status != "Deployed":
        return fail_result(
            name,
            f"status={status!r}, expected 'Deployed'",
        )

    if enabled is not True:
        return fail_result(
            name,
            "distribution is disabled",
        )

    return pass_result(
        name,
        "Deployed and enabled",
    )


def check_cloudfront_tags(cloudfront) -> CheckResult:
    name = "CloudFront governance tags"

    try:
        distribution = cloudfront.get_distribution(
            Id=DISTRIBUTION_ID
        )["Distribution"]

        items = cloudfront.list_tags_for_resource(
            Resource=distribution["ARN"]
        )["Tags"].get("Items", [])
    except (BotoCoreError, ClientError) as exc:
        return fail_result(name, str(exc))

    actual = {
        item["Key"]: item["Value"]
        for item in items
    }

    passed, detail = check_required_tags(
        actual,
        EXPECTED_CLOUDFRONT_TAGS,
    )

    if not passed:
        return fail_result(name, detail)

    return pass_result(name, detail)


def check_alarm(cloudwatch) -> CheckResult:
    name = "CloudWatch 5xx alarm"

    try:
        alarms = cloudwatch.describe_alarms(
            AlarmNames=[ALARM_NAME]
        )["MetricAlarms"]
    except (BotoCoreError, ClientError) as exc:
        return fail_result(name, str(exc))

    if len(alarms) != 1:
        return fail_result(
            name,
            f"expected 1 alarm, found {len(alarms)}",
        )

    alarm = alarms[0]

    state = alarm["StateValue"]
    actions_enabled = alarm["ActionsEnabled"]

    if state != "OK":
        return fail_result(
            name,
            f"state={state!r}, expected 'OK'",
        )

    if not actions_enabled:
        return fail_result(
            name,
            "alarm actions are disabled",
        )

    return pass_result(
        name,
        "state OK and actions enabled",
    )


def http_status(url: str) -> int:
    request = urllib.request.Request(
        url,
        method="GET",
        headers={
            "User-Agent": "aws-production-health/1.0",
        },
    )

    try:
        with urllib.request.urlopen(
            request,
            timeout=10,
        ) as response:
            return response.status
    except urllib.error.HTTPError as exc:
        return exc.code


def check_cloudfront_http() -> CheckResult:
    name = "CloudFront public website"

    url = f"https://{DISTRIBUTION_DOMAIN}/"

    try:
        status = http_status(url)
    except (OSError, urllib.error.URLError) as exc:
        return fail_result(name, str(exc))

    if status != 200:
        return fail_result(
            name,
            f"HTTP {status}, expected 200",
        )

    return pass_result(name, "HTTP 200")


def check_direct_s3_http() -> CheckResult:
    name = "Direct S3 access"

    url = (
        f"https://{BUCKET}.s3.{REGION}."
        "amazonaws.com/index.html"
    )

    try:
        status = http_status(url)
    except (OSError, urllib.error.URLError) as exc:
        return fail_result(name, str(exc))

    if status != 403:
        return fail_result(
            name,
            f"HTTP {status}, expected 403",
        )

    return pass_result(
        name,
        "HTTP 403 — private origin preserved",
    )


def safe_check(
    name: str,
    function: Callable[[], CheckResult],
) -> CheckResult:
    try:
        return function()
    except Exception as exc:
        return fail_result(
            name,
            f"unexpected error: {exc}",
        )


def print_results(results: list[CheckResult]) -> None:
    width = max(len(result.name) for result in results)

    print()
    print("Production health checks")
    print("=" * 72)

    for result in results:
        status = "PASS" if result.passed else "FAIL"

        print(
            f"{result.name:<{width}}  "
            f"{status:<4}  "
            f"{result.detail}"
        )

    print("=" * 72)


def main() -> int:
    print("AWS Production Health")
    print("=====================")
    print(f"Region: {REGION}")

    session = boto3.Session(region_name=REGION)

    credentials = session.get_credentials()

    if credentials is None:
        print(
            "FATAL: No AWS credentials available.",
            file=sys.stderr,
        )
        return 2

    print(
        "Credential provider:",
        getattr(credentials, "method", "unknown"),
    )

    sts = session.client("sts")

    try:
        identity = sts.get_caller_identity()
    except (BotoCoreError, ClientError) as exc:
        print(
            f"FATAL: Could not verify AWS identity: {exc}",
            file=sys.stderr,
        )
        return 2

    account = identity["Account"]

    print(f"AWS account: {account}")

    if account != EXPECTED_ACCOUNT:
        print(
            "FATAL: Wrong AWS account. "
            f"Expected {EXPECTED_ACCOUNT}, got {account}.",
            file=sys.stderr,
        )
        return 2

    s3 = session.client("s3")
    cloudfront = session.client("cloudfront")
    cloudwatch = session.client("cloudwatch")

    checks = [
        (
            "S3 bucket",
            lambda: check_s3_bucket(s3),
        ),
        (
            "S3 public access block",
            lambda: check_s3_public_access(s3),
        ),
        (
            "S3 governance tags",
            lambda: check_s3_tags(s3),
        ),
        (
            "CloudFront distribution",
            lambda: check_cloudfront(cloudfront),
        ),
        (
            "CloudFront governance tags",
            lambda: check_cloudfront_tags(cloudfront),
        ),
        (
            "CloudWatch 5xx alarm",
            lambda: check_alarm(cloudwatch),
        ),
        (
            "CloudFront public website",
            check_cloudfront_http,
        ),
        (
            "Direct S3 access",
            check_direct_s3_http,
        ),
    ]

    results = [
        safe_check(name, function)
        for name, function in checks
    ]

    print_results(results)

    failures = [
        result
        for result in results
        if not result.passed
    ]

    print()

    if failures:
        print(
            f"Overall production health: FAIL "
            f"({len(failures)} check(s) failed)"
        )
        return 1

    print("Overall production health: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
