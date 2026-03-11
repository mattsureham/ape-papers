## 02_clean_data.R — Construct analysis dataset
## APEP-0601: PDUFA Deadline Bunching and Drug Safety

source("code/00_packages.R")

cat("=== Loading and cleaning data ===\n")

# Load NME data
pdufa_std <- readRDS("data/pdufa_standard.rds")

# Load FAERS data
ae_data <- readRDS("data/faers_pdufa_cache.rds")

cat("NME drugs:", nrow(pdufa_std), "\n")
cat("FAERS records:", nrow(ae_data), "\n")

# Clean NME data
df <- pdufa_std %>%
  transmute(
    drug_name = Proprietary..Name,
    active_ingredient = Active.Ingredient.Moiety,
    applicant = Applicant,
    nda_bla = NDA.BLA,
    nda_number = as.character(Application.Number.1.),
    dosage_form = Dosage.Form.1.,
    route = Route.of.Administration.1.,
    receipt_date = receipt_date,
    approval_date = approval_date,
    review_days = review_days,
    approval_year = approval_year,
    indication = Abbreviated.Indication.s.,
    review_designation = Review.Designation,
    orphan = Orphan.Drug.Designation,
    accelerated = Accelerated.Approval,
    breakthrough = Breakthrough.Therapy.Designation,
    fast_track = Fast.Track.Designation
  ) %>%
  # Clean boolean fields
  mutate(
    is_orphan = grepl("Yes", orphan, ignore.case = TRUE),
    is_accelerated = grepl("Yes", accelerated, ignore.case = TRUE),
    is_breakthrough = grepl("Yes", breakthrough, ignore.case = TRUE),
    is_fast_track = grepl("Yes", fast_track, ignore.case = TRUE)
  )

# Merge with FAERS data
df <- df %>%
  left_join(ae_data, by = "nda_number")

cat("\nMerged dataset:", nrow(df), "drugs\n")
cat("Drugs with AE data:", sum(!is.na(df$total_ae)), "\n")
cat("Drugs without AE data:", sum(is.na(df$total_ae)), "\n")

# Create key analysis variables
df <- df %>%
  mutate(
    # Running variable centered at 300
    rv = review_days - 300,

    # Treatment: above PDUFA deadline
    above_300 = as.integer(review_days >= 300),

    # Bunching window indicators
    in_bunching = review_days >= 295 & review_days <= 310,
    in_tight_bunching = review_days >= 298 & review_days <= 305,
    in_donut_left = review_days >= 275 & review_days < 295,
    in_donut_right = review_days > 310 & review_days <= 345,

    # Log-transformed AE counts (adding 1 to handle zeros)
    log_total_ae = log1p(total_ae),
    log_serious_ae = log1p(serious_ae),
    log_death_ae = log1p(death_ae),
    log_hosp_ae = log1p(hospitalization_ae),

    # Adverse event rates relative to total
    serious_share = ifelse(total_ae > 0, serious_ae / total_ae, NA_real_),
    death_share = ifelse(total_ae > 0, death_ae / total_ae, NA_real_),
    hosp_share = ifelse(total_ae > 0, hospitalization_ae / total_ae, NA_real_),

    # Safety action indicators
    any_recall = !is.na(recall_count) & recall_count > 0,
    has_boxed = has_boxed_warning,

    # Time on market (years since approval)
    years_on_market = as.numeric(as.Date("2024-12-31") - approval_date) / 365.25,

    # AE rate per year on market
    ae_per_year = ifelse(years_on_market > 0, total_ae / years_on_market, NA_real_),
    serious_ae_per_year = ifelse(years_on_market > 0, serious_ae / years_on_market, NA_real_),

    # Therapeutic class (simplified from indication)
    therapeutic_class = case_when(
      grepl("cancer|oncol|tumor|carcinoma|leukemia|lymphoma|melanoma|myeloma",
            indication, ignore.case = TRUE) ~ "Oncology",
      grepl("HIV|hepat|anti.?viral|influenza", indication, ignore.case = TRUE) ~ "Antiviral",
      grepl("diabet|insulin|glucose", indication, ignore.case = TRUE) ~ "Metabolic",
      grepl("heart|cardio|hypertens|cholesterol|lipid|statin",
            indication, ignore.case = TRUE) ~ "Cardiovascular",
      grepl("depress|anxiety|schizo|bipolar|psych|ADHD",
            indication, ignore.case = TRUE) ~ "Psychiatric",
      grepl("arthrit|inflam|autoimmune|rheumat|lupus|crohn|colitis",
            indication, ignore.case = TRUE) ~ "Autoimmune",
      grepl("infect|bacteri|antibiotic|fungal", indication, ignore.case = TRUE) ~ "Anti-infective",
      grepl("pain|analges|opioid|migraine", indication, ignore.case = TRUE) ~ "Pain",
      grepl("asthma|COPD|pulmon|respiratory|cystic fibrosis",
            indication, ignore.case = TRUE) ~ "Respiratory",
      grepl("seizure|epilep|neurolog|alzheim|parkinson|multiple sclerosis",
            indication, ignore.case = TRUE) ~ "Neurological",
      TRUE ~ "Other"
    ),

    # Era dummies
    era = case_when(
      approval_year <= 1997 ~ "PDUFA I (1993-1997)",
      approval_year <= 2002 ~ "PDUFA II (1998-2002)",
      approval_year <= 2007 ~ "PDUFA III (2003-2007)",
      approval_year <= 2012 ~ "PDUFA IV (2008-2012)",
      approval_year <= 2017 ~ "PDUFA V (2013-2017)",
      TRUE ~ "PDUFA VI-VII (2018+)"
    )
  )

cat("\n=== Analysis sample characteristics ===\n")
cat("Total standard-review drugs:", nrow(df), "\n")
cat("With FAERS linkage:", sum(!is.na(df$total_ae)), "\n")
cat("Mean review days:", round(mean(df$review_days), 1), "\n")
cat("Median review days:", median(df$review_days), "\n")
cat("\nTherapeutic class distribution:\n")
print(table(df$therapeutic_class))
cat("\nEra distribution:\n")
print(table(df$era))
cat("\nAE summary (drugs with FAERS data):\n")
cat("  Mean total AEs:", round(mean(df$total_ae, na.rm=T), 0), "\n")
cat("  Mean serious AEs:", round(mean(df$serious_ae, na.rm=T), 0), "\n")
cat("  Mean death reports:", round(mean(df$death_ae, na.rm=T), 0), "\n")
cat("  Pct with recalls:", round(100*mean(df$any_recall, na.rm=T), 1), "%\n")
cat("  Pct with boxed warnings:", round(100*mean(df$has_boxed, na.rm=T), 1), "%\n")

# Restrict to drugs with FAERS data for analysis
df_analysis <- df %>% filter(!is.na(total_ae))
cat("\nFinal analysis sample:", nrow(df_analysis), "drugs\n")

# Save
saveRDS(df, "data/clean_full.rds")
saveRDS(df_analysis, "data/clean_analysis.rds")
cat("Saved clean_full.rds and clean_analysis.rds\n")
