## 01_fetch_data.R — Load CMS data and validate
## Data already downloaded via API/CSV from data.cms.gov

source("00_packages.R")

cat("=== Loading CMS Nursing Home Data ===\n")

# --- Provider Information (facility-level, current snapshot) ---
provider <- fread("../data/NH_ProviderInfo.csv")
cat(sprintf("Provider Info: %d facilities, %d columns\n", nrow(provider), ncol(provider)))

# --- Health Deficiencies (survey-level, historical panel) ---
deficiencies <- fread("../data/NH_HealthCitations.csv")
cat(sprintf("Health Deficiencies: %d records\n", nrow(deficiencies)))

# --- Penalties ---
penalties <- fread("../data/NH_Penalties.csv")
cat(sprintf("Penalties: %d records\n", nrow(penalties)))

# --- Quality Measures ---
quality <- fread("../data/NH_QualityMsr.csv")
cat(sprintf("Quality Measures: %d records\n", nrow(quality)))

# === VALIDATION: Ensure real data loaded ===
stopifnot("Provider data must have >10000 facilities" = nrow(provider) > 10000)
stopifnot("Deficiency data must have >100000 records" = nrow(deficiencies) > 100000)
stopifnot("Must have all 50+ states" = length(unique(provider$State)) >= 50)

# Standardize column names
setnames(provider, make.names(colnames(provider)))
setnames(deficiencies, make.names(colnames(deficiencies)))
setnames(penalties, make.names(colnames(penalties)))
setnames(quality, make.names(colnames(quality)))

# === TREATMENT MAPPING ===
# State nursing home minimum staffing mandates with quantitative HPRD floors
# Sources: KFF, NCSL, individual state statutes
mandate_info <- data.table(
  state = c("CT", "RI", "CA", "AZ", "WA", "NY",
            "FL", "IL", "AR", "OR", "PA", "MA"),
  mandate_year = c(2017L, 2017L, 2018L, 2019L, 2019L, 2022L,
                   2002L, 2010L, 2014L, 2015L, 2016L, 2016L),
  hprd_floor = c(NA, NA, 3.5, NA, NA, 3.5,
                 3.6, NA, NA, NA, NA, NA),
  mandate_type = c("updated", "updated", "updated", "new", "updated", "new",
                   "always", "always", "always", "always", "always", "always"),
  notes = c("Updated existing ratio requirements",
            "Updated existing ratio requirements",
            "AB 2079: 3.5 total HPRD",
            "New quantitative staffing floor",
            "Updated existing staffing standards",
            "Safe Staffing Act: 3.5 HPRD, 2.2 CNA floor",
            "Statute 400.23: 3.6 total HPRD",
            "Updated 2010",
            "Updated 2014",
            "Updated 2015",
            "Updated 2016",
            "Updated 2016")
)

# For the DiD: states that adopted/updated DURING the data period (2017-2025)
# are the treatment cohorts. Pre-2017 are always-treated. Rest are never-treated.
did_cohorts <- mandate_info[mandate_year >= 2017]
cat(sprintf("\nDiD treatment cohorts: %d states\n", nrow(did_cohorts)))
print(did_cohorts[, .(state, mandate_year, notes)])

always_treated <- mandate_info[mandate_year < 2017]$state
cat(sprintf("Always-treated states (pre-2017 mandates): %s\n",
            paste(always_treated, collapse = ", ")))

# Save treatment mapping
fwrite(mandate_info, "../data/mandate_info.csv")

# Save processed data
saveRDS(provider, "../data/provider.rds")
saveRDS(deficiencies, "../data/deficiencies.rds")
saveRDS(penalties, "../data/penalties.rds")
saveRDS(quality, "../data/quality.rds")

cat("\n=== Data loading complete ===\n")
