# #Delete the items in the bucket before destorying
# resource "null_resource" "delete_bucket_objects" {
#   provisioner "local-exec" {
#     command = "aws s3 rm s3://${aws_s3_bucket.s3bucket.bucket} --recursive"
#   }

#   triggers = {
#     bucket_name = aws_s3_bucket.s3bucket.bucket
#   }
# }


data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "s3bucket" {
  bucket = "${var.aws_config.region}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  //depends_on = [null_resource.delete_bucket_objects]
}

