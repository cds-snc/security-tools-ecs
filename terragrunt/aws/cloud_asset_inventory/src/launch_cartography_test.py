import os
import sys
import unittest

try:
    from unittest.mock import ANY, MagicMock
except ImportError:
    from mock import MagicMock


ECS_CLIENT_MOCK = MagicMock()
SSM_CLIENT_MOCK = MagicMock()


class Boto3Mock:
    @staticmethod
    def client(client_name, *args, **kwargs):
        if client_name == "ecs":
            return ECS_CLIENT_MOCK
        if client_name == "ssm":
            return SSM_CLIENT_MOCK
        raise Exception("Attempting to create an unknown client")


sys.modules["boto3"] = Boto3Mock()

LAMBDA = __import__("launch_cartography")


class LambdaTest(unittest.TestCase):
    def setUp(self):
        os.environ["CARTOGRAPHY_ECS_NETWORKING"] = "subnet-12345678,subnet-87654321"
        os.environ["CARTOGRAPHY_ECS_SECURITY_GROUPS"] = "sg-12345678"

    def test_launching_ecs(self):
        ssm_mock('["123456789012", "999456789012"]')
        LAMBDA.handler({}, {})
        SSM_CLIENT_MOCK.get_parameter.assert_called_once()
        ECS_CLIENT_MOCK.run_task.assert_called_once_with(
            taskDefinition="cartography",
            launchType="FARGATE",
            cluster="cartography",
            platformVersion="LATEST",
            count=1,
            networkConfiguration={
                "awsvpcConfiguration": {
                    "subnets": ["subnet-12345678", "subnet-87654321"],
                    "securityGroups": ["sg-12345678"],
                }
            },
            overrides={
                "containerOverrides": [
                    {
                        "name": "cartography",
                        "environment": [
                            {
                                "name": "AWS_CONFIG_FILE",
                                "value": "/config/role_config",
                            },
                            {
                                "name": "NEO4J_URI",
                                "value": "bolt://neo4j.internal.local:7687",
                            },
                            {"name": "NEO4J_USER", "value": "neo4j"},
                            {
                                "name": "AWS_PROFILE_DATA",
                                "value": ANY,
                            },
                        ],
                    }
                ]
            },
        )


# Helper Functions
def ssm_mock(accounts):
    get_parameter = {
        "Parameter": {
            "Name": "foo",
            "Type": "SecureString",
            "Value": accounts,
            "Version": 123,
        }
    }
    SSM_CLIENT_MOCK.reset_mock(return_value=True)
    SSM_CLIENT_MOCK.get_parameter = MagicMock(return_value=get_parameter)
