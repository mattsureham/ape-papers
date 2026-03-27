# 04_robustness.R — Robustness checks
# apep_1077: Child Labor Law Rollbacks DDD

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
load("../data/main_results.RData")

# ============================================================================
# 1. RANDOMIZATION INFERENCE (permutation test on treatment assignment)
# ============================================================================
cat("=== Randomization Inference ===\n")

# Permute state treatment assignment 999 times
set.seed(42)
observed_coef <- coef(m1_emp)["post:teen:food_retail"]

state_list <- unique(panel$state_fips)
n_treated <- uniqueN(panel[treated_state == 1]$state_fips)
n_perms <- 999
perm_coefs <- numeric(n_perms)

for (p in seq_len(n_perms)) {
  # Randomly assign treatment to same number of states
  fake_treated <- sample(state_list, n_treated)
  perm_data <- copy(panel)
  perm_data[, fake_treat := as.integer(state_fips %in% fake_treated)]
  # Assign earliest real treatment time to fake-treated states
  perm_data[, fake_post := as.integer(fake_treat == 1 & yq >= 2023.0)]

  tryCatch({
    m_perm <- feols(
      log_emp ~ fake_post:teen:food_retail + fake_post:teen + fake_post:food_retail + teen:food_retail |
        state_fips + time_period + industry + agegrp,
      data = perm_data
    )
    perm_coefs[p] <- coef(m_perm)["fake_post:teen:food_retail"]
  }, error = function(e) {
    perm_coefs[p] <<- NA
  })
}

perm_coefs <- perm_coefs[!is.na(perm_coefs)]
ri_pval <- mean(abs(perm_coefs) >= abs(observed_coef))
cat(sprintf("RI p-value (two-sided): %.4f\n", ri_pval))
cat(sprintf("Observed DDD coef: %.4f\n", observed_coef))
cat(sprintf("Permutation distribution: mean=%.4f, sd=%.4f\n",
            mean(perm_coefs), sd(perm_coefs)))

boot_result <- list(p_val = ri_pval)

# ============================================================================
# 2. PLACEBO: OLDER ADULTS (age 25-34, A04)
# ============================================================================
cat("\n=== Placebo: Older Adults ===\n")

# Fetch A04 (25-34) data from Azure to use as placebo age group
env_file <- "../../../../.env"
lines <- readLines(env_file, warn = FALSE)
conn_str <- NULL
for (l in lines) {
  if (grepl("^AZURE_STORAGE_CONNECTION_STRING=", l)) {
    conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", l)
  }
}

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, "SET azure_transport_option_type = 'curl'")
dbExecute(con, sprintf("CREATE SECRET (TYPE AZURE, CONNECTION_STRING '%s')", conn_str))

placebo_raw <- dbGetQuery(con, "
  SELECT geography AS fips, industry, agegrp, year, quarter,
         Emp AS emp, HirA AS hires, Sep AS separations, EarnS AS earnings
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE geo_level = 'C' AND ownercode = 'A05' AND sex = '0'
    AND agegrp = 'A04'
    AND industry IN ('72', '44-45', '54')
    AND year >= 2018
    AND periodicity = 'Q' AND seasonadj = 'U'
")
dbDisconnect(con)

placebo_dt <- as.data.table(placebo_raw)
placebo_dt[, state_fips := as.integer(fips %/% 1000)]

state_map <- data.table(
  state_fips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,
                 26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,
                 47,48,49,50,51,53,54,55,56),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI",
                 "ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN",
                 "MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH",
                 "OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA",
                 "WV","WI","WY")
)
placebo_dt <- merge(placebo_dt, state_map, by = "state_fips", all.x = TRUE)
placebo_dt <- placebo_dt[!is.na(state_abbr)]

treatment <- data.table(
  state_abbr = c("NH", "NJ", "IA", "AR", "TN", "AL", "FL", "IN", "KY", "WV",
                 "OH", "MO"),
  treat_year = c(2022, 2022, 2023, 2023, 2023, 2024, 2024, 2024, 2024, 2024,
                 2024, 2024),
  treat_quarter = c(3, 1, 3, 3, 3, 1, 3, 3, 3, 3, 1, 1)
)
treatment[, treat_yq := treat_year + (treat_quarter - 1) / 4]

placebo_dt <- merge(placebo_dt, treatment, by = "state_abbr", all.x = TRUE)
placebo_dt[is.na(treat_year), treat_year := 0]
placebo_dt[is.na(treat_yq), treat_yq := 0]
placebo_dt[, yq := year + (quarter - 1) / 4]
placebo_dt[, treated_state := as.integer(treat_year > 0)]
placebo_dt[, post := as.integer(treat_yq > 0 & yq >= treat_yq)]
placebo_dt[, food_retail := as.integer(industry %in% c("72", "44-45"))]

# Aggregate to state level
placebo_panel <- placebo_dt[, .(emp = sum(emp, na.rm = TRUE)),
                            by = .(state_fips, state_abbr, industry, agegrp, year, quarter,
                                   yq, treated_state, post, food_retail)]
placebo_panel[, log_emp := log(emp + 1)]
placebo_panel[, time_period := as.integer((year - 2018) * 4 + quarter)]

# Placebo DD: adults in food/retail vs professional, treated vs control
m_placebo <- feols(
  log_emp ~ post:food_retail |
    state_fips^time_period + industry^time_period,
  data = placebo_panel,
  cluster = ~state_fips
)

cat("Placebo test (25-34 year olds, DD on food/retail):\n")
print(summary(m_placebo))

# ============================================================================
# 3. EXCLUDING COVID-ERA STATES (NH, NJ — passed laws during COVID recovery)
# ============================================================================
cat("\n=== Excluding COVID-Era States (NH, NJ) ===\n")

panel_excl_covid <- panel[!(state_abbr %in% c("NH", "NJ"))]
panel_excl_covid[, cohort_yq := fifelse(treated_state == 1, treat_yq, 0)]

m_excl_covid <- feols(
  log_emp ~ post:teen:food_retail + post:teen + post:food_retail + teen:food_retail |
    state_fips^time_period + industry^time_period + agegrp^time_period +
    state_fips^industry^agegrp,
  data = panel_excl_covid,
  cluster = ~state_fips
)

cat("DDD excluding NH/NJ (COVID-era adopters):\n")
print(summary(m_excl_covid))

# ============================================================================
# 4. DOSE-RESPONSE: Law Stringency Index
# ============================================================================
cat("\n=== Dose-Response: Stringency ===\n")

# Classify laws by stringency (number of provisions weakened)
# NH: extended hours; NJ: extended hours; IA: hours + age + permits;
# AR: hours + permits; TN: hours; AL: hours; FL: hours + age;
# IN: hours + age; KY: hours; WV: hours; OH: hours + permits; MO: hours
stringency <- data.table(
  state_abbr = c("NH", "NJ", "IA", "AR", "TN", "AL", "FL", "IN", "KY", "WV",
                 "OH", "MO"),
  n_provisions = c(1, 1, 3, 2, 1, 1, 2, 2, 1, 1, 2, 1)
)

panel_dose <- merge(panel, stringency, by = "state_abbr", all.x = TRUE)
panel_dose[is.na(n_provisions), n_provisions := 0]
panel_dose[, dose := post * teen * food_retail * n_provisions]

m_dose <- feols(
  log_emp ~ dose + post:teen + post:food_retail + teen:food_retail |
    state_fips^time_period + industry^time_period + agegrp^time_period +
    state_fips^industry^agegrp,
  data = panel_dose,
  cluster = ~state_fips
)

cat("Dose-response (DDD x n_provisions):\n")
print(summary(m_dose))

# ============================================================================
# SAVE ALL ROBUSTNESS RESULTS
# ============================================================================
save(boot_result, m_placebo, m_excl_covid, m_dose,
     file = "../data/robustness_results.RData")

cat("\nAll robustness checks complete. Saved to data/robustness_results.RData\n")
