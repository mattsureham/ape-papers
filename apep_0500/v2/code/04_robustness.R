## ===========================================================
## 04_robustness.R — Robustness checks and sensitivity
## APEP-0500 v2: Anti-Open Grazing Laws and Farmer-Herder Violence
## Fixes: RI redesign, WCB fix, geography-only classification,
##        within-state displacement test
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
# 1. Wild Cluster Bootstrap (Fix 4)
# -----------------------------------------------------------
cat("=== Wild Cluster Bootstrap ===\n")

lga_analysis <- lga_analysis %>%
  mutate(state_year_fe = interaction(state_id, year, drop = TRUE))

# Try WCB on the preferred spec with explicit state_year FE
ddd_for_boot <- tryCatch({
  feols(
    events_nonstate ~
      post:pastoral |
      lga_num + state_year_fe,
    data = lga_analysis,
    cluster = ~ state_id
  )
}, error = function(e) {
  cat("DDD for boot (state×year FE) error:", conditionMessage(e), "\n")
  NULL
})

boot_result_final <- NULL
boot_spec <- "Failed"

if (!is.null(ddd_for_boot)) {
  set.seed(2024)
  boot_result_final <- tryCatch({
    boottest(
      ddd_for_boot,
      param = "post:pastoral",
      clustid = ~ state_id,
      B = 9999,
      type = "webb"
    )
  }, error = function(e) {
    cat("WCB preferred spec error:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(boot_result_final)) {
    boot_spec <- "State×Year FE (Webb)"
    cat(sprintf("WCB p-value (State×Year FE): %.4f\n", boot_result_final$p_val))
  }
}

# Fallback: WCB on simpler LGA + year FE spec
if (is.null(boot_result_final)) {
  cat("Trying WCB on simpler LGA + year FE spec...\n")
  ddd_simple_fe <- feols(
    events_nonstate ~
      post + post:pastoral |
      lga_num + year,
    data = lga_analysis,
    cluster = ~ state_id
  )

  set.seed(2024)
  boot_result_final <- tryCatch({
    boottest(
      ddd_simple_fe,
      param = "post:pastoral",
      clustid = ~ state_id,
      B = 9999,
      type = "webb"
    )
  }, error = function(e) {
    cat("WCB simple spec error:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(boot_result_final)) {
    boot_spec <- "LGA+Year FE (Webb)"
    cat(sprintf("WCB p-value (LGA+Year FE): %.4f\n", boot_result_final$p_val))
  }
}

# Final fallback: Manual Rademacher WCB on preferred spec
if (is.null(boot_result_final)) {
  cat("Attempting manual Rademacher wild cluster bootstrap on preferred spec...\n")
  set.seed(123)
  n_boot <- 999
  states_vec <- unique(lga_analysis$state_id)
  n_clusters <- length(states_vec)

  ddd_preferred <- feols(
    events_nonstate ~
      post:pastoral |
      lga_num + state_id^year,
    data = lga_analysis,
    cluster = ~ state_id
  )
  obs_t <- coef(ddd_preferred)["post:pastoral"] / se(ddd_preferred)["post:pastoral"]

  lga_null <- lga_analysis %>%
    mutate(y_null = events_nonstate - coef(ddd_preferred)["post:pastoral"] * post * pastoral)

  boot_t <- numeric(n_boot)
  for (b in seq_len(n_boot)) {
    weights <- sample(c(-1, 1), n_clusters, replace = TRUE)
    names(weights) <- states_vec

    lga_boot <- lga_null %>%
      mutate(
        resid = y_null - fitted(ddd_preferred) + coef(ddd_preferred)["post:pastoral"] * post * pastoral,
        y_boot = fitted(ddd_preferred) + resid * weights[as.character(state_id)]
      )

    boot_fit <- tryCatch({
      feols(
        y_boot ~ post:pastoral | lga_num + state_id^year,
        data = lga_boot,
        cluster = ~ state_id,
        warn = FALSE
      )
    }, error = function(e) NULL)

    if (!is.null(boot_fit)) {
      boot_t[b] <- coef(boot_fit)["post:pastoral"] / se(boot_fit)["post:pastoral"]
    }
  }

  boot_pval <- mean(abs(boot_t) >= abs(obs_t), na.rm = TRUE)
  cat(sprintf("Manual WCB p-value (Rademacher, %d reps): %.4f\n", n_boot, boot_pval))
  boot_result_final <- list(p_val = boot_pval, type = "manual_rademacher", B = n_boot)
  boot_spec <- "Rademacher (preferred spec)"
}

cat(sprintf("\nFinal WCB result — spec: %s, p-value: %.4f\n",
            boot_spec, boot_result_final$p_val))

# -----------------------------------------------------------
# 2. HonestDiD Sensitivity Analysis
# -----------------------------------------------------------
cat("\n=== HonestDiD Sensitivity ===\n")

cs_out <- results$cs_nonstate

tryCatch({
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
# 3. Randomization Inference (Fix 1: preserve cohort vector)
# -----------------------------------------------------------
cat("\n=== Randomization Inference (Cohort-Preserving) ===\n")

set.seed(42)
n_perms <- 1000

# Get observed DDD coefficient from preferred spec
obs_coef <- coef(results$ddd_saturated)["post:pastoral"]

# States in the data
states_in_data <- lga_analysis %>%
  distinct(state, treat_state, first_treat) %>%
  arrange(state)

n_treated <- sum(states_in_data$treat_state)
n_states <- nrow(states_in_data)

# Extract the EXACT cohort vector from actual treated states
# This preserves the staggered adoption structure
actual_cohorts <- states_in_data %>%
  filter(treat_state == 1) %>%
  pull(first_treat)

cat(sprintf("RI: %d treated of %d states, %d permutations\n",
            n_treated, n_states, n_perms))
cat(sprintf("Cohort vector (preserved): %s\n",
            paste(sort(actual_cohorts), collapse = ", ")))

perm_coefs <- numeric(n_perms)

for (i in seq_len(n_perms)) {
  # Step 1: Randomly select 14 of 37 states
  perm_treated_states <- sample(states_in_data$state, n_treated)

  # Step 2: Randomly assign the 14-element cohort vector to them
  perm_cohort_assignment <- sample(actual_cohorts)  # shuffle the exact cohort years

  # Build a lookup: permuted state -> permuted first_treat
  perm_lookup <- tibble(
    state = perm_treated_states,
    perm_first_treat = perm_cohort_assignment
  )

  # Merge to full data
  perm_data <- lga_analysis %>%
    left_join(perm_lookup, by = "state") %>%
    mutate(
      perm_first_treat = replace_na(perm_first_treat, 0L),
      perm_post = as.integer(perm_first_treat > 0 & year >= perm_first_treat)
    )

  # Run DDD with permuted treatment
  perm_fit <- tryCatch({
    feols(
      events_nonstate ~
        perm_post:pastoral |
        lga_num + state_id^year,
      data = perm_data,
      warn = FALSE
    )
  }, error = function(e) NULL)

  if (!is.null(perm_fit) && "perm_post:pastoral" %in% names(coef(perm_fit))) {
    perm_coefs[i] <- coef(perm_fit)["perm_post:pastoral"]
  } else {
    perm_coefs[i] <- NA_real_
  }

  if (i %% 200 == 0) cat(sprintf("  RI permutation %d/%d\n", i, n_perms))
}

# RI p-value
ri_pval <- mean(abs(perm_coefs) >= abs(obs_coef), na.rm = TRUE)
cat(sprintf("\nRI p-value (two-sided): %.4f\n", ri_pval))
cat(sprintf("Observed coefficient: %.4f\n", obs_coef))
cat(sprintf("Permutation distribution: mean=%.4f, sd=%.4f\n",
            mean(perm_coefs, na.rm = TRUE), sd(perm_coefs, na.rm = TRUE)))

# Verify centering: mean should be close to 0
if (abs(mean(perm_coefs, na.rm = TRUE)) > 0.02) {
  cat("WARNING: Permutation mean not centered near 0. Check design.\n")
} else {
  cat("PASS: Permutation distribution centered near 0 (within ±0.02).\n")
}

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

sgf_states <- c("Ondo", "Rivers", "Enugu", "Osun", "Lagos", "Delta", "Ogun")

lga_analysis <- lga_analysis %>%
  mutate(
    sgf_adopter = as.integer(state %in% sgf_states),
    early_adopter = as.integer(first_treat > 0 & first_treat < 2021)
  )

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
# 6. Cross-State Spatial Displacement Test
# -----------------------------------------------------------
cat("\n=== Spatial Displacement Test (Cross-State) ===\n")

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

lga_analysis <- lga_analysis %>%
  mutate(
    event_time = ifelse(first_treat > 0, year - first_treat, NA_real_)
  )

lga_analysis <- lga_analysis %>%
  mutate(
    et_binned = case_when(
      is.na(event_time) ~ NA_real_,
      event_time <= -5 ~ -5,
      event_time >= 5 ~ 5,
      TRUE ~ event_time
    )
  )

et_values <- sort(unique(na.omit(lga_analysis$et_binned)))
et_values <- et_values[et_values != -1]

for (k in et_values) {
  varname <- paste0("et_", ifelse(k < 0, paste0("m", abs(k)), k))
  lga_analysis[[varname]] <- as.integer(!is.na(lga_analysis$et_binned) &
                                         lga_analysis$et_binned == k)
}

et_vars <- grep("^et_", names(lga_analysis), value = TRUE)
for (v in et_vars) {
  lga_analysis[[paste0(v, "_pastoral")]] <- lga_analysis[[v]] * lga_analysis$pastoral
}

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

  ddd_es_df <- bind_rows(
    ddd_es_df,
    data.frame(e = -1, att = 0, se = 0, ci_lo = 0, ci_hi = 0)
  ) %>% arrange(e)

  cat("DDD event study coefficients:\n")
  print(ddd_es_df)

  saveRDS(ddd_es_df, file.path(data_dir, "ddd_event_study.rds"))

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
cat("\n=== Alternative Pastoral Classification (Pre-2010) ===\n")

ged_raw <- fread(file.path(data_dir, "ucdp_nigeria.csv"))

nga_lgas_sf <- st_read(file.path(data_dir, "nga_lgas.gpkg"),
                        layer = "lgas", quiet = TRUE)

pre2010_events <- ged_raw %>%
  filter(year >= 1990 & year <= 2009,
         type_of_violence == 2,
         !is.na(latitude) & !is.na(longitude)) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

pre2010_lga <- st_join(pre2010_events, nga_lgas_sf[, c("GID_2")],
                        join = st_within) %>%
  st_drop_geometry()

pastoral_pre2010 <- pre2010_lga %>%
  filter(!is.na(GID_2)) %>%
  group_by(GID_2) %>%
  summarise(pre_events = n(), .groups = "drop") %>%
  filter(pre_events >= 1) %>%
  pull(GID_2)

lga_analysis <- lga_analysis %>%
  mutate(pastoral_pre2010 = as.integer(lga_id %in% pastoral_pre2010))

cat(sprintf("Pre-2010 pastoral LGAs: %d (%.1f%%)\n",
            sum(lga_analysis$pastoral_pre2010[lga_analysis$year == 2015]),
            100 * mean(lga_analysis$pastoral_pre2010[lga_analysis$year == 2015])))

ddd_pre2010 <- tryCatch({
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

if (!is.null(ddd_pre2010)) {
  cat("DDD with pre-2010 pastoral classification:\n")
  summary(ddd_pre2010)
}

# -----------------------------------------------------------
# 10. Geography-Only Pastoral Classification (Fix 3)
# -----------------------------------------------------------
cat("\n=== Geography-Only Pastoral Classification (No Violence History) ===\n")

# pastoral_geo uses Middle Belt geography + GLW cattle density
# NO pre-treatment violence data — eliminates RTM concern entirely

ddd_geo <- tryCatch({
  feols(
    events_nonstate ~
      post:pastoral_geo |
      lga_num + state_id^year,
    data = lga_analysis,
    cluster = ~ state_id
  )
}, error = function(e) {
  cat("Geography-only DDD error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(ddd_geo)) {
  cat("DDD with geography-only pastoral classification:\n")
  summary(ddd_geo)
  geo_coef <- coef(ddd_geo)["post:pastoral_geo"]
  geo_se <- se(ddd_geo)["post:pastoral_geo"]
  geo_pval <- 2 * pt(-abs(geo_coef / geo_se), df = n_distinct(lga_analysis$state_id) - 1)
  cat(sprintf("Geography-only DDD: %.4f (SE=%.4f, p=%.4f)\n", geo_coef, geo_se, geo_pval))
}

# Conflict-only classification (for comparison)
cat("\n=== Conflict-Only Pastoral Classification ===\n")

ddd_conflict <- tryCatch({
  feols(
    events_nonstate ~
      post:pastoral_conflict |
      lga_num + state_id^year,
    data = lga_analysis,
    cluster = ~ state_id
  )
}, error = function(e) {
  cat("Conflict-only DDD error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(ddd_conflict)) {
  cat("DDD with conflict-only pastoral classification:\n")
  summary(ddd_conflict)
}

# -----------------------------------------------------------
# 11. Poisson/PPML Model
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
# 12. Cross-State Spatial Spillover Analysis
# -----------------------------------------------------------
cat("\n=== Spatial Spillover Analysis ===\n")

adj <- st_touches(nga_lgas_sf)

treatment_data <- read_csv(file.path(data_dir, "treatment_assignment.csv"),
                            show_col_types = FALSE)

treated_state_names <- treatment_data %>% filter(first_treat > 0) %>% pull(state)

lga_state_map <- nga_lgas_sf %>%
  st_drop_geometry() %>%
  select(lga_id = GID_2, state_name = NAME_1) %>%
  mutate(in_treated_state = state_name %in% treated_state_names)

border_lgas <- c()
for (i in seq_len(nrow(nga_lgas_sf))) {
  lga_st <- lga_state_map$state_name[i]
  if (lga_st %in% treated_state_names) next

  neighbors <- adj[[i]]
  neighbor_states <- lga_state_map$state_name[neighbors]
  if (any(neighbor_states %in% treated_state_names)) {
    border_lgas <- c(border_lgas, lga_state_map$lga_id[i])
  }
}

cat(sprintf("Border LGAs (untreated state, adjacent to treated): %d\n",
            length(border_lgas)))

lga_analysis <- lga_analysis %>%
  mutate(border_lga = as.integer(lga_id %in% border_lgas))

earliest_treat <- min(treatment_data$first_treat[treatment_data$first_treat > 0])

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
# 13. Within-State Displacement Test (Fix 2: NEW)
# -----------------------------------------------------------
cat("\n=== Within-State Displacement Test ===\n")

# If anti-grazing laws displace violence from pastoral to non-pastoral
# LGAs within treated states, this would mechanically generate a
# negative DDD. Test: DD for non-pastoral LGAs in treated states only.
# The coefficient should be ~0 if deterrence, positive if displacement.

# (A) DD for non-pastoral LGAs in treated states
nonpastoral_treated <- lga_analysis %>%
  filter(treat_state == 1, pastoral == 0)

dd_nonpastoral <- tryCatch({
  feols(
    events_nonstate ~ post | lga_num + year,
    data = nonpastoral_treated,
    cluster = ~ state_id
  )
}, error = function(e) {
  cat("Non-pastoral DD error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(dd_nonpastoral)) {
  cat("DD for non-pastoral LGAs in treated states (should be ~0):\n")
  summary(dd_nonpastoral)
  np_coef <- coef(dd_nonpastoral)["post"]
  np_se <- se(dd_nonpastoral)["post"]
  np_pval <- 2 * pt(-abs(np_coef / np_se), df = n_distinct(nonpastoral_treated$state_id) - 1)
  cat(sprintf("Non-pastoral DD: %.4f (SE=%.4f, p=%.4f)\n", np_coef, np_se, np_pval))
}

# (B) Event study for non-pastoral LGAs in treated states
nonpastoral_treated <- nonpastoral_treated %>%
  mutate(
    event_time = year - first_treat,
    et_binned = case_when(
      event_time <= -5 ~ -5,
      event_time >= 5 ~ 5,
      TRUE ~ event_time
    )
  )

et_vals_np <- sort(unique(nonpastoral_treated$et_binned))
et_vals_np <- et_vals_np[et_vals_np != -1]

for (k in et_vals_np) {
  varname <- paste0("et_np_", ifelse(k < 0, paste0("m", abs(k)), k))
  nonpastoral_treated[[varname]] <- as.integer(nonpastoral_treated$et_binned == k)
}

np_et_vars <- paste(grep("^et_np_", names(nonpastoral_treated), value = TRUE),
                    collapse = " + ")

np_es_formula <- as.formula(
  paste("events_nonstate ~", np_et_vars, "| lga_num + year")
)

dd_np_es <- tryCatch({
  feols(np_es_formula, data = nonpastoral_treated, cluster = ~ state_id)
}, error = function(e) {
  cat("Non-pastoral event study error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(dd_np_es)) {
  np_es_coefs <- coef(dd_np_es)
  np_es_se <- se(dd_np_es)

  np_es_times <- sapply(names(np_es_coefs), function(v) {
    if (grepl("^et_np_m\\d+$", v)) {
      return(-as.numeric(gsub("et_np_m(\\d+)", "\\1", v)))
    } else if (grepl("^et_np_\\d+$", v)) {
      return(as.numeric(gsub("et_np_(\\d+)", "\\1", v)))
    } else {
      return(NA_real_)
    }
  })

  np_es_df <- data.frame(
    e = np_es_times,
    att = unname(np_es_coefs),
    se = unname(np_es_se)
  ) %>%
    filter(!is.na(e)) %>%
    arrange(e) %>%
    mutate(ci_lo = att - 1.96 * se, ci_hi = att + 1.96 * se)

  np_es_df <- bind_rows(
    np_es_df,
    data.frame(e = -1, att = 0, se = 0, ci_lo = 0, ci_hi = 0)
  ) %>% arrange(e)

  cat("Non-pastoral event study (within treated states):\n")
  print(np_es_df)

  saveRDS(np_es_df, file.path(data_dir, "displacement_event_study.rds"))
}

# (C) Total violence (all LGAs) in treated vs control states
# If deterrence: total violence should fall
# If displacement: total violence should stay the same
cat("\n--- Total Violence Test (All LGAs, Treated vs Control) ---\n")

ddd_total <- tryCatch({
  feols(
    events_nonstate ~ post | lga_num + year,
    data = lga_analysis,
    cluster = ~ state_id
  )
}, error = function(e) NULL)

if (!is.null(ddd_total)) {
  cat("DD for total violence (all LGAs, treated vs control):\n")
  summary(ddd_total)
}

# -----------------------------------------------------------
# 14. Save all robustness results
# -----------------------------------------------------------
robust_results <- list(
  boot_result = boot_result_final,
  boot_spec = boot_spec,
  ri_pval = ri_pval,
  obs_coef = obs_coef,
  loo_coefs = loo_coefs,
  ddd_sgf = ddd_sgf,
  ddd_onesided = ddd_onesided,
  ddd_log = ddd_log,
  ddd_geo = ddd_geo,
  ddd_conflict = if (exists("ddd_conflict")) ddd_conflict else NULL,
  ddd_pre2010 = ddd_pre2010,
  ddd_ppml = ddd_ppml,
  ddd_spillover = ddd_spillover,
  dd_nonpastoral = dd_nonpastoral,
  dd_np_es = if (exists("dd_np_es")) dd_np_es else NULL,
  np_es_df = if (exists("np_es_df")) np_es_df else NULL,
  ddd_total = if (exists("ddd_total")) ddd_total else NULL,
  ddd_es_df = if (exists("ddd_es_df")) ddd_es_df else NULL
)

saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))
cat("\nAll robustness checks complete.\n")
