resource "aws_s3_bucket" "dsci_import_notes_bucket" {
  bucket = "${local.dsci_import_notes_bucket_name}"
  acl    = "private"

  tags = "${var.default_tags}"
}
