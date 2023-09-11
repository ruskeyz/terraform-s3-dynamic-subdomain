terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.73.0"
    }
  }
  backend "s3" {
    bucket = "terraform-backend.playrcart.app"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
//create private backend bucket manually, with privacy
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "AWS": "arn:aws:iam::<accountid>:root"
#             },
#             "Action": "s3:ListBucket",
#             "Resource": "arn:aws:s3:::<nameofbackendbucket>"
#         },
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "AWS": "arn:aws:iam::<accountid>:root"
#             },
#             "Action": [
#                 "s3:GetObject",
#                 "s3:PutObject"
#             ],
#             "Resource": "arn:aws:s3:::<nameofbackendbucket>/*"
#         }
#     ]
# }