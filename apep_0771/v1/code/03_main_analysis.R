# ==============================================================================
# 03_main_analysis.R — Primary Regressions
# Paper: When the Campus Goes Dark (apep_0771)
# ==============================================================================

source("00_packages.R")

qwi_panel <- readRDS("../data/qwi_panel.rds")
county_base <- readRDS("../data/county_panel_base.rds")

# ---- 1. Prepare annual panel for CS-DiD ----
# Aggregate quarterly to annual for cleaner event study
cat("Preparing annual panel for CS-DiD...\n")

annual_panel <- qwi_panel %>%
  group_by(county_fips, year, industry, n_closures, first_closure_year,
           total_peak_enrollment, has_chain, chain_closures) %>%
  summarise(
    emp = mean(emp, na.rm = TRUE),
    hir_a = sum(hir_a, na.rm = TRUE),
    sep = sum(sep, na.rm = TRUE),
    earn_s = mean(earn_s, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    log_emp = log(pmax(emp, 1)),
    log_hir = log(pmax(hir_a, 1)),
    log_sep = log(pmax(sep, 1)),
    log_earn = log(pmax(earn_s, 1))
  )

# ---- 2. Callaway-Sant'Anna Event Study ----
# Focus sectors: Education (61), Total Private (00)
sectors <- c("61", "62", "72", "00")
sector_names <- c("Education", "Health Care", "Accommodation/Food", "Total Private")

cs_results <- list()
es_results <- list()

for (i in seq_along(sectors)) {
  sec <- sectors[i]
  sec_name <- sector_names[i]
  cat(sprintf("\n--- CS-DiD for %s (NAICS %s) ---\n", sec_name, sec))

  df_sec <- annual_panel %>%
    filter(industry == sec) %>%
    mutate(
      id = county_fips,
      gname = ifelse(first_closure_year == 0, 0, first_closure_year)
    ) %>%
    filter(!is.na(log_emp), is.finite(log_emp))

  # Check minimum requirements
  n_treated <- sum(df_sec$gname > 0) / n_distinct(df_sec$year)
  n_pre <- sum(df_sec$year < 2013 & df_sec$gname > 0) / n_treated
  cat(sprintf("  Treated counties: %.0f, Pre-periods: %.0f\n", n_treated, n_pre))

  if (n_treated < 20) {
    cat("  SKIP: fewer than 20 treated units\n")
    next
  }

  # Run CS-DiD with proper data types
  tryCatch({
    df_cs <- as.data.frame(df_sec)
    df_cs$id <- as.integer(df_cs$id)
    df_cs$year <- as.integer(df_cs$year)
    df_cs$gname <- as.integer(df_cs$gname)
    df_cs$log_emp <- as.numeric(df_cs$log_emp)

    cs_out <- att_gt(
      yname = "log_emp",
      tname = "year",
      idname = "id",
      gname = "gname",
      data = df_cs,
      control_group = "notyettreated",
      base_period = "universal",
      est_method = "dr"
    )

    # Aggregate: overall ATT
    agg_overall <- aggte(cs_out, type = "simple")
    cat(sprintf("  Overall ATT: %.4f (SE: %.4f, p: %.4f)\n",
                agg_overall$overall.att, agg_overall$overall.se,
                2 * pnorm(-abs(agg_overall$overall.att / agg_overall$overall.se))))

    # Dynamic/event study
    es <- aggte(cs_out, type = "dynamic", min_e = -5, max_e = 5)

    cs_results[[sec]] <- list(
      att = agg_overall$overall.att,
      se = agg_overall$overall.se,
      cs_out = cs_out,
      sector_name = sec_name
    )
    es_results[[sec]] <- es

  }, error = function(e) {
    cat(sprintf("  ERROR in CS-DiD: %s\n", e$message))
    cat("  Using Sun-Abraham via fixest::sunab()...\n")

    # Sun-Abraham for binary treatment event study
    df_sec <- df_sec %>%
      mutate(cohort = ifelse(gname == 0, 10000L, as.integer(gname)))

    fit_sa <- feols(log_emp ~ sunab(cohort, year) | county_fips + year,
                    data = df_sec, cluster = ~county_fips)

    # Extract ATT
    att_val <- mean(coef(fit_sa)[grep("year::", names(coef(fit_sa)))], na.rm = TRUE)
    att_se <- mean(sqrt(diag(vcov(fit_sa)))[grep("year::", names(coef(fit_sa)))], na.rm = TRUE)

    cs_results[[sec]] <<- list(
      att = att_val,
      se = att_se,
      fit = fit_sa,
      sector_name = sec_name,
      method = "Sun-Abraham"
    )
  })
}

# ---- 3. TWFE with Continuous Treatment Intensity ----
cat("\n--- TWFE with Closure Count Intensity ---\n")

twfe_results <- list()

for (i in seq_along(sectors)) {
  sec <- sectors[i]
  sec_name <- sector_names[i]

  df_sec <- annual_panel %>%
    filter(industry == sec) %>%
    mutate(
      post = as.integer(year >= first_closure_year & first_closure_year > 0),
      treat_intensity = n_closures * post
    ) %>%
    filter(!is.na(log_emp), is.finite(log_emp))

  fit <- feols(log_emp ~ treat_intensity | county_fips + year,
               data = df_sec, cluster = ~county_fips)
  cat(sprintf("  %s: coef=%.5f, SE=%.5f, p=%.4f\n",
              sec_name, coef(fit)["treat_intensity"],
              sqrt(vcov(fit)["treat_intensity", "treat_intensity"]),
              fixest::pvalue(fit)["treat_intensity"]))

  twfe_results[[sec]] <- fit
}

# ---- 4. Chain IV ----
cat("\n--- Chain IV (ITT/Corinthian/ECA Exposure) ---\n")

iv_results <- list()

for (i in seq_along(sectors)) {
  sec <- sectors[i]
  sec_name <- sector_names[i]

  df_sec <- annual_panel %>%
    filter(industry == sec) %>%
    mutate(
      post = as.integer(year >= 2015),  # chain closures peak 2015-2016
      treat_intensity = n_closures * post,
      chain_iv = has_chain * post
    ) %>%
    filter(!is.na(log_emp), is.finite(log_emp))

  if (sum(df_sec$chain_iv > 0, na.rm = TRUE) < 50) {
    cat(sprintf("  %s: Too few chain-exposed obs, skipping IV\n", sec_name))
    next
  }

  fit_iv <- feols(log_emp ~ 1 | county_fips + year | treat_intensity ~ chain_iv,
                  data = df_sec, cluster = ~county_fips)
  cat(sprintf("  %s IV: coef=%.5f, SE=%.5f, F-stat: %.1f\n",
              sec_name, coef(fit_iv)["fit_treat_intensity"],
              sqrt(vcov(fit_iv)["fit_treat_intensity", "fit_treat_intensity"]),
              fitstat(fit_iv, "ivf")$ivf1$stat))

  iv_results[[sec]] <- fit_iv
}

# ---- 5. Hiring and Separations (mechanism) ----
cat("\n--- Hires and Separations (Education Sector) ---\n")

df_edu <- annual_panel %>%
  filter(industry == "61") %>%
  mutate(
    post = as.integer(year >= first_closure_year & first_closure_year > 0),
    treat_intensity = n_closures * post
  ) %>%
  filter(!is.na(log_hir), is.finite(log_hir),
         !is.na(log_sep), is.finite(log_sep))

fit_hires <- feols(log_hir ~ treat_intensity | county_fips + year,
                   data = df_edu, cluster = ~county_fips)
fit_seps  <- feols(log_sep ~ treat_intensity | county_fips + year,
                   data = df_edu, cluster = ~county_fips)
fit_earn  <- feols(log_earn ~ treat_intensity | county_fips + year,
                   data = df_edu, cluster = ~county_fips)

cat(sprintf("  Hires: %.5f (%.5f)\n", coef(fit_hires)[1], sqrt(vcov(fit_hires)[1,1])))
cat(sprintf("  Separations: %.5f (%.5f)\n", coef(fit_seps)[1], sqrt(vcov(fit_seps)[1,1])))
cat(sprintf("  Earnings: %.5f (%.5f)\n", coef(fit_earn)[1], sqrt(vcov(fit_earn)[1,1])))

# ---- 6. Save results ----
results <- list(
  cs_results = cs_results,
  es_results = es_results,
  twfe_results = twfe_results,
  iv_results = iv_results,
  mechanism = list(hires = fit_hires, seps = fit_seps, earnings = fit_earn)
)
saveRDS(results, "../data/main_results.rds")

# ---- 7. Write diagnostics.json ----
# Get sample counts from the total private sector analysis
df_total <- annual_panel %>%
  filter(industry == "00") %>%
  mutate(gname = ifelse(first_closure_year == 0, 0, first_closure_year))

diag <- list(
  n_treated = n_distinct(df_total$county_fips[df_total$first_closure_year > 0]),
  n_pre = length(unique(df_total$year[df_total$year < 2013])),
  n_obs = nrow(df_total)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

cat("\nMain analysis complete.\n")
