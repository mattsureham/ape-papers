# 04_robustness.R — Robustness checks and heterogeneity
# Paper: Mandated to Stay (apep_1271)

source("00_packages.R")

food <- fread("../data/panel_food.csv")
retail <- fread("../data/panel_retail.csv")
age_panel <- fread("../data/panel_age.csv")
att_table <- fread("../data/att_table.csv")

# ---- 1. Never-treated only as control group ----
cat("=== ROBUSTNESS 1: Never-treated only controls ===\n")

outcomes <- c("sep_rate", "hirn_rate", "hirr_rate", "stability")
labels <- c("Separation Rate", "New Hire Rate", "Recall Rate", "Stable Employment Share")

nt_results <- list()
for (i in seq_along(outcomes)) {
  d <- food[!is.na(get(outcomes[i]))]
  cs <- att_gt(
    yname = outcomes[i],
    tname = "quarter_num",
    idname = "county_fips",
    gname = "treatment_quarter",
    data = d,
    control_group = "nevertreated",
    clustervars = "state_fips",
    base_period = "universal",
    anticipation = 0
  )
  agg <- aggte(cs, type = "simple")
  nt_results[[outcomes[i]]] <- list(att = agg$overall.att, se = agg$overall.se)
  cat(sprintf("  %s: ATT = %.5f (SE = %.5f)\n", labels[i], agg$overall.att, agg$overall.se))
}

# ---- 2. Retail sector (NAICS 44-45) as placebo ----
cat("\n=== ROBUSTNESS 2: Retail sector placebo ===\n")

# Retail already has treatment_quarter from 02_clean_data.R
# Just compute rates if needed
if (!"sep_rate" %in% names(retail)) {
  retail[Emp > 0, `:=`(
    sep_rate  = Sep / Emp,
    hirn_rate = HirN / Emp
  )]
}

retail_results <- list()
for (out in c("sep_rate", "hirn_rate")) {
  d <- retail[!is.na(get(out))]
  cs <- att_gt(
    yname = out,
    tname = "quarter_num",
    idname = "county_fips",
    gname = "treatment_quarter",
    data = d,
    control_group = "notyettreated",
    clustervars = "state_fips",
    base_period = "universal",
    anticipation = 0
  )
  agg <- aggte(cs, type = "simple")
  retail_results[[out]] <- list(att = agg$overall.att, se = agg$overall.se)
  cat(sprintf("  Retail %s: ATT = %.5f (SE = %.5f)\n", out, agg$overall.att, agg$overall.se))
}

# ---- 3. Exclude CT (different mandate structure) ----
cat("\n=== ROBUSTNESS 3: Exclude Connecticut ===\n")

food_no_ct <- food[state_fips != 9L]
ct_results <- list()
for (i in seq_along(outcomes)) {
  d <- food_no_ct[!is.na(get(outcomes[i]))]
  cs <- att_gt(
    yname = outcomes[i],
    tname = "quarter_num",
    idname = "county_fips",
    gname = "treatment_quarter",
    data = d,
    control_group = "notyettreated",
    clustervars = "state_fips",
    base_period = "universal",
    anticipation = 0
  )
  agg <- aggte(cs, type = "simple")
  ct_results[[outcomes[i]]] <- list(att = agg$overall.att, se = agg$overall.se)
  cat(sprintf("  %s: ATT = %.5f (SE = %.5f)\n", labels[i], agg$overall.att, agg$overall.se))
}

# ---- 4. Age heterogeneity: Young vs Prime-age ----
cat("\n=== ROBUSTNESS 4: Age heterogeneity ===\n")

age_results <- list()
for (ag in c("young_19_24", "prime_25_54")) {
  cat(sprintf("\n  Age group: %s\n", ag))
  d <- age_panel[age_group == ag & !is.na(sep_rate) & Emp >= 20]
  for (i in seq_along(outcomes)) {
    if (!outcomes[i] %in% names(d)) next
    dd <- d[!is.na(get(outcomes[i]))]
    cs <- att_gt(
      yname = outcomes[i],
      tname = "quarter_num",
      idname = "county_fips",
      gname = "treatment_quarter",
      data = dd,
      control_group = "notyettreated",
      clustervars = "state_fips",
      base_period = "universal",
      anticipation = 0
    )
    agg <- aggte(cs, type = "simple")
    age_results[[paste0(ag, "_", outcomes[i])]] <- list(att = agg$overall.att, se = agg$overall.se)
    cat(sprintf("    %s: ATT = %.5f (SE = %.5f)\n", labels[i], agg$overall.att, agg$overall.se))
  }
}

# ---- 5. Wild cluster bootstrap for main results ----
cat("\n=== ROBUSTNESS 5: Wild cluster bootstrap (main outcomes) ===\n")

# Use fixest TWFE as base for wild bootstrap (since fwildclusterboot works with fixest)
# This gives TWFE estimates with wild bootstrap p-values
boot_results <- list()
for (i in seq_along(outcomes)) {
  d <- food[!is.na(get(outcomes[i]))]
  d[, post := as.integer(treatment_quarter > 0 & quarter_num >= treatment_quarter)]

  fm <- feols(as.formula(paste0(outcomes[i], " ~ post | county_fips + quarter_num")),
              data = d, cluster = ~state_fips)

  boot <- tryCatch({
    boottest(fm, param = "post", B = 9999, clustid = ~state_fips,
             type = "webb", impose_null = TRUE)
  }, error = function(e) {
    cat(sprintf("    Bootstrap failed for %s: %s\n", outcomes[i], e$message))
    NULL
  })

  if (!is.null(boot)) {
    boot_results[[outcomes[i]]] <- list(
      p_boot = boot$p_val,
      ci_lo = boot$conf_int[1],
      ci_hi = boot$conf_int[2]
    )
    cat(sprintf("  %s: p_boot = %.4f, 95%% CI = [%.5f, %.5f]\n",
                labels[i], boot$p_val, boot$conf_int[1], boot$conf_int[2]))
  }
}

# ---- Collect all robustness results ----
robustness <- list(
  never_treated = nt_results,
  retail_placebo = retail_results,
  exclude_ct = ct_results,
  age_heterogeneity = age_results,
  wild_bootstrap = boot_results
)

saveRDS(robustness, "../data/robustness_results.rds")

cat("\n04_robustness.R completed successfully.\n")
