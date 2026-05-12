resource "aws_iam_role" "cloudwatch_observability" {
  name = "${var.environment_name}-cloudwatch-observability"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks_cluster.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks_cluster.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
            "${replace(module.eks_cluster.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
          }
        }
      }
    ]
  })

  tags = var.tags

  depends_on = [module.eks_cluster]
}

resource "aws_iam_role_policy_attachment" "cloudwatch_observability" {
  role       = aws_iam_role.cloudwatch_observability.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_observability_xray" {
  role       = aws_iam_role.cloudwatch_observability.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = module.eks_cluster.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  service_account_role_arn    = aws_iam_role.cloudwatch_observability.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    agent = {
      config = {
        logs = {
          metrics_collected = {
            application_signals = {}
            kubernetes = {
              enhanced_container_insights = true
            }
          }
        }
        traces = {
          traces_collected = {
            application_signals = {}
          }
        }
      }
    }
    containerLogs = {
      enabled = true
    }
  })

  tags = var.tags

  depends_on = [
    module.eks_cluster,
    aws_iam_role.cloudwatch_observability,
    aws_iam_role_policy_attachment.cloudwatch_observability,
    aws_iam_role_policy_attachment.cloudwatch_observability_xray
  ]
}
