# Data upload script for ProPASS training
# Uploads D1 and df datasets to Opal server

library(opalr)
library(tibble)

# Helper function to upload datasets to Opal server
upload_testing_dataset_table <- function(opal, project_name, table_name, local_file_path, file_type='csv') {
  if (! opal.project_exists(opal, project_name))
    opal.project_create(opal, project_name, database = "mongodb")
  
  if(file_type=='rda'){
    dataset_name <- load(file = local_file_path)
    dataset <- eval(as.symbol(dataset_name))
  }
  if(file_type=='csv'){
    dataset <- read.csv(file = local_file_path)
  }
  
  data <- as_tibble(dataset, rownames = '_row_id_')
  data$`_row_id_` <- as.numeric(data$`_row_id_`)
  
  opal.table_save(opal = opal, data, project_name, table_name, id.name = "_row_id_", force = TRUE)
}

# Login to the Opal demo server
opal <- opal.login('administrator','password', url='https://opal-demo.obiba.org', 
                   opts = list(ssl_verifyhost=0, ssl_verifypeer=0))

# Upload D1 dataset
upload_testing_dataset_table(opal, project_name = 'ProPass', table_name = 'life1', 
                             file_type='rda', local_file_path='scripts/data/D1.rda')

# Upload df dataset
upload_testing_dataset_table(opal, project_name = 'ProPass', table_name = 'df', 
                             file_type='rda', local_file_path='scripts/data/df.rda')

# Server configuration
config_json <- '{
  "name": "Opal",
  "defaultCharSet": "ISO-8859-1", 
  "enforced2FA": false,
  "allowRPackageManagement": true
}'

opal.put(
  opal, "system", "conf", "general",
  body = config_json,
  contentType = "application/json"
)

# Install dsCoda package from GitHub
#opalr::dsadmin.install_github_package(opal, "dsCoda", "datashield", "v0.2.0-dev", "margin-idiom")

# Initialize profile with dsCoda
#opalr::dsadmin.profile_init(opal, "margin-idiom", c("dsBase", "dsSurvival", "dsTidyverse", "resourcer", "dsCoda"))

# Set DataSHIELD options on margin-idiom profile
opalr::dsadmin.set_option(opal, "datashield.privacyControlLevel", "permissive", profile = "margin-idiom")
opalr::dsadmin.set_option(opal, "datashield.seed", "239", profile = "margin-idiom")

# Logout
opal.logout(opal)

message("Data upload complete!")
