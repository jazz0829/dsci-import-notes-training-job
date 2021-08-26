locals {
  name_prefix                                  = "${terraform.workspace}"
  dsci_import_notes_state_machine_name         = "${local.name_prefix}-${var.step_function_name}"
  dsci_import_notes_bucket_name                = "${local.name_prefix}-dsci-import-notes-${var.accountid}-${var.region}"
  dsci_import_notes_sm_role                    = "${local.name_prefix}-dsci-import-notes-sm-role"
  dsci_import_note_rgs_bucket_allow_read_write = "${local.name_prefix}-dsci-import-note-rgs-bucket-allow-read-write"
  dsci_import_notes_endpoint_invoke_policy     = "${local.name_prefix}-dsci-import-notes-endpoint-invoke-policy"
  dsci_sagemaker_import_notes_invoker_for_eol  = "${local.name_prefix}-dsci-sagemaker-import-notes-invoker-for-eol"
  dsci_endpoint_name                           = "${local.name_prefix}-${var.endpoint_name}"
  dsci_state_machine_role                      = "${local.dsci_import_notes_state_machine_name}-assume-role"
  dsci_state_machine_invoke_policy             = "${local.dsci_import_notes_state_machine_name}-invoke-policy"
}
