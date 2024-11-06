resource "aws_iam_role" "ec2_ssm_role" {
  name = "EC2SSMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "s3-bucket-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::my-terraform-state-files-bucket",
          "arn:aws:s3:::my-terraform-state-files-bucket/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_ssm_role.name
}

# Attach the S3 Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "s3_attachment" {
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
  role       = aws_iam_role.ec2_ssm_role.name
}

# IAM Instance Profile to associate the role with EC2 instances
resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = "EC2SSMInstanceProfile"
  role = aws_iam_role.ec2_ssm_role.name
}
