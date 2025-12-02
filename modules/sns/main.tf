resource "aws_sns_topic" "main" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "subscriptions" {
  count                  = length(var.subscriptions)
  topic_arn              = aws_sns_topic.main.arn
  protocol               = var.subscriptions[count.index].protocol
  endpoint               = var.subscriptions[count.index].endpoint
  endpoint_auto_confirms = lookup(var.subscriptions[count.index], "endpoint_auto_confirms", false)
}
