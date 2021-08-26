resource "aws_iam_role" "import_notes_rgs_training" {
  name               = "${local.dsci_import_notes_sm_role}"
  assume_role_policy = "${data.aws_iam_policy_document.import_notes_rgs_training_assume_policy.json}"

  tags = "${var.default_tags}"
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = "${aws_iam_role.import_notes_rgs_training.name}"
  policy_arn = "${data.aws_iam_policy.s3_full_access.arn}"
}

resource "aws_iam_role_policy_attachment" "sm_attach" {
  role       = "${aws_iam_role.import_notes_rgs_training.name}"
  policy_arn = "${data.aws_iam_policy.sagemaker_full_access.arn}"
}

resource "aws_iam_role_policy" "rolepolicy_trained_model" {
  name = "${local.dsci_import_note_rgs_bucket_allow_read_write}"
  role = "${aws_iam_role.import_notes_rgs_training.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "${aws_s3_bucket.dsci_import_notes_bucket.arn}",
                "${aws_s3_bucket.dsci_import_notes_bucket.arn}/*"
             ]
        }
    ]
}
EOF
}

resource "aws_iam_user" "sagemaker_in_user" {
  name = "${local.dsci_sagemaker_import_notes_invoker_for_eol}"

  tags = "${var.default_tags}"
}

resource "aws_iam_user_policy" "in_invoke_policy" {
  name = "${local.dsci_import_notes_endpoint_invoke_policy}"
  user = "${aws_iam_user.sagemaker_in_user.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sagemaker:InvokeEndpoint",
            "Resource": "arn:aws:sagemaker:${var.region}:${var.accountid}:endpoint/${local.dsci_endpoint_name}"
        }
    ]
}
EOF
}

resource "aws_iam_access_key" "in_invoker_key" {
  user = "${aws_iam_user.sagemaker_in_user.name}"
}
