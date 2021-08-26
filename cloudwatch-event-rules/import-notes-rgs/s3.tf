resource "aws_s3_bucket_object" "import_notes_install_dependencies" {
  bucket = "${var.dsci_import_notes_bucket_name}"
  key    = "scripts/EMR/import_notes_install_dependencies.sh"
  source = "${path.module}/scripts/import_notes_install_dependencies.sh"
  etag   = "${md5(file("${path.module}/scripts/import_notes_install_dependencies.sh"))}"

  tags = "${var.tags}"
}

resource "aws_s3_bucket_object" "import_notes_generate_training_set" {
  bucket = "${var.dsci_import_notes_bucket_name}"
  key    = "scripts/EMR/import_notes_generate_training_set.py"
  source = "${path.module}/scripts/import_notes_generate_training_set.py"
  etag   = "${md5(file("${path.module}/scripts/import_notes_generate_training_set.py"))}"

  tags = "${var.tags}"
}
