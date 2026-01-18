# load the required packages
library('DSI')
library('DSOpal')
library('dsBaseClient') # Make sure this is v6.3.2-dev `devtools::install_github("datashield/dsBaseClient", ref = "v6.3.2-dev")`
library('dsTidyverseClient')
library('dsSurvivalClient') # Make sure this is v6.3.2-dev `devtools::install_github("datashield/dsSurvivalClient", ref = "v2.3.0-dev")`

# data preparation --------------------------------------------------------

# read the synthetic data
D1 <- readRDS('lifestyle_study1.rds')
D1$med_lipid <- as.numeric(haven::as_factor(D1$med_lipid)) - 1
D1$med_bp <- as.numeric(haven::as_factor(D1$med_bp)) - 1
D1$med_glucose <- as.numeric(haven::as_factor(D1$med_glucose)) - 1

save(D1, file='D1.rda')

library(opalr)
library(tibble)

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

# here you login to the opal demo server using credentials as an administrator
opal <- opal.login('administrator','password', url='https://opal-demo.obiba.org', 
                   opts = list(ssl_verifyhost=0, ssl_verifypeer=0))
upload_testing_dataset_table(opal, project_name = 'ProPass', table_name = 'life1', file_type='rda', local_file_path='D1.rda')

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

opalr::dsadmin.install_github_package(opal, "dsSurvival", "datashield", "v2.3.0-dev") # This operation takes some minutes to complete
opalr::dsadmin.install_package(opal, "dsTidyverse")
opalr::dsadmin.profile_init(opal, "default", c("dsBase", "dsSurvival", "dsTidyverse", "resourcer"))
opalr::dsadmin.set_option(opal, "datashield.privacyControlLevel", "permissive")
opalr::dsadmin.set_option(opal, "	datashield.seed", "239")
opal.logout(opal)

#######################################################################################################
# Data preparation, this aims at replicating the `Codes to simulate_RKB.Rmd` script supplied by ProPASS
#######################################################################################################

builder <- DSI::newDSLoginBuilder()
builder$append(server = "study1", url = "https://opal-demo.obiba.org", user = "administrator", password = "password", table = "ProPass.life1", driver = "OpalDriver", options='list(ssl_verifyhost=0, ssl_verifypeer=0)')
logindata <- builder$build()

connections <- datashield.login(logins = logindata, assign = TRUE, symbol = "D")
ds.arrange(df.name = "D", tidy_expr = list(ID), newobj = 'D')
# Original script uses 0.975 quantile; on datashield it is 0.95
# ds.quantileMean(x = 'D$bmi'): yields 37.16000
ds.case_when(tidy_expr = list(D$bmi <= 37.16000 ~ D$bmi, D$bmi > 37.16000 ~ 37.16000), newobj = 'bmi_revised')
ds.dataFrame(x = c('D','bmi_revised'), newobj = 'D')
ds.numNA(x = 'D$alc')
ds.filter(df.name = "D", tidy_expr = list(D$alc != 'NA'), newobj = "D")
ds.if_else(condition = list(D$med_lipid == 1 | D$med_bp == 1 | D$med_glucose == 1), true = 1, false = 0, newobj = 'med_combined')
ds.dataFrame(x = c('D','med_combined'), newobj = 'D')
ds.asNumeric(x.name = 'D$veg', newobj = 'veg.n')
ds.asNumeric(x.name = 'D$fruit', newobj = 'fruit.n')
ds.make(toAssign = 'fruit.n + veg.n', newobj = 'diet')
ds.dataFrame(x = c('D','diet'), newobj = 'D')
ds.select(df.name = 'D', tidy_expr = list(ID, age, sex, smoke, edu, bmi, alc, med_combined, diet), 
          newobj = 'D2')
ds.rBinom(samp.size = 491, size = 1, prob = 0.15, newobj = 'acm', seed.as.integer = 3112)
ds.rUnif(samp.size = 491, min = 3.0, max = 7.8, newobj = 'var1', seed.as.integer = NULL)
ds.make(toAssign = 'acm * var1', newobj = 'var2')
ds.recodeValues(var.name = 'var2', values2replace.vector = 0, new.values.vector = 8, newobj = 'fup')
ds.recodeValues(var.name = 'var1', values2replace.vector = 0, new.values.vector = 8, newobj = 'fup2')
ds.dataFrame(x = c('D2', 'acm', 'fup'), newobj = 'D2')
ds.rBinom(samp.size = 491, size = 2, prob = 0.3, newobj = 'CVD', seed.as.integer = NULL)
ds.case_when(tidy_expr = list(CVD == 2 ~ var1, CVD < 2 ~ 8), newobj = 'fup_CVD')
ds.dataFrame(x = c('D2', 'CVD', 'fup_CVD'), newobj = 'D2')
ds.asNumeric(x.name = 'D2$edu', newobj = 'edu')
ds.asNumeric(x.name = 'D2$smoke', newobj = 'smoke')
ds.select(df.name = 'D2', tidy_expr = list(ID, age, sex, bmi, alc, med_combined, diet, acm, fup, CVD, fup_CVD), 
          newobj = 'D2')
ds.dataFrame(x = c('D2', 'smoke', 'edu'), newobj = 'D2')
ds.mice(data = 'D2', m = 5, method = 'rf', newobj_df = 'imputed_data', seed = 'fixed', newobj_mids = "imputed_mids")
ds.asFactor(input.var.name = 'D2$edu', newobj.name = 'edu')
ds.asFactor(input.var.name = 'D2$smoke', newobj.name = 'smoke')
ds.asFactor(input.var.name = 'D2$sex', newobj.name = 'sex')
ds.select(df.name = 'imputed_data.1', tidy_expr = list(ID, age, bmi, alc, med_combined, diet, acm, fup, CVD, fup_CVD), 
          newobj = 'imputed_data1')
ds.dataFrame(x = c('imputed_data1', 'smoke', 'edu', 'sex'), newobj = 'imputed_data.3')

## Coxs data final step

ds.dataFrameSubset(df.name = 'imputed_data.3', V1.name = 'fup', V2.name = '1', 
                   Boolean.operator = '>=', newobj = 'dat_ACM_BMI')
ds.make(toAssign = 'dat_ACM_BMI$bmi', newobj = 'Primary_exposure')
ds.dataFrame(c('dat_ACM_BMI', 'Primary_exposure'), newobj = 'dat_ACM_BMI')

## Fine-gray data final step

ds.dataFrameSubset(df.name = 'imputed_data.3', V1.name = 'fup_CVD', V2.name = '1', 
                   Boolean.operator = '>=', newobj = 'dat_CVD_BMI')
ds.make(toAssign = 'dat_CVD_BMI$bmi', newobj = 'Primary_exposure')
ds.dataFrame(c('dat_CVD_BMI', 'Primary_exposure'), newobj = 'dat_CVD_BMI')

#######################################################################################################
# Coxs model
#######################################################################################################

ds.datadist(data = 'dat_ACM_BMI', adjust_to = list(Primary_exposure = 'min'))
ds.useDatadist(datadist = 'datadist_dat_ACM_BMI')

# Get knots 0.1/0.5/0.9 quantiles: ds.quantileMean(x = 'dat_ACM_BMI$Primary_exposure')
ds.make(toAssign = 'c(23.5, 27.5, 32.8)', newobj = 'knots')
ds.Surv(time = 'dat_ACM_BMI$fup', event = 'dat_ACM_BMI$acm', objectname = 'surv_object')
ds.coxphSLMAassign(formula = 'surv_object ~ rms::rcs(Primary_exposure, knots) +age + sex + smoke + edu + alc + med_combined + diet', 
                      dataName = 'dat_ACM_BMI', objectname = 'cph1', use.rms = TRUE)
test.ph <- ds.cox.zphSLMA('cph1')
survminer::ggcoxzph(test.ph[[1]])
# We can't get min and max of Primary_exposure, so we use 0.05 and 0.95 quantiles: ds.quantileMean(x = 'dat_ACM_BMI$Primary_exposure') yields 17.2 and 48.4
ds.Predict(fit = 'cph1', objectname = 'predictions', Primary_exposure = seq(22.6, 34.4, 0.01), fun = "exp", ref.zero = TRUE)

ds.acmPlot(pred_obj = 'predictions', line_color = 'blue', line_size = 2, ref_line_color = 'brown', ref_line_size = 1.5, x_label = 'BMI', y_label = 'Hazardratio', event_n = 87)

# However, if we want we can increase the predicted range
ds.Predict(fit = 'cph1', objectname = 'predictions', Primary_exposure = seq(22, 44, 0.01), fun = "exp", ref.zero = TRUE)
ds.acmPlot(pred_obj = 'predictions', line_color = 'blue', line_size = 2, ref_line_color = 'brown', ref_line_size = 1.5, x_label = 'BMI', y_label = 'Hazardratio', event_n = 87)

#######################################################################################################
# Fine-Gray model
#######################################################################################################

ds.datadist(data = 'dat_CVD_BMI', adjust_to = list(Primary_exposure = 'min'))
ds.useDatadist(datadist = 'datadist_dat_CVD_BMI')

# Get knots 0.1/0.5/0.9 quantiles: ds.quantileMean(x = 'dat_CVD_BMI$Primary_exposure')
ds.make(toAssign = 'c(23.5, 27.5, 32.8)', newobj = 'knots')
ds.asFactor(input.var.name = 'dat_CVD_BMI$CVD', newobj.name = 'CVD_factor')
ds.dataFrame(x = c('dat_CVD_BMI', 'CVD_factor'), newobj = 'dat_CVD_BMI')
ds.finegray(formula = 'Surv(fup_CVD, CVD_factor) ~ .', data = 'dat_CVD_BMI', etype = '1', newobj = 'fg_object')
ds.coxphSLMAassign(formula = 'survival::Surv(fgstart,fgstop,fgstatus) ~ rms::rcs(Primary_exposure, knots) +age + sex + smoke + edu + alc + med_combined + diet', 
                      dataName = 'fg_object', objectname = 'cph3', use.rms = TRUE)

# We can't get min and max of Primary_exposure, so we use 0.05 and 0.95 quantiles: ds.quantileMean(x = 'dat_CVD_BMI$Primary_exposure')
ds.Predict(fit = 'cph3', objectname = 'predictions', Primary_exposure = seq(22.6, 34.4, 0.01), fun = "exp", ref.zero = TRUE)
ds.acmPlot(pred_obj = 'predictions', line_color = 'blue', line_size = 2, ref_line_color = 'brown', ref_line_size = 1.5, x_label = 'BMI', y_label = 'Hazardratio', event_n = 220, outcome_name = 'CVD')
