import base64
import boto3
import json
from os import environ

ecs = boto3.client("ecs")
ssm = boto3.client("ssm")


def handler(event, context):
    account_list = json.loads(
        ssm.get_parameter(
            Name="/cartography/asset_inventory_account_list", WithDecryption=True
        )["Parameter"]["Value"]
    )
    aws_profile_template = (
        "[profile {account_id}]\n"
        "role_arn = arn:aws:iam::{account_id}:role/secopsAssetInventorySecurityAuditRole\n"  # noqa: E501
        "source_profile = default\n"
        "region = ca-central-1\n"
        "output = json\n\n"
    )
    combined_profile = ""
    for account_id in account_list:
        combined_profile += aws_profile_template.format(account_id=account_id)

    ecs.run_task(
        taskDefinition="cartography",
        launchType="FARGATE",
        cluster="cartography",
        platformVersion="LATEST",
        count=1,
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets": environ.get("CARTOGRAPHY_ECS_NETWORKING").split(","),
                "securityGroups": [environ.get("CARTOGRAPHY_ECS_SECURITY_GROUPS")],
            }
        },
        overrides={
            "containerOverrides": [
                {
                    "name": "cartography",
                    "environment": [
                        {"name": "AWS_CONFIG_FILE", "value": "/config/role_config"},
                        {
                            "name": "NEO4J_URI",
                            "value": "bolt://neo4j.internal.local:7687",
                        },
                        {"name": "NEO4J_USER", "value": "neo4j"},
                        {
                            "name": "AWS_PROFILE_DATA",
                            "value": base64.b64encode(
                                combined_profile.encode("ascii")
                            ).decode("ascii"),
                        },
                    ],
                }
            ]
        },
    )
