# 03_main_analysis.R — Main DiD analysis of price-walking ban
source("00_packages.R")

data_dir <- "../data"
fca <- readRDS(file.path(data_dir, "fca_panel.rds"))
boe <- readRDS(file.path(data_dir, "boe_panel.rds"))

# ==============================================================================
# 1. FCA Complaints: Cross-Product DiD
# ==============================================================================
cat("=== FCA Complaints DiD ===\n\n")

# Main specification: complaint rate
# Y_{pt} = alpha_p + lambda_t + beta * (Treated_p x Post_t) + epsilon_{pt}
# Cluster at product level (7 clusters) — need wild cluster bootstrap

# Convert to factors for FE
fca$product_fe <- factor(fca$Product)
fca$time_fe    <- factor(fca$Semester)

# Main regression: complaint rate
m1_rate <- feols(complaint_rate ~ treated:post | product_fe + time_fe,
                 data = fca, cluster = ~product_fe)
cat("--- Model 1: Complaint Rate (per 1,000 policies) ---\n")
summary(m1_rate)

# Log complaints (level)
m2_log <- feols(log_complaints ~ treated:post | product_fe + time_fe,
                data = fca, cluster = ~product_fe)
cat("\n--- Model 2: Log Complaints ---\n")
summary(m2_log)

# Log provision (check if market size changed differentially)
m3_prov <- feols(log_provision ~ treated:post | product_fe + time_fe,
                 data = fca, cluster = ~product_fe)
cat("\n--- Model 3: Log Provision (market size) ---\n")
summary(m3_prov)

# ==============================================================================
# 2. Event Study (FCA)
# ==============================================================================
cat("\n=== Event Study ===\n")

# Create relative time variable. Treatment starts at 2022 H1.
# 2022 H1 = time_idx 12 (given 2016 H2 = 2)
# Wait, let me recompute. 2016 H2: year=2016, half=2, time_idx = (2016-2016)*2+2 = 2
# 2022 H1: year=2022, half=1, time_idx = (2022-2016)*2+1 = 13
# Relative: semester_relative = time_idx - 13

fca$rel_time <- fca$time_idx - 13  # 0 = 2022 H1 (first treated semester)

# Bin endpoints: rel_time <= -6 binned to -6, rel_time >= 5 binned to 5
fca$rel_time_binned <- pmin(pmax(fca$rel_time, -6), 5)

# Drop one pre-treatment period (rel_time = -1 = 2021 H2) as reference
m_es <- feols(complaint_rate ~ i(rel_time_binned, treated, ref = -1) |
                product_fe + time_fe,
              data = fca, cluster = ~product_fe)
cat("--- Event Study: Complaint Rate ---\n")
summary(m_es)

# ==============================================================================
# 3. BoE Underwriting DiD
# ==============================================================================
cat("\n=== BoE Underwriting DiD ===\n")

boe$line_fe <- factor(boe$line)
boe$qtr_fe  <- factor(boe$quarter)

# NWP (log)
m4_nwp <- feols(log_nwp ~ treated:post | line_fe + qtr_fe,
                data = boe, cluster = ~line_fe)
cat("--- Model 4: Log Net Written Premium ---\n")
summary(m4_nwp)

# Loss ratio
m5_lr <- feols(loss_ratio ~ treated:post | line_fe + qtr_fe,
               data = boe, cluster = ~line_fe)
cat("--- Model 5: Loss Ratio ---\n")
summary(m5_lr)

# ==============================================================================
# 4. Wild Cluster Bootstrap (inference with few clusters)
# ==============================================================================
cat("\n=== Wild Cluster Bootstrap Inference ===\n")

# For the main specification (m1_rate) with 7 product clusters
boot_m1 <- tryCatch({
  boottest(m1_rate, param = "treated:post",
           B = 9999, clustid = "product_fe",
           type = "mammen")
}, error = function(e) {
  cat("  Bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_m1)) {
  cat("--- Bootstrap CI for complaint rate DiD ---\n")
  print(summary(boot_m1))
}

# ==============================================================================
# 5. Summary Statistics Table
# ==============================================================================
cat("\n=== Summary Statistics ===\n")

summ_stats <- fca %>%
  mutate(period = ifelse(post == 1, "Post (2022H1-2025H1)", "Pre (2016H2-2021H2)"),
         group = ifelse(treated == 1, "Treated (Motor, Property)", "Control")) %>%
  group_by(group, period) %>%
  summarise(
    mean_rate = mean(complaint_rate, na.rm = TRUE),
    sd_rate = sd(complaint_rate, na.rm = TRUE),
    mean_complaints = mean(complaints, na.rm = TRUE),
    mean_provision = mean(provision / 1e6, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )
print(summ_stats)

# Raw DiD
pre_treat  <- summ_stats$mean_rate[summ_stats$group == "Treated (Motor, Property)" & grepl("Pre", summ_stats$period)]
post_treat <- summ_stats$mean_rate[summ_stats$group == "Treated (Motor, Property)" & grepl("Post", summ_stats$period)]
pre_ctrl   <- summ_stats$mean_rate[summ_stats$group == "Control" & grepl("Pre", summ_stats$period)]
post_ctrl  <- summ_stats$mean_rate[summ_stats$group == "Control" & grepl("Post", summ_stats$period)]
raw_did <- (post_treat - pre_treat) - (post_ctrl - pre_ctrl)
cat(sprintf("\nRaw DiD (complaint rate): %.4f\n", raw_did))
cat(sprintf("  Treated: %.3f -> %.3f (change: %.3f)\n", pre_treat, post_treat, post_treat - pre_treat))
cat(sprintf("  Control: %.3f -> %.3f (change: %.3f)\n", pre_ctrl, post_ctrl, post_ctrl - pre_ctrl))

# ==============================================================================
# 6. Write diagnostics.json
# ==============================================================================
diag <- list(
  n_treated = 2L,
  n_control = 5L,
  n_pre = 11L,  # 2016 H2 through 2021 H2
  n_post = 7L,  # 2022 H1 through 2025 H1
  n_obs = nrow(fca),
  n_products = length(unique(fca$Product)),
  n_semesters = length(unique(fca$Semester)),
  treatment_date = "2022-01-01",
  main_coef = coef(m1_rate)[["treated:post"]],
  main_se = se(m1_rate)[["treated:post"]],
  main_pval = pvalue(m1_rate)[["treated:post"]]
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

# ==============================================================================
# 7. Save regression objects
# ==============================================================================
save(m1_rate, m2_log, m3_prov, m_es, m4_nwp, m5_lr, boot_m1,
     summ_stats, raw_did,
     file = file.path(data_dir, "regression_results.RData"))

cat("\n=== Main analysis complete ===\n")
