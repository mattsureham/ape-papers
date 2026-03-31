# 03_main_analysis.R — Main DiD analysis
source("code/00_packages.R")
library(fixest)
library(data.table)

df <- fread("data/analysis_panel.csv")
cat("=== Main Analysis ===\n")
cat(sprintf("Panel: %d obs, %d municipalities, %d treated\n",
            nrow(df), uniqueN(df$bfsnr), sum(df[year == min(year), ever_cut], na.rm = TRUE)))

# ============================================================
# 1. Summary statistics
# ============================================================
cat("\n--- Summary Statistics ---\n")

# Overall means
sum_stats <- df[, .(
  n = .N,
  mean_stf = mean(steuerfuss, na.rm = TRUE),
  sd_stf = sd(steuerfuss, na.rm = TRUE),
  mean_estab = mean(establishments, na.rm = TRUE),
  mean_emp = mean(employment, na.rm = TRUE),
  mean_epe = mean(emp_per_estab, na.rm = TRUE),
  sd_epe = sd(emp_per_estab, na.rm = TRUE),
  mean_epe_ter = mean(emp_per_estab_ter, na.rm = TRUE),
  sd_epe_ter = sd(emp_per_estab_ter, na.rm = TRUE),
  mean_ter_share = mean(tertiary_share, na.rm = TRUE),
  mean_pop = mean(population, na.rm = TRUE)
), by = ever_cut]

print(sum_stats)

# Pre-treatment SD of main outcomes for SDE
pre_df <- df[is.na(first_cut_year) | year < first_cut_year]
sd_epe <- sd(pre_df$emp_per_estab, na.rm = TRUE)
sd_log_epe <- sd(pre_df$log_emp_per_estab, na.rm = TRUE)
sd_epe_ter <- sd(pre_df$emp_per_estab_ter, na.rm = TRUE)
sd_log_epe_ter <- sd(pre_df$log_emp_per_estab_ter, na.rm = TRUE)
sd_ter_share <- sd(pre_df$tertiary_share, na.rm = TRUE)
sd_log_estab <- sd(pre_df$log_establishments, na.rm = TRUE)

cat(sprintf("\nPre-treatment SDs:\n"))
cat(sprintf("  emp_per_estab: %.3f\n", sd_epe))
cat(sprintf("  log_emp_per_estab: %.3f\n", sd_log_epe))
cat(sprintf("  emp_per_estab_ter: %.3f\n", sd_epe_ter))
cat(sprintf("  tertiary_share: %.3f\n", sd_ter_share))

# ============================================================
# 2. Main specification: TWFE DiD
# ============================================================
cat("\n--- Main TWFE Results ---\n")

# Treatment: post-cut indicator (1 for all years after first ≥5pp cut)
df[, post_cut := as.integer(!is.na(first_cut_year) & year >= first_cut_year)]

# (a) Employment per establishment — total
m1 <- feols(log_emp_per_estab ~ post_cut | bfsnr + year, data = df,
            cluster = ~canton)

# (b) Employment per establishment — tertiary sector only
m2 <- feols(log_emp_per_estab_ter ~ post_cut | bfsnr + year,
            data = df[!is.na(log_emp_per_estab_ter)],
            cluster = ~canton)

# (c) Tertiary establishment share
m3 <- feols(tertiary_share ~ post_cut | bfsnr + year,
            data = df[!is.na(tertiary_share)],
            cluster = ~canton)

# (d) Log establishments (extensive margin)
m4 <- feols(log_establishments ~ post_cut | bfsnr + year, data = df,
            cluster = ~canton)

# (e) Log employment
m5 <- feols(log_employment ~ post_cut | bfsnr + year, data = df,
            cluster = ~canton)

etable(m1, m2, m3, m4, m5,
       headers = c("Log(Emp/Est)", "Log(Emp/Est) Tertiary",
                   "Tertiary Share", "Log(Establishments)", "Log(Employment)"))

# ============================================================
# 3. Event study
# ============================================================
cat("\n--- Event Study ---\n")

# Restrict event time window
df[, event_time_c := fcase(
  is.na(event_time), NA_real_,
  event_time < -5, -5,
  event_time > 5, 5,
  default = as.double(event_time)
)]

# Event study: employment per establishment (cluster at municipality — only 2 cantons)
es1 <- feols(log_emp_per_estab ~ i(event_time_c, ref = -1) | bfsnr + year,
             data = df[ever_cut == 1 | is.na(ever_cut) | ever_cut == 0],
             cluster = ~bfsnr)

# Event study: tertiary emp per establishment
es2 <- feols(log_emp_per_estab_ter ~ i(event_time_c, ref = -1) | bfsnr + year,
             data = df[(ever_cut == 1 | is.na(ever_cut) | ever_cut == 0) &
                         !is.na(log_emp_per_estab_ter)],
             cluster = ~bfsnr)

cat("\nEvent study — Log(Emp/Estab):\n")
print(summary(es1))
cat("\nEvent study — Log(Emp/Estab) Tertiary:\n")
print(summary(es2))

# ============================================================
# 4. Continuous treatment: Steuerfuss level
# ============================================================
cat("\n--- Continuous Treatment (Steuerfuss Level) ---\n")

m_cont <- feols(log_emp_per_estab ~ steuerfuss | bfsnr + year, data = df,
                cluster = ~canton)
m_cont_ter <- feols(log_emp_per_estab_ter ~ steuerfuss | bfsnr + year,
                    data = df[!is.na(log_emp_per_estab_ter)],
                    cluster = ~canton)

etable(m_cont, m_cont_ter,
       headers = c("Log(Emp/Est)", "Log(Emp/Est) Tertiary"))

# ============================================================
# 5. Save results for tables
# ============================================================
cat("\n--- Saving results ---\n")

# Save key coefficients
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  m_cont = m_cont, m_cont_ter = m_cont_ter,
  es1 = es1, es2 = es2,
  sd_epe = sd_epe, sd_log_epe = sd_log_epe,
  sd_epe_ter = sd_epe_ter, sd_log_epe_ter = sd_log_epe_ter,
  sd_ter_share = sd_ter_share, sd_log_estab = sd_log_estab,
  n_treated = uniqueN(df[ever_cut == 1]$bfsnr),
  n_pre = uniqueN(df[ever_cut == 1 & year < first_cut_year]$year),
  n_obs = nrow(df)
)
saveRDS(results, "data/main_results.rds")

# Write diagnostics
jsonlite::write_json(list(
  n_treated = uniqueN(df[ever_cut == 1]$bfsnr),
  n_pre = max(5L, uniqueN(pre_df$year)),
  n_obs = nrow(df)
), "data/diagnostics.json", auto_unbox = TRUE)

cat("Results saved to data/main_results.rds\n")
cat("Diagnostics saved to data/diagnostics.json\n")
