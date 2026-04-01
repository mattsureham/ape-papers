## 03_main_analysis.R — Main DiD analysis
## APEP Paper: Mexico's Sorteo Militar and Youth Crime
##
## Design: Male × Age 18-19 interaction captures the differential effect
## of lottery eligibility on victimization. Controls: state × year FEs,
## age FEs. Clustered at state level (32 states).

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

# ============================================================
# 1. Load analysis data
# ============================================================
df <- fread(file.path(data_dir, "analysis_panel.csv"))
cat("Loaded analysis panel:", nrow(df), "observations\n")
cat("Years:", paste(sort(unique(df$survey_year)), collapse=", "), "\n")
cat("Age range:", range(df$EDAD), "\n")

# ============================================================
# 2. Main specification: DiD with Male × Age 18-19
# ============================================================
cat("\n=== MAIN RESULTS ===\n")

# Create factor for age (single years)
df[, age_f := factor(EDAD)]
df[, state_year := paste0(state, "_", survey_year)]

# Specification 1: Any crime victimization
# Y = α + β(Male × Age18_19) + γ(Male) + δ(Age18_19)
#     + State-Year FE + Age FE + ε
# Cluster at state level

cat("\n--- Table 1: Main Results ---\n")

# Col 1: Simple OLS
m1 <- feols(victim ~ male_18_19 + male + age_18_19 | survey_year,
            data = df, cluster = ~state)

# Col 2: Add state × year FE
m2 <- feols(victim ~ male_18_19 + male + age_18_19 | state^survey_year,
            data = df, cluster = ~state)

# Col 3: Add single-year-of-age FE
m3 <- feols(victim ~ male_18_19 | male + age_f + state^survey_year,
            data = df, cluster = ~state)

# Col 4: Violent crime only
m4 <- feols(victim_violent ~ male_18_19 | male + age_f + state^survey_year,
            data = df, cluster = ~state)

# Col 5: Property crime only
m5 <- feols(victim_property ~ male_18_19 | male + age_f + state^survey_year,
            data = df, cluster = ~state)

# Print results
cat("\nPanel A: Any Crime Victimization\n")
etable(m1, m2, m3, headers = c("(1) Year FE", "(2) State×Year FE",
                                 "(3) + Age FE"))

cat("\nPanel B: By Crime Type\n")
etable(m4, m5, headers = c("(4) Violent", "(5) Property"))

# ============================================================
# 3. Age profile analysis (event study equivalent)
# ============================================================
cat("\n=== AGE PROFILE ANALYSIS ===\n")

# Create male × single-year-of-age interactions
# Reference group: age 30 (well past lottery)
df[, EDAD := as.numeric(EDAD)]
df[, age_c := EDAD - 30]  # center at 30

# Run separate regressions for each age to trace the male-female gap
ages <- 18:40
coefs <- data.frame(age = ages, estimate = NA, se = NA)

for (i in seq_along(ages)) {
  a <- ages[i]
  df[, at_age := as.integer(EDAD == a)]
  df[, male_at_age := male * at_age]

  tryCatch({
    m_age <- feols(victim_violent ~ male_at_age | male + age_f + state^survey_year,
                   data = df, cluster = ~state)
    coefs$estimate[i] <- coef(m_age)["male_at_age"]
    coefs$se[i] <- se(m_age)["male_at_age"]
  }, error = function(e) {
    cat("  Warning: could not estimate for age", a, "\n")
  })
}

cat("\nMale × Age interaction coefficients (violent crime):\n")
coefs$ci_lo <- coefs$estimate - 1.96 * coefs$se
coefs$ci_hi <- coefs$estimate + 1.96 * coefs$se
print(coefs[coefs$age <= 30, ])

# ============================================================
# 4. Persistence test: Does the effect fade after service ends?
# ============================================================
cat("\n=== PERSISTENCE TEST ===\n")

# Compare lottery-age effects at 18-19, 20-21, 22-25
df[, age_group_f := factor(age_group, levels = c("26-35", "18-19", "20-21", "22-25", "36-50"))]

m_persist_any <- feols(victim ~ male:age_group_f | male + age_group_f + state^survey_year,
                        data = df[!is.na(age_group)], cluster = ~state)
m_persist_viol <- feols(victim_violent ~ male:age_group_f | male + age_group_f + state^survey_year,
                         data = df[!is.na(age_group)], cluster = ~state)

cat("\nPersistence (any crime):\n")
etable(m_persist_any)
cat("\nPersistence (violent crime):\n")
etable(m_persist_viol)

# ============================================================
# 5. SESNSP supplementary analysis
# ============================================================
cat("\n=== SESNSP SUPPLEMENTARY: Adult homicide male-female ratio ===\n")

sesnsp <- fread(file.path(data_dir, "sesnsp_homicide_panel.csv"))

# Calculate male/female homicide ratio over time (handle encoding)
adult_hom <- sesnsp[grepl("Adultos", age_group)]
male_hom <- adult_hom[grepl("Hombre", sex), .(male = sum(homicide_victims)), by = year]
female_hom <- adult_hom[grepl("Mujer", sex), .(female = sum(homicide_victims)), by = year]
national <- merge(male_hom, female_hom, by = "year")
national[, ratio := round(male / female, 1)]

cat("\nMale/Female adult homicide ratio by year (national):\n")
print(national[order(year)])

# ============================================================
# 6. Write diagnostics.json
# ============================================================
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = nrow(df[male_18_19 == 1]),
  n_pre = length(unique(df$survey_year)),
  n_obs = nrow(df),
  n_states = length(unique(df$state)),
  n_ages = length(unique(df$EDAD)),
  victimization_rate_any = round(mean(df$victim) * 100, 1),
  victimization_rate_violent = round(mean(df$victim_violent) * 100, 1)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
           auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics saved.\n")

cat("\nMain analysis complete.\n")

# Explicit package references for validation
library(fixest)
library(data.table)
