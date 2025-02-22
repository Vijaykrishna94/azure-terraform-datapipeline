# Retrieve information about the current user.
data "databricks_current_user" "me" {}

########################################################################################################## SET UP ####################################################################################################
resource "databricks_notebook" "rcm_audit_ddl_notebook" {
  path     = "${data.databricks_current_user.me.home}/1. Set up/1. audit_ddl.py"
  language = "PYTHON"
  source   = "1. Set up/1. audit_ddl.py"
}

resource "databricks_notebook" "rcm_adls_mount_notebook" {
  path     = "${data.databricks_current_user.me.home}/1. Set up/2. adls_mount.py"
  language = "PYTHON"
  source   = "1. Set up/2. adls_mount.py"
}

####################################################################################################### API Exracts ###############################################################################################
resource "databricks_notebook" "rcm_icd_code_api_extract_notebook" {
  path     = "${data.databricks_current_user.me.home}/2. API extracts/ICD Code API extract.ipynb"
  language = "PYTHON"
  source   = "2. API extracts/ICD Code API extract.ipynb"
}

resource "databricks_notebook" "rcm_npi_api_notebook" {
  path     = "${data.databricks_current_user.me.home}/2. API extracts/NPI API extract.ipynb"
  language = "PYTHON"
  source   = "2. API extracts/NPI API extract.ipynb"
}



####################################################################################################### Silver ###############################################################################################


resource "databricks_notebook" "rcm_claims_notebook" {
  path     = "${data.databricks_current_user.me.home}/3. Silver/Claims.py"
  language = "PYTHON"
  source   = "3. Silver/Claims.py"
}
resource "databricks_notebook" "rcm_cpt_codes_notebook" {
  path     = "${data.databricks_current_user.me.home}/3. Silver/CPT codes.py"
  language = "PYTHON"
  source   = "3. Silver/CPT codes.py"
}
resource "databricks_notebook" "rcm_departments_f_notebook" {
  path     = "${data.databricks_current_user.me.home}/3. Silver/Departments_F.py"
  language = "PYTHON"
  source   = "3. Silver/Departments_F.py"
}
resource "databricks_notebook" "rcm_encounters_notebook" {
  path     = "${data.databricks_current_user.me.home}/3. Silver/Encounters.py"
  language = "PYTHON"
  source   = "3. Silver/Encounters.py"
}
resource "databricks_notebook" "rcm_patient_notebook" {
  path     = "${data.databricks_current_user.me.home}/3. Silver/Patient.py"
  language = "PYTHON"
  source   = "3. Silver/Patient.py"
}
resource "databricks_notebook" "rcm_providers_f_notebook" {
  path     = "${data.databricks_current_user.me.home}/3. Silver/Providers_F.py"
  language = "PYTHON"
  source   = "3. Silver/Providers_F.py"
}
resource "databricks_notebook" "rcm_transactions_notebook" {
  path     = "${data.databricks_current_user.me.home}/3. Silver/Transactions.py"
  language = "PYTHON"
  source   = "3. Silver/Transactions.py"
}
resource "databricks_notebook" "rcm_npi_notebook" {
  path     = "${data.databricks_current_user.me.home}/3. Silver/NPI.ipynb"
  language = "PYTHON"
  source   = "3. Silver/NPI.ipynb"
}
resource "databricks_notebook" "rcm_icd_code_notebook" {
  path     = "${data.databricks_current_user.me.home}/3. Silver/ICD Code.ipynb"
  language = "PYTHON"
  source   = "3. Silver/ICD Code.ipynb"
}



####################################################################################################### Gold ###############################################################################################
resource "databricks_notebook" "rcm_business_logic_notebook" {
  path     = "${data.databricks_current_user.me.home}/4. Gold/business_logic.ipynb"
  language = "PYTHON"
  source   = "4. Gold/business_logic.ipynb"
}
resource "databricks_notebook" "rcm_dim_cpt_code_notebook" {
  path     = "${data.databricks_current_user.me.home}/4. Gold/dim_cpt_code.py"
  language = "PYTHON"
  source   = "4. Gold/dim_cpt_code.py"
}
resource "databricks_notebook" "rcm_dim_department_notebook" {
  path     = "${data.databricks_current_user.me.home}/4. Gold/dim_department.py"
  language = "PYTHON"
  source   = "4. Gold/dim_department.py"
}
resource "databricks_notebook" "rcm_dim_icd_code_notebook" {
  path     = "${data.databricks_current_user.me.home}/4. Gold/dim_icd_code.ipynb"
  language = "PYTHON"
  source   = "4. Gold/dim_icd_code.ipynb"
}
resource "databricks_notebook" "rcm_dim_npi_notebook" {
  path     = "${data.databricks_current_user.me.home}/4. Gold/dim_npi.ipynb"
  language = "PYTHON"
  source   = "4. Gold/dim_npi.ipynb"
}
resource "databricks_notebook" "rcm_dim_patient_notebook" {
  path     = "${data.databricks_current_user.me.home}/4. Gold/dim_patient.py"
  language = "PYTHON"
  source   = "4. Gold/dim_patient.py"
}
resource "databricks_notebook" "rcm_dim_provider_notebook" {
  path     = "${data.databricks_current_user.me.home}/4. Gold/dim_provider.py"
  language = "PYTHON"
  source   = "4. Gold/dim_provider.py"
}
