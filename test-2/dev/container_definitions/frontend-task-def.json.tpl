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
    "name": "fe-container",
    "image": "${frontend_image_uri}",
    "portMappings": [
      {
        "containerPort": 80,
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awsfirelens",
      "options": {
        "Name": "opensearch",
        "Host": "${opensearch_endpoint}",
        "Port": "443",
        "Index": "fullstack-logs-fe",
        "AWS_Auth": "On",
        "aws_region": "${region}",
        "Suppress_Type_Name": "On",
        "tls": "on"
      }
    },
    "environment": [
      {
        "value": "${backend_url}",
        "name": "VITE_BACKEND_URL"
      }
    ]
  }
]
