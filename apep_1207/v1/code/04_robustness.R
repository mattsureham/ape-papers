# 04_robustness.R — Robustness checks and placebo tests
# apep_1207: Thailand Rice Pledging Scheme Collapse

source("00_packages.R")

cat("=== Robustness Checks ===\n")

# --- 1. Load data and results ---
scm_data <- read_csv("../data/scm_panel.csv", show_col_types = FALSE)
results <- readRDS("../data/main_results.rds")

# --- 2. Placebo-in-time test ---
# Move treatment to 2011 (before actual collapse) — should find no effect
cat("\n--- Placebo in time: treatment at 2011 ---\n")

scm_data_placebo_time <- scm_data %>% filter(year <= 2013)

placebo_time <- tryCatch({
  augsynth(
    cereal_index ~ treated,
    unit = iso2c,
    time = year,
    data = scm_data_placebo_time,
    t_int = 2011,
    progfunc = "Ridge",
    scm = TRUE
  )
}, error = function(e) {
  cat(sprintf("  Placebo-in-time error: %s\n", e$message))
  NULL
})

if (!is.null(placebo_time)) {
  cat("Placebo-in-time (2011) results:\n")
  print(summary(placebo_time))
}

# --- 3. Placebo-in-space: permutation inference ---
# Run SCM for each donor country as if it were treated
cat("\n--- Placebo in space: permutation tests ---\n")

donors <- unique(scm_data$iso2c[scm_data$iso2c != "TH"])
placebo_results <- list()

for (donor in donors) {
  cat(sprintf("  Running placebo for %s...\n", donor))

  placebo_data <- scm_data %>%
    mutate(treated = as.integer(iso2c == donor))

  placebo_fit <- tryCatch({
    augsynth(
      cereal_index ~ treated,
      unit = iso2c,
      time = year,
      data = placebo_data,
      t_int = 2014,
      progfunc = "Ridge",
      scm = TRUE
    )
  }, error = function(e) {
    cat(sprintf("    Error for %s: %s\n", donor, e$message))
    NULL
  })

  if (!is.null(placebo_fit)) {
    fit_summary <- summary(placebo_fit)
    placebo_results[[donor]] <- fit_summary$att
  }
}

# Compute RMSPE ratios
cat("\n--- RMSPE Ratios ---\n")

compute_rmspe <- function(att_df, t_int = 2014) {
  pre <- att_df %>% filter(Time < t_int)
  post <- att_df %>% filter(Time >= t_int)
  rmspe_pre <- sqrt(mean(pre$Estimate^2, na.rm = TRUE))
  rmspe_post <- sqrt(mean(post$Estimate^2, na.rm = TRUE))
  ratio <- ifelse(rmspe_pre > 0, rmspe_post / rmspe_pre, NA)
  list(pre = rmspe_pre, post = rmspe_post, ratio = ratio)
}

# Thailand RMSPE
th_att <- summary(results$scm_cereal)$att
th_rmspe <- compute_rmspe(th_att)
cat(sprintf("Thailand RMSPE ratio: %.2f (pre: %.2f, post: %.2f)\n",
            th_rmspe$ratio, th_rmspe$pre, th_rmspe$post))

# Donor RMSPE ratios
rmspe_ratios <- tibble(
  country = character(),
  rmspe_pre = numeric(),
  rmspe_post = numeric(),
  ratio = numeric()
)

for (donor in names(placebo_results)) {
  d_rmspe <- compute_rmspe(placebo_results[[donor]])
  rmspe_ratios <- bind_rows(rmspe_ratios, tibble(
    country = donor,
    rmspe_pre = d_rmspe$pre,
    rmspe_post = d_rmspe$post,
    ratio = d_rmspe$ratio
  ))
}

# Add Thailand
rmspe_ratios <- bind_rows(
  tibble(country = "TH", rmspe_pre = th_rmspe$pre,
         rmspe_post = th_rmspe$post, ratio = th_rmspe$ratio),
  rmspe_ratios
) %>%
  arrange(desc(ratio))

cat("\nRMSPE ratio ranking:\n")
print(as.data.frame(rmspe_ratios))

# Permutation p-value: fraction of donors with RMSPE ratio >= Thailand's
th_rank <- which(rmspe_ratios$country == "TH")
perm_pvalue <- th_rank / nrow(rmspe_ratios)
cat(sprintf("\nPermutation p-value: %.3f (Thailand rank: %d of %d)\n",
            perm_pvalue, th_rank, nrow(rmspe_ratios)))

# --- 4. Leave-one-out: drop each donor and re-estimate ---
cat("\n--- Leave-one-out robustness ---\n")

loo_results <- list()

for (drop_donor in donors) {
  loo_data <- scm_data %>% filter(iso2c != drop_donor)

  loo_fit <- tryCatch({
    augsynth(
      cereal_index ~ treated,
      unit = iso2c,
      time = year,
      data = loo_data,
      t_int = 2014,
      progfunc = "Ridge",
      scm = TRUE
    )
  }, error = function(e) NULL)

  if (!is.null(loo_fit)) {
    loo_summary <- summary(loo_fit)
    avg_att <- mean(loo_summary$att$Estimate[loo_summary$att$Time >= 2014], na.rm = TRUE)
    loo_results[[drop_donor]] <- avg_att
    cat(sprintf("  Drop %s: avg post-ATT = %.2f\n", drop_donor, avg_att))
  }
}

# --- 5. Alternative donor pool: ASEAN only ---
cat("\n--- Alternative donor pool: ASEAN only ---\n")

asean_only <- c("TH", "VN", "ID", "PH", "MM", "KH", "MY", "LA")
scm_asean <- scm_data %>% filter(iso2c %in% asean_only)

scm_asean_fit <- tryCatch({
  augsynth(
    cereal_index ~ treated,
    unit = iso2c,
    time = year,
    data = scm_asean,
    t_int = 2014,
    progfunc = "Ridge",
    scm = TRUE
  )
}, error = function(e) {
  cat(sprintf("  ASEAN-only SCM error: %s\n", e$message))
  NULL
})

if (!is.null(scm_asean_fit)) {
  cat("ASEAN-only SCM results:\n")
  print(summary(scm_asean_fit))
}

# --- 6. Controlling for world rice price ---
cat("\n--- Rice price control ---\n")

did_rice_control <- feols(
  cereal_index ~ treat_x_post + rice_price_usd | iso2c + year,
  data = scm_data %>%
    mutate(treat_x_post = as.integer(iso2c == "TH") * as.integer(year >= 2014)),
  cluster = ~iso2c
)

cat("DiD with rice price control:\n")
print(summary(did_rice_control))

# --- 7. Save robustness results ---
rob_results <- list(
  placebo_time = placebo_time,
  placebo_results = placebo_results,
  rmspe_ratios = rmspe_ratios,
  perm_pvalue = perm_pvalue,
  loo_results = loo_results,
  scm_asean_fit = scm_asean_fit,
  did_rice_control = did_rice_control
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness complete ===\n")
cat(sprintf("  Permutation p-value: %.3f\n", perm_pvalue))
cat(sprintf("  Leave-one-out ATT range: [%.2f, %.2f]\n",
            min(unlist(loo_results)), max(unlist(loo_results))))
