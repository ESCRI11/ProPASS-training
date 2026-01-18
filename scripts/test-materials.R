# =============================================================================
# ProPASS DataSHIELD Training - Materials Test Script
# =============================================================================
# This script tests all examples from the training materials to ensure they work.
# Run this script to verify the materials before the workshop.
# =============================================================================

# -----------------------------------------------------------------------------
# CHAPTER 2: Getting Connected
# -----------------------------------------------------------------------------

cat("\n========================================\n")
cat("CHAPTER 2: Getting Connected\n")
cat("========================================\n\n")

# Load required libraries
library(DSI)
library(DSOpal)
library(dsBaseClient)
library(dsTidyverseClient)

# Create login builder
builder <- DSI::newDSLoginBuilder()

# Add the demo server with CNSIM1 table
builder$append(
  server = "demo",
  url = "https://opal-demo.obiba.org",
  user = "dsuser",
  password = "P@ssw0rd",
  table = "CNSIM.CNSIM1",
  profile = "lemon-donkey"
)

# Build login data
logindata <- builder$build()

cat("Connecting to DataSHIELD server...\n")

# Connect and assign data to symbol "D"
conns <- datashield.login(logins = logindata, assign = TRUE, symbol = "D")

# Verify connection
cat("\n--- Listing assigned objects ---\n")
print(ds.ls())

# Explore data
cat("\n--- Data dimensions ---\n")
print(ds.dim("D"))

cat("\n--- Column names ---\n")
print(ds.colnames("D"))

# -----------------------------------------------------------------------------
# CHAPTER 3: Filtering & Subsetting (Tidyverse Approach)
# -----------------------------------------------------------------------------

cat("\n\n========================================\n")
cat("CHAPTER 3: Filtering & Subsetting\n")
cat("========================================\n\n")

# --- Sorting with ds.arrange() ---

cat("--- Sorting data with ds.arrange() ---\n")

ds.arrange(
  df.name = "D",
  tidy_expr = list(PM_BMI_CONTINUOUS),
  newobj = "D_sorted"
)

cat("D_sorted (sorted by BMI):\n")
print(ds.dim("D_sorted"))

# --- Filtering rows with ds.filter() ---

cat("\n--- Filtering rows with ds.filter() ---\n")

# Filter for BMI >= 25
ds.filter(
  df.name = "D",
  tidy_expr = list(D$PM_BMI_CONTINUOUS >= 25),
  newobj = "D_bmi25plus"
)

cat("D_bmi25plus (BMI >= 25):\n")
print(ds.dim("D_bmi25plus"))

# Filter with multiple conditions
ds.filter(
  df.name = "D",
  tidy_expr = list(D$PM_BMI_CONTINUOUS >= 20, D$PM_BMI_CONTINUOUS <= 35),
  newobj = "D_bmi_range"
)

cat("D_bmi_range (BMI 20-35):\n")
print(ds.dim("D_bmi_range"))

# --- Selecting columns with ds.select() ---

cat("\n--- Selecting columns with ds.select() ---\n")

ds.select(
  df.name = "D",
  tidy_expr = list(PM_BMI_CONTINUOUS, LAB_TSC, LAB_HDL, LAB_TRIG, GENDER, DIS_DIAB),
  newobj = "D_selected"
)

cat("D_selected columns:\n")
print(ds.colnames("D_selected"))

# --- Subsetting with ds.dataFrameSubset() ---

cat("\n--- Subsetting with ds.dataFrameSubset() ---\n")

# Subset for BMI >= 25 (similar to follow-up filtering in ProPASS)
ds.dataFrameSubset(
  df.name = "D",
  V1.name = "D$PM_BMI_CONTINUOUS",
  V2.name = "25",
  Boolean.operator = ">=",
  newobj = "D_subset"
)

cat("D_subset (BMI >= 25 using ds.dataFrameSubset):\n")
print(ds.dim("D_subset"))

# --- Complete cases ---

cat("\n--- Complete case analysis ---\n")

ds.completeCases(
  x1 = "D",
  newobj = "D_complete"
)

cat("D_complete (no missing values):\n")
print(ds.dim("D_complete"))

# -----------------------------------------------------------------------------
# CHAPTER 4: Conditional Operations (Tidyverse Approach)
# -----------------------------------------------------------------------------

cat("\n\n========================================\n")
cat("CHAPTER 4: Conditional Operations\n")
cat("========================================\n\n")

# --- ds.case_when() for winsorizing ---

cat("--- Winsorizing BMI with ds.case_when() ---\n")

# Cap BMI at 40 (winsorization)
ds.case_when(
  tidy_expr = list(
    D$PM_BMI_CONTINUOUS <= 40 ~ D$PM_BMI_CONTINUOUS,
    D$PM_BMI_CONTINUOUS > 40 ~ 40
  ),
  newobj = "bmi_capped"
)

cat("BMI capped at 40:\n")
print(ds.summary("bmi_capped"))

# Add to data frame
ds.dataFrame(x = c("D", "bmi_capped"), newobj = "D_with_capped")
cat("D_with_capped columns:\n")
print(ds.colnames("D_with_capped"))

# --- ds.if_else() for binary indicators ---

cat("\n--- Creating binary indicators with ds.if_else() ---\n")

# Create overweight indicator (BMI >= 25)
ds.if_else(
  condition = list(D$PM_BMI_CONTINUOUS >= 25),
  true = 1,
  false = 0,
  newobj = "is_overweight"
)

cat("Overweight indicator distribution:\n")
print(ds.table("is_overweight"))

# --- ds.recodeValues() ---

cat("\n--- Recoding values with ds.recodeValues() ---\n")

# Recode GENDER: 0,1 -> 1,2
ds.recodeValues(
  var.name = "D$GENDER",
  values2replace.vector = c(0, 1),
  new.values.vector = c(1, 2),
  newobj = "gender_recoded"
)

cat("Recoded GENDER (0,1 -> 1,2):\n")
print(ds.table("gender_recoded"))

# --- ds.make() for arithmetic and copies ---

cat("\n--- Creating variables with ds.make() ---\n")

# Create HDL/TSC ratio
ds.make(
  toAssign = "D$LAB_HDL / D$LAB_TSC",
  newobj = "hdl_ratio"
)

cat("HDL/TSC ratio:\n")
print(ds.summary("hdl_ratio"))

# Create variable copy (like Primary_exposure in ProPASS)
ds.make(
  toAssign = "D$PM_BMI_CONTINUOUS",
  newobj = "Primary_exposure"
)

cat("Primary_exposure (copy of BMI):\n")
print(ds.summary("Primary_exposure"))

# Log transformation (common for skewed data)
ds.make(
  toAssign = "log(D$LAB_TRIG)",
  newobj = "log_trig"
)

cat("\nLog-transformed triglycerides:\n")
print(ds.summary("log_trig"))

# --- Creating combined indicators ---

cat("\n--- Creating combined indicators ---\n")

# Metabolic risk indicator (diabetes OR high cholesterol)
ds.if_else(
  condition = list(D$DIS_DIAB == 1 | D$LAB_TSC > 6.5),
  true = 1,
  false = 0,
  newobj = "metabolic_risk"
)

cat("Metabolic risk indicator:\n")
print(ds.table("metabolic_risk"))

# --- Converting variable types ---

cat("\n--- Converting variable types ---\n")

# Convert to factor
ds.asFactor("D$GENDER", newobj = "gender_factor")

cat("GENDER as factor levels:\n")
print(ds.levels("gender_factor"))

# Convert to numeric
ds.asNumeric("D$DIS_DIAB", newobj = "diabetes_numeric")

cat("DIS_DIAB as numeric:\n")
print(ds.class("diabetes_numeric"))

# --- ds.mice() note ---

cat("\n--- Multiple Imputation (ds.mice) ---\n")
cat("Note: ds.mice() requires dsTidyverse server-side package.\n")
cat("In production, you would use:\n")
cat('  ds.mice(data = "D", m = 5, method = "rf", newobj_df = "imputed_data")\n')

# -----------------------------------------------------------------------------
# CHAPTER 5: Derived Variables & Grouped Summaries
# -----------------------------------------------------------------------------

cat("\n\n========================================\n")
cat("CHAPTER 5: Derived Variables & Grouped Summaries\n")
cat("========================================\n\n")

# --- Checking for missing data ---

cat("--- Checking for missing data with ds.numNA() ---\n")

cat("\nMissing values in LAB_TSC:\n")
print(ds.numNA("D$LAB_TSC"))

cat("\nMissing values in PM_BMI_CONTINUOUS:\n")
print(ds.numNA("D$PM_BMI_CONTINUOUS"))

# --- Quantiles for model knots ---

cat("\n--- Quantile calculations (for model knots) ---\n")

cat("\nBMI quantiles (combined):\n")
print(ds.quantileMean("D$PM_BMI_CONTINUOUS", type = "combine"))

# Create knots vector (as done in ProPASS script)
cat("\nCreating knots vector:\n")
ds.make(toAssign = "c(23.5, 27.5, 32.8)", newobj = "knots")
cat("Knots created for restricted cubic splines\n")

# --- Grouped Summaries with ds.tapply() ---

cat("\n--- Grouped summaries with ds.tapply() ---\n")

# Mean BMI by gender
cat("\nMean BMI by GENDER:\n")
print(ds.tapply(
  X.name = "D$PM_BMI_CONTINUOUS",
  INDEX.names = "D$GENDER",
  FUN.name = "mean"
))

# --- Cross-Tabulations ---

cat("\n--- Cross-tabulations ---\n")

cat("\nGENDER by DIS_DIAB:\n")
print(ds.table(
  rvar = "D$GENDER",
  cvar = "D$DIS_DIAB"
))

# --- Creating Data Frames ---

cat("\n--- Creating new data frames ---\n")

ds.dataFrame(
  x = c("D$PM_BMI_CONTINUOUS", "D$LAB_TSC", "D$LAB_HDL", "D$GENDER"),
  newobj = "D_analysis"
)

cat("D_analysis columns:\n")
print(ds.colnames("D_analysis"))

# --- Adding derived variables ---

cat("\n--- Adding derived variables to data frame ---\n")

ds.cbind(
  x = c("D_analysis", "hdl_ratio", "is_overweight"),
  newobj = "D_extended"
)

cat("D_extended columns:\n")
print(ds.colnames("D_extended"))

# --- Comprehensive Summary ---

cat("\n--- Variable summaries ---\n")

cat("\nBMI summary:\n")
print(ds.summary("D$PM_BMI_CONTINUOUS"))

# --- Correlation ---

cat("\n--- Correlation analysis ---\n")

cat("\nCorrelation between BMI and Total Cholesterol:\n")
print(ds.cor(
  x = "D$PM_BMI_CONTINUOUS",
  y = "D$LAB_TSC"
))

# --- Mean and Variance ---

cat("\n--- Mean and variance ---\n")

cat("\nMean BMI:\n")
print(ds.mean("D$PM_BMI_CONTINUOUS", type = "combine"))

cat("\nVariance of BMI:\n")
print(ds.var("D$PM_BMI_CONTINUOUS", type = "combine"))

# -----------------------------------------------------------------------------
# CHAPTER 6: Table 1
# -----------------------------------------------------------------------------

cat("\n\n========================================\n")
cat("CHAPTER 6: Creating Table 1\n")
cat("========================================\n\n")

# --- Basic Descriptive Statistics ---

cat("--- Basic descriptive statistics ---\n")

# Continuous variables
cat("\nBMI mean and SD:\n")
bmi_mean <- ds.mean("D$PM_BMI_CONTINUOUS", type = "combine")
bmi_var <- ds.var("D$PM_BMI_CONTINUOUS", type = "combine")
bmi_sd <- sqrt(bmi_var$Global.Variance[1])
cat("BMI:", round(bmi_mean$Global.Mean, 1), "(", round(bmi_sd, 1), ")\n")

cat("\nTotal Cholesterol mean and SD:\n")
tsc_mean <- ds.mean("D$LAB_TSC", type = "combine")
tsc_var <- ds.var("D$LAB_TSC", type = "combine")
tsc_sd <- sqrt(tsc_var$Global.Variance[1])
cat("TSC:", round(tsc_mean$Global.Mean, 2), "(", round(tsc_sd, 2), ")\n")

# --- Categorical Variables ---

cat("\n--- Categorical variable frequencies ---\n")

cat("\nGender distribution:\n")
print(ds.table("D$GENDER"))

cat("\nDiabetes prevalence:\n")
print(ds.table("D$DIS_DIAB"))

# --- Stratified Statistics ---

cat("\n--- Stratified statistics (by gender) ---\n")

cat("\nMean BMI by gender:\n")
print(ds.tapply(X.name = "D$PM_BMI_CONTINUOUS", INDEX.names = "D$GENDER", FUN.name = "mean"))

cat("\nSD of BMI by gender:\n")
print(ds.tapply(X.name = "D$PM_BMI_CONTINUOUS", INDEX.names = "D$GENDER", FUN.name = "sd"))

cat("\nMean cholesterol by gender:\n")
print(ds.tapply(X.name = "D$LAB_TSC", INDEX.names = "D$GENDER", FUN.name = "mean"))

# --- Cross-tabulations ---

cat("\n--- Cross-tabulations ---\n")

cat("\nDiabetes by Gender:\n")
print(ds.table("D$DIS_DIAB", "D$GENDER"))

# --- Missing Data Summary ---

cat("\n--- Missing data summary ---\n")

cat("PM_BMI_CONTINUOUS:", ds.numNA("D$PM_BMI_CONTINUOUS")$demo, "\n")
cat("LAB_TSC:", ds.numNA("D$LAB_TSC")$demo, "\n")
cat("LAB_HDL:", ds.numNA("D$LAB_HDL")$demo, "\n")
cat("GENDER:", ds.numNA("D$GENDER")$demo, "\n")
cat("DIS_DIAB:", ds.numNA("D$DIS_DIAB")$demo, "\n")

# -----------------------------------------------------------------------------
# CHAPTER 7: GLM Models
# -----------------------------------------------------------------------------

cat("\n\n========================================\n")
cat("CHAPTER 7: Generalized Linear Models\n")
cat("========================================\n\n")

# --- Linear Regression ---

cat("--- Linear Regression (Gaussian) ---\n")

# Simple linear regression: TSC ~ BMI
cat("\nSimple linear model: LAB_TSC ~ PM_BMI_CONTINUOUS\n")
model_linear <- ds.glm(
  formula = "LAB_TSC ~ PM_BMI_CONTINUOUS",
  data = "D",
  family = "gaussian"
)
print(model_linear$coefficients)

# Multiple linear regression
cat("\nMultiple linear model: LAB_TSC ~ PM_BMI_CONTINUOUS + LAB_HDL + GENDER\n")
model_multi_linear <- ds.glm(
  formula = "LAB_TSC ~ PM_BMI_CONTINUOUS + LAB_HDL + GENDER",
  data = "D",
  family = "gaussian"
)
print(model_multi_linear$coefficients)

# --- Logistic Regression ---

cat("\n--- Logistic Regression (Binomial) ---\n")

# Simple logistic regression: DIS_DIAB ~ BMI
cat("\nSimple logistic model: DIS_DIAB ~ PM_BMI_CONTINUOUS\n")
model_logistic <- ds.glm(
  formula = "DIS_DIAB ~ PM_BMI_CONTINUOUS",
  data = "D",
  family = "binomial"
)
print(model_logistic$coefficients)

cat("\nOdds Ratio for BMI:", exp(model_logistic$coefficients[2, "Estimate"]), "\n")

# Multiple logistic regression
cat("\nMultiple logistic model: DIS_DIAB ~ PM_BMI_CONTINUOUS + LAB_TSC + GENDER\n")
model_multi_logistic <- ds.glm(
  formula = "DIS_DIAB ~ PM_BMI_CONTINUOUS + LAB_TSC + GENDER",
  data = "D",
  family = "binomial"
)
print(model_multi_logistic$coefficients)

# --- Odds Ratios with 95% CI ---

cat("\n--- Odds Ratios with 95% CI ---\n")

coefs <- model_multi_logistic$coefficients
cat("\nVariable | OR | 95% CI | p-value\n")
cat("---------|----|---------|---------\n")
for (i in 1:nrow(coefs)) {
  or <- exp(coefs[i, "Estimate"])
  ci_low <- exp(coefs[i, "Estimate"] - 1.96 * coefs[i, "Std. Error"])
  ci_high <- exp(coefs[i, "Estimate"] + 1.96 * coefs[i, "Std. Error"])
  cat(rownames(coefs)[i], "|", round(or, 3), "|", 
      round(ci_low, 3), "-", round(ci_high, 3), "|", 
      round(coefs[i, "p-value"], 4), "\n")
}

# -----------------------------------------------------------------------------
# CLEANUP: Logout from CNSIM
# -----------------------------------------------------------------------------

cat("\n\n========================================\n")
cat("CLEANUP: Logging out from CNSIM\n")
cat("========================================\n\n")

datashield.logout(conns)
cat("Successfully logged out from CNSIM server.\n")

# -----------------------------------------------------------------------------
# CHAPTER 8: Survival Analysis (CORDELIA dataset)
# -----------------------------------------------------------------------------

cat("\n\n========================================\n")
cat("CHAPTER 8: Survival Analysis\n")
cat("========================================\n\n")

cat("Survival analysis requires the CORDELIA dataset and dsSurvivalClient.\n")
cat("Connecting to CORDELIA resource...\n\n")

# Load survival client
library(dsSurvivalClient)

# Connect to CORDELIA dataset
builder_surv <- DSI::newDSLoginBuilder()
builder_surv$append(
  server = "demo",
  url = "https://opal-demo.obiba.org",
  user = "dsuser",
  password = "P@ssw0rd",
  resource = "CORDELIA.cordelia45",
  profile = "lemon-donkey"
)

logindata_surv <- builder_surv$build()
conns <- datashield.login(logins = logindata_surv, assign = TRUE, symbol = "res")

# Convert resource to data frame
datashield.assign.expr(
  conns, 
  symbol = "D",
  expr = quote(as.resource.data.frame(res, strict = TRUE))
)

# --- Check CORDELIA data structure ---

cat("--- CORDELIA data structure ---\n")

cat("\nData dimensions:\n")
print(ds.dim("D"))

cat("\nColumn names:\n")
cordelia_cols <- ds.colnames("D")$demo
print(cordelia_cols)

# --- Check survival-related variables ---

cat("\n--- Survival-related variables ---\n")

cat("\nTime to death (todeath):\n")
print(ds.summary("D$todeath"))

cat("\nDeath indicator (death):\n")
print(ds.table("D$death"))

cat("\nBMI (IMC):\n")
print(ds.summary("D$IMC"))

cat("\nAge (edad):\n")
print(ds.summary("D$edad"))

cat("\nSex (sexo):\n")
print(ds.table("D$sexo"))

# --- Creating survival object ---

cat("\n--- Creating survival object ---\n")

ds.Surv(
  time = "D$todeath",
  event = "D$death",
  objectname = "surv_obj",
  type = "right"
)

cat("Survival object created: surv_obj\n")
print(ds.class("surv_obj"))

# --- Simple Cox model using ds.coxph.SLMA ---

cat("\n--- Simple Cox model: surv_obj ~ IMC ---\n")
cat("Using ds.coxph.SLMA() which takes formula syntax\n\n")

cox_simple <- ds.coxph.SLMA(
  formula = "surv_obj ~ IMC",
  dataName = "D"
)

# Results are stored under $demo (study name)
cat("\nCox model coefficients (from demo study):\n")
print(cox_simple$demo$coefficients)

cat("\nConfidence intervals:\n")
print(cox_simple$demo$conf.int)

cat("\nHazard ratio for BMI (per 1 unit increase):\n")
hr_bmi <- cox_simple$demo$coefficients["IMC", "exp(coef)"]
cat("HR:", round(hr_bmi, 4), "\n")
cat("95% CI:", round(cox_simple$demo$conf.int["IMC", "lower .95"], 4), 
    "-", round(cox_simple$demo$conf.int["IMC", "upper .95"], 4), "\n")

# --- Prepare factor variables ---

cat("\n--- Preparing factor variables ---\n")

# Convert sex to factor
ds.asFactor("D$sexo", newobj.name = "sexo_f")
cat("sexo_f created\n")

# Add sex factor to data frame
ds.dataFrame(x = c("D", "sexo_f"), newobj = "D_surv")

cat("D_surv columns:\n")
print(ds.colnames("D_surv"))

# --- Multiple Cox model ---

cat("\n--- Multiple Cox model (with sex, age, diabetes, HTA) ---\n")

# Create survival object with the new data frame
ds.Surv(time = "D_surv$todeath", event = "D_surv$death", objectname = "surv_obj2")

# Model with available variables
cox_multi <- ds.coxph.SLMA(
  formula = "surv_obj2 ~ IMC + edad + sexo_f + diabetes + HTA",
  dataName = "D_surv"
)

cat("\nMultiple Cox model coefficients:\n")
print(cox_multi$demo$coefficients)

cat("\nHazard Ratios with 95% CI:\n")
coefs <- cox_multi$demo$coefficients
ci <- cox_multi$demo$conf.int
for (var in rownames(coefs)) {
  cat(var, ": HR =", round(coefs[var, "exp(coef)"], 3),
      "(", round(ci[var, "lower .95"], 3), "-", round(ci[var, "upper .95"], 3), ")\n")
}

# --- Filter for adequate follow-up ---

cat("\n--- Filtering for adequate follow-up ---\n")

ds.dataFrameSubset(
  df.name = "D",
  V1.name = "D$todeath",
  V2.name = "1",
  Boolean.operator = ">=",
  newobj = "D_ACM"
)

cat("D_ACM (follow-up >= 1 year):\n")
print(ds.dim("D_ACM"))

cat("\nDeath events in filtered data:\n")
print(ds.table("D_ACM$death"))

# --- BMI Categories ---

cat("\n--- Creating BMI categories ---\n")

ds.Boole(V1 = "D$IMC", V2 = "25", Boolean.operator = "<", newobj = "bmi_normal")
ds.Boole(V1 = "D$IMC", V2 = "25", Boolean.operator = ">=", newobj = "bmi_ge25")
ds.Boole(V1 = "D$IMC", V2 = "30", Boolean.operator = "<", newobj = "bmi_lt30")

# Overweight: BMI 25-30
ds.make(toAssign = "bmi_ge25 * bmi_lt30", newobj = "bmi_overweight")

# Obese: BMI >= 30
ds.Boole(V1 = "D$IMC", V2 = "30", Boolean.operator = ">=", newobj = "bmi_obese")

cat("BMI categories created\n")

# Check distributions
cat("\nNormal weight (BMI < 25):\n")
print(ds.table("bmi_normal"))

cat("\nOverweight (BMI 25-30):\n")
print(ds.table("bmi_overweight"))

cat("\nObese (BMI >= 30):\n")
print(ds.table("bmi_obese"))

# -----------------------------------------------------------------------------
# CLEANUP: Final Logout
# -----------------------------------------------------------------------------

cat("\n\n========================================\n")
cat("CLEANUP: Logging out\n")
cat("========================================\n\n")

datashield.logout(conns)

cat("Successfully logged out from DataSHIELD server.\n")
cat("\n=== ALL TESTS COMPLETED SUCCESSFULLY ===\n\n")
