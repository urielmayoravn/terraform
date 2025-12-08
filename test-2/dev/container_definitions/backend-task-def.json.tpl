[
  {
    "name": "log-router",
    "image": "amazon/aws-for-fluent-bit:latest",
    "essential": true,
    "firelensConfiguration": {
      "type": "fluentbit",
      "options": {
        "enable-ecs-log-metadata": "true"
      }
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  },
  {
    "name": "be-container",
    "image": "${backend_image_uri}",
    "portMappings": [
      {
        "containerPort": 3000,
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awsfirelens",
      "options": {
        "Name": "opensearch",
        "Host": "${opensearch_endpoint}",
        "Port": "443",
        "Index": "fullstack-logs-be",
        "AWS_Auth": "On",
        "aws_region": "${region}",
        "Suppress_Type_Name": "On",
        "tls": "on"
      }
    },
    "depends_on": [
      {
        "containerName": "log-router",
        "condition": "STARTED"
      }
    ],
    "secrets": [
      {
        "valueFrom": "${db_secret_arn}",
        "name": "DATABASE_URL"
      }
    ]
  }
]
