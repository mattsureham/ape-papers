## ===========================================================
## 04_robustness.R — Robustness checks and sensitivity
## APEP-0500: Anti-Open Grazing Laws and Farmer-Herder Violence
## ===========================================================

source("00_packages.R")

state_panel <- read_csv(file.path(data_dir, "state_panel.csv"),
                        show_col_types = FALSE)
lga_panel <- read_csv(file.path(data_dir, "lga_panel.csv"),
                      show_col_types = FALSE)
results <- readRDS(file.path(data_dir, "main_results.rds"))

lga_analysis <- lga_panel %>%
  filter(year >= 2010 & year <= 2024) %>%
  mutate(
    post = as.integer(first_treat > 0 & year >= first_treat),
    treat_state = as.integer(first_treat > 0)
  )

# -----------------------------------------------------------
# 1. Wild Cluster Bootstrap
# -----------------------------------------------------------
cat("=== Wild Cluster Bootstrap ===\n")

# Create explicit state_year FE variable (boottest can't handle ^ notation)
lga_analysis <- lga_analysis %>%
  mutate(state_year_fe = interaction(state_id, year, drop = TRUE))

# Re-run DDD with explicit state_year FE for boottest
ddd_for_boot <- tryCatch({
  feols(
    events_nonstate ~
      post:pastoral |
      lga_num + state_year_fe,
    data = lga_analysis,
    cluster = ~ state_id
  )
}, error = function(e) {
  cat("DDD for boot error:", conditionMessage(e), "\n")
  NULL
})

# Wild cluster bootstrap (Webb weights for few clusters)
boot_result <- NULL
if (!is.null(ddd_for_boot)) {
  boot_result <- tryCatch({
    boottest(
      ddd_for_boot,
      param = "post:pastoral",
      clustid = ~ state_id,
      B = 9999,
      type = "webb"  # Webb weights for small cluster counts
    )
  }, error = function(e) {
    cat("WCB error:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(boot_result)) {
    cat("WCB p-value:", boot_result$p_val, "\n")
    cat("WCB CI:", boot_result$conf_int, "\n")
  }
}

# -----------------------------------------------------------
# 2. HonestDiD Sensitivity Analysis
# -----------------------------------------------------------
cat("\n=== HonestDiD Sensitivity ===\n")

# Extract CS results for sensitivity
cs_out <- results$cs_nonstate

tryCatch({
  # Get honest confidence intervals allowing for pre-trend violations
  honest_cs <- honest_did(
    es = results$es_nonstate,
    type = "smoothness",
    Mvec = seq(from = 0, to = 0.5, by = 0.1)
  )
  cat("HonestDiD bounds computed.\n")
  saveRDS(honest_cs, file.path(data_dir, "honest_did_results.rds"))
}, error = function(e) {
  cat("HonestDiD error:", conditionMessage(e), "\n")
  cat("Will proceed with standard pre-trends tests.\n")
})

# -----------------------------------------------------------
# 3. Randomization Inference
# -----------------------------------------------------------
cat("\n=== Randomization Inference ===\n")

# Permute treatment assignment across states
set.seed(42)
n_perms <- 1000

# Get observed DDD coefficient
obs_coef <- coef(ddd_for_boot)["post:pastoral"]

# States in the data
states_in_data <- lga_analysis %>%
  distinct(state, treat_state) %>%
  arrange(state)

n_treated <- sum(states_in_data$treat_state)
n_states <- nrow(states_in_data)

cat(sprintf("RI: %d treated of %d states, %d permutations\n",
            n_treated, n_states, n_perms))

perm_coefs <- numeric(n_perms)

for (i in seq_len(n_perms)) {
  # Randomly assign treatment to same number of states
  perm_treated <- sample(states_in_data$state, n_treated)

  # Create permuted treatment
  perm_data <- lga_analysis %>%
    mutate(
      perm_treat = as.integer(state %in% perm_treated),
      perm_post = as.integer(perm_treat == 1 & year >= first_treat)
    )

  # For never-treated states now "treated", assign random treatment year
  # from the actual treated states' years
  actual_treat_years <- lga_analysis %>%
    filter(treat_state == 1) %>%
    distinct(state, first_treat)

  perm_data <- perm_data %>%
    mutate(
      perm_first_treat = ifelse(
        perm_treat == 1 & first_treat == 0,
        sample(actual_treat_years$first_treat,
               sum(perm_treat == 1 & first_treat == 0),
               replace = TRUE),
        first_treat
      ),
      perm_post = as.integer(perm_treat == 1 & year >= perm_first_treat)
    )

  # Run DDD with permuted treatment (state×year FE)
  perm_fit <- tryCatch({
    feols(
      events_nonstate ~
        perm_post:pastoral |
        lga_num + state_id^year,
      data = perm_data,
      warn = FALSE
    )
  }, error = function(e) NULL)

  if (!is.null(perm_fit)) {
    perm_coefs[i] <- coef(perm_fit)["perm_post:pastoral"]
  }

  if (i %% 200 == 0) cat(sprintf("  RI permutation %d/%d\n", i, n_perms))
}

# RI p-value
ri_pval <- mean(abs(perm_coefs) >= abs(obs_coef), na.rm = TRUE)
cat(sprintf("\nRI p-value (two-sided): %.4f\n", ri_pval))
cat(sprintf("Observed coefficient: %.4f\n", obs_coef))
cat(sprintf("Permutation distribution: mean=%.4f, sd=%.4f\n",
            mean(perm_coefs, na.rm = TRUE), sd(perm_coefs, na.rm = TRUE)))

# Save RI results
saveRDS(list(obs_coef = obs_coef, perm_coefs = perm_coefs, ri_pval = ri_pval),
        file.path(data_dir, "ri_results.rds"))

# -----------------------------------------------------------
# 4. Leave-One-State-Out
# -----------------------------------------------------------
cat("\n=== Leave-One-State-Out ===\n")

treated_states <- states_in_data %>% filter(treat_state == 1) %>% pull(state)
loo_coefs <- numeric(length(treated_states))
names(loo_coefs) <- treated_states

for (s in treated_states) {
  loo_data <- lga_analysis %>% filter(state != s)
  loo_fit <- tryCatch({
    feols(
      events_nonstate ~
        post:pastoral |
        lga_num + state_id^year,
      data = loo_data,
      cluster = ~ state_id
    )
  }, error = function(e) NULL)

  if (!is.null(loo_fit)) {
    loo_coefs[s] <- coef(loo_fit)["post:pastoral"]
  }
}

cat("Leave-one-out coefficients:\n")
print(round(loo_coefs, 4))
cat(sprintf("Range: [%.4f, %.4f]\n", min(loo_coefs), max(loo_coefs)))
cat(sprintf("Main estimate: %.4f\n", obs_coef))

saveRDS(loo_coefs, file.path(data_dir, "loo_results.rds"))

# -----------------------------------------------------------
# 5. Southern Governors' Forum Sub-sample
# -----------------------------------------------------------
cat("\n=== SGF Sub-sample Analysis ===\n")

# States that adopted due to SGF resolution (collective action, less endogenous)
sgf_states <- c("Ondo", "Rivers", "Enugu", "Osun", "Lagos", "Delta", "Ogun")

# Compare SGF adopters vs. early/individual adopters
lga_analysis <- lga_analysis %>%
  mutate(
    sgf_adopter = as.integer(state %in% sgf_states),
    early_adopter = as.integer(first_treat > 0 & first_treat < 2021)
  )

# DDD for SGF sub-sample only
sgf_data <- lga_analysis %>%
  filter(state %in% c(sgf_states, states_in_data$state[states_in_data$treat_state == 0]))

ddd_sgf <- feols(
  events_nonstate ~
    post:pastoral |
    lga_num + state_id^year,
  data = sgf_data,
  cluster = ~ state_id
)

cat("DDD for SGF sub-sample:\n")
summary(ddd_sgf)

# -----------------------------------------------------------
# 6. Spatial Displacement Test
# -----------------------------------------------------------
cat("\n=== Spatial Displacement Test ===\n")

# Do events shift to neighboring untreated states?
# Test: violence in border LGAs of untreated states neighboring treated states

# For now, test at state level: does violence increase in states
# bordering treated states?
# (Full spatial analysis would need LGA adjacency matrix)

ddd_onesided <- feols(
  events_onesided ~
    post:pastoral |
    lga_num + state_id^year,
  data = lga_analysis,
  cluster = ~ state_id
)

cat("DDD for one-sided violence (PLACEBO):\n")
summary(ddd_onesided)

# -----------------------------------------------------------
# 7. Alternative Outcome: Log(events + 1)
# -----------------------------------------------------------
cat("\n=== Log Outcome ===\n")

lga_analysis <- lga_analysis %>%
  mutate(log_events_nonstate = log(events_nonstate + 1))

ddd_log <- feols(
  log_events_nonstate ~
    post:pastoral |
    lga_num + state_id^year,
  data = lga_analysis,
  cluster = ~ state_id
)

cat("DDD with log(events+1):\n")
summary(ddd_log)

# -----------------------------------------------------------
# 8. DDD Event Study (leads/lags of D_st × P_i)
# -----------------------------------------------------------
cat("\n=== DDD Event Study ===\n")

# Create event-time variable for each LGA
lga_analysis <- lga_analysis %>%
  mutate(
    event_time = ifelse(first_treat > 0, year - first_treat, NA_real_)
  )

# Bin event-time: group extreme leads/lags
lga_analysis <- lga_analysis %>%
  mutate(
    et_binned = case_when(
      is.na(event_time) ~ NA_real_,
      event_time <= -5 ~ -5,
      event_time >= 5 ~ 5,
      TRUE ~ event_time
    )
  )

# Create indicator variables for each event-time bin (relative to -1)
et_values <- sort(unique(na.omit(lga_analysis$et_binned)))
et_values <- et_values[et_values != -1]  # reference period

for (k in et_values) {
  varname <- paste0("et_", ifelse(k < 0, paste0("m", abs(k)), k))
  lga_analysis[[varname]] <- as.integer(!is.na(lga_analysis$et_binned) &
                                         lga_analysis$et_binned == k)
}

# Create interactions with pastoral
et_vars <- grep("^et_", names(lga_analysis), value = TRUE)
for (v in et_vars) {
  lga_analysis[[paste0(v, "_pastoral")]] <- lga_analysis[[v]] * lga_analysis$pastoral
}

# Run DDD event study
pastoral_vars <- paste(grep("_pastoral$", names(lga_analysis), value = TRUE),
                       collapse = " + ")

ddd_es_formula <- as.formula(
  paste("events_nonstate ~", pastoral_vars, "| lga_num + state_id^year")
)

ddd_es <- tryCatch({
  feols(ddd_es_formula, data = lga_analysis, cluster = ~ state_id)
}, error = function(e) {
  cat("DDD event study error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(ddd_es)) {
  es_coefs <- coef(ddd_es)
  es_se <- se(ddd_es)
  pastoral_coefs <- es_coefs[grep("_pastoral$", names(es_coefs))]
  pastoral_se <- es_se[grep("_pastoral$", names(es_se))]

  # Parse event-time from variable names (e.g., "et_m3_pastoral" -> -3, "et_2_pastoral" -> 2)
  vnames <- names(pastoral_coefs)
  es_times <- sapply(vnames, function(v) {
    if (grepl("^et_m\\d+_pastoral$", v)) {
      return(-as.numeric(gsub("et_m(\\d+)_pastoral", "\\1", v)))
    } else if (grepl("^et_\\d+_pastoral$", v)) {
      return(as.numeric(gsub("et_(\\d+)_pastoral", "\\1", v)))
    } else {
      return(NA_real_)
    }
  })

  ddd_es_df <- data.frame(
    e = es_times,
    att = unname(pastoral_coefs),
    se = unname(pastoral_se)
  ) %>%
    filter(!is.na(e)) %>%
    arrange(e) %>%
    mutate(ci_lo = att - 1.96 * se, ci_hi = att + 1.96 * se)

  # Add the reference period
  ddd_es_df <- bind_rows(
    ddd_es_df,
    data.frame(e = -1, att = 0, se = 0, ci_lo = 0, ci_hi = 0)
  ) %>% arrange(e)

  cat("DDD event study coefficients:\n")
  print(ddd_es_df)

  saveRDS(ddd_es_df, file.path(data_dir, "ddd_event_study.rds"))

  # Joint pre-trend test (pre-period coefficients jointly = 0)
  pre_vars <- names(pastoral_coefs)[es_times < -1]
  if (length(pre_vars) >= 2) {
    pre_test <- tryCatch({
      wald(ddd_es, paste(pre_vars, collapse = " + "), vcov = ~ state_id)
    }, error = function(e) {
      cat("Joint pretrend test error:", conditionMessage(e), "\n")
      NULL
    })
    if (!is.null(pre_test)) {
      cat("Joint pre-trend test (DDD):", pre_test, "\n")
    }
  }
}

# -----------------------------------------------------------
# 9. Alternative Pastoral Classification: Pre-2010 Events
# -----------------------------------------------------------
cat("\n=== Alternative Pastoral Classification (Pre-2010, Outside Estimation Window) ===\n")

# Use UCDP events from 1990-2009 (entirely outside the 2010-2024 estimation window)
# This addresses the concern about mechanical mean reversion from same-period selection
ged_raw <- fread(file.path(data_dir, "ucdp_nigeria.csv"))

nga_lgas_sf <- st_read(file.path(data_dir, "nga_lgas.gpkg"),
                        layer = "lgas", quiet = TRUE)

# Spatial join for pre-2010 events
pre2010_events <- ged_raw %>%
  filter(year >= 1990 & year <= 2009,
         type_of_violence == 2,
         !is.na(latitude) & !is.na(longitude)) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

pre2010_lga <- st_join(pre2010_events, nga_lgas_sf[, c("GID_2")],
                        join = st_within) %>%
  st_drop_geometry()

# LGAs with any pre-2010 non-state violence
pastoral_pre2010 <- pre2010_lga %>%
  filter(!is.na(GID_2)) %>%
  group_by(GID_2) %>%
  summarise(pre_events = n(), .groups = "drop") %>%
  filter(pre_events >= 1) %>%  # Lower threshold for sparser pre-period
  pull(GID_2)

lga_analysis <- lga_analysis %>%
  mutate(pastoral_pre2010 = as.integer(lga_id %in% pastoral_pre2010))

cat(sprintf("Pre-2010 pastoral LGAs: %d (%.1f%%)\n",
            sum(lga_analysis$pastoral_pre2010[lga_analysis$year == 2015]),
            100 * mean(lga_analysis$pastoral_pre2010[lga_analysis$year == 2015])))

ddd_geo <- tryCatch({
  feols(
    events_nonstate ~
      post:pastoral_pre2010 |
      lga_num + state_id^year,
    data = lga_analysis,
    cluster = ~ state_id
  )
}, error = function(e) {
  cat("Pre-2010 classification error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(ddd_geo)) {
  cat("DDD with pre-2010 pastoral classification:\n")
  summary(ddd_geo)
}

# -----------------------------------------------------------
# 10. Poisson/PPML Model
# -----------------------------------------------------------
cat("\n=== Poisson Pseudo-Maximum Likelihood ===\n")

ddd_ppml <- tryCatch({
  fepois(
    events_nonstate ~
      post:pastoral |
      lga_num + state_id^year,
    data = lga_analysis,
    cluster = ~ state_id
  )
}, error = function(e) {
  cat("PPML error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(ddd_ppml)) {
  cat("PPML (Poisson) DDD:\n")
  summary(ddd_ppml)
  ppml_coef <- coef(ddd_ppml)["post:pastoral"]
  ppml_se <- se(ddd_ppml)["post:pastoral"]
  cat(sprintf("IRR = %.4f (exp(%.4f))\n", exp(ppml_coef), ppml_coef))
}

# -----------------------------------------------------------
# 11. Spatial Spillover Analysis
# -----------------------------------------------------------
cat("\n=== Spatial Spillover Analysis ===\n")

# Identify LGAs in never-treated states that border treated states
# (nga_lgas_sf already loaded above in section 9)

# Build adjacency: which LGAs touch each other?
adj <- st_touches(nga_lgas_sf)

# Load treatment data
treatment_data <- read_csv(file.path(data_dir, "treatment_assignment.csv"),
                            show_col_types = FALSE)

# For each never-treated-state LGA, check if any neighbor is in a treated state
treated_state_names <- treatment_data %>% filter(first_treat > 0) %>% pull(state)

lga_state_map <- nga_lgas_sf %>%
  st_drop_geometry() %>%
  select(lga_id = GID_2, state_name = NAME_1) %>%
  mutate(in_treated_state = state_name %in% treated_state_names)

# Find border LGAs: in untreated state but adjacent to treated-state LGA
border_lgas <- c()
for (i in seq_len(nrow(nga_lgas_sf))) {
  lga_st <- lga_state_map$state_name[i]
  if (lga_st %in% treated_state_names) next  # skip treated states

  neighbors <- adj[[i]]
  neighbor_states <- lga_state_map$state_name[neighbors]
  if (any(neighbor_states %in% treated_state_names)) {
    border_lgas <- c(border_lgas, lga_state_map$lga_id[i])
  }
}

cat(sprintf("Border LGAs (untreated state, adjacent to treated): %d\n",
            length(border_lgas)))

# Create border indicator and test for spillovers
lga_analysis <- lga_analysis %>%
  mutate(border_lga = as.integer(lga_id %in% border_lgas))

# Spillover test: do border LGAs experience violence increases?
# Use the earliest treatment year as the "shock" for border LGAs
earliest_treat <- min(treatment_data$first_treat[treatment_data$first_treat > 0])

# Restrict to never-treated states for the spillover test
spillover_data <- lga_analysis %>%
  filter(first_treat == 0) %>%
  mutate(post_spillover = as.integer(year >= earliest_treat))

ddd_spillover <- tryCatch({
  feols(
    events_nonstate ~
      post_spillover:border_lga |
      lga_num + state_id^year,
    data = spillover_data,
    cluster = ~ state_id
  )
}, error = function(e) {
  cat("Spillover test error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(ddd_spillover)) {
  cat("Spillover test (border LGAs in untreated states):\n")
  summary(ddd_spillover)
}

# -----------------------------------------------------------
# 12. Save all robustness results
# -----------------------------------------------------------
robust_results <- list(
  boot_result = boot_result,
  ri_pval = ri_pval,
  loo_coefs = loo_coefs,
  ddd_sgf = ddd_sgf,
  ddd_onesided = ddd_onesided,
  ddd_log = ddd_log,
  ddd_geo = ddd_geo,
  ddd_ppml = ddd_ppml,
  ddd_spillover = ddd_spillover,
  ddd_es_df = if (exists("ddd_es_df")) ddd_es_df else NULL
)

saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))
cat("\nAll robustness checks complete.\n")
