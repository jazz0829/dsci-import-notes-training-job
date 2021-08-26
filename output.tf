output "secret_in_user" {
  value = "${aws_iam_access_key.in_invoker_key.secret}"
}

output "accesskey_in_user" {
  value = "${aws_iam_access_key.in_invoker_key.id}"
}
