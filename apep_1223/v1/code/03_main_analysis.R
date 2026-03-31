## 03_main_analysis.R — apep_1223: The Choice Tax
## Main analysis: pot-size gradient in access method, advice gap, welfare loss

source("00_packages.R")
# Uses: fixest (feols), data.table (fread/fwrite), jsonlite (write_json)

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
advice <- fread(file.path(data_dir, "advice_clean.csv"))

pot_order <- c("<10K", "10-29K", "30-49K", "50-99K", "100-249K", "250K+")

# ============================================================
# ANALYSIS 1: Pot-Size Gradient in Full Encashment
# ============================================================
cat("=== Analysis 1: Pot-Size Gradient ===\n")

# OLS: Full encashment share on log(pot size)
panel[, pot_factor := factor(pot_size, levels = pot_order)]

# Main specification: share_fullwd ~ log_pot + period FE
m1 <- feols(share_fullwd ~ log_pot | period, data = panel, cluster = ~period)
cat("\nModel 1: share_fullwd ~ log_pot | period FE\n")
summary(m1)

# With time trend interaction
m2 <- feols(share_fullwd ~ log_pot + log_pot:time | period, data = panel, cluster = ~period)
cat("\nModel 2: With time interaction\n")
summary(m2)

# Annuity share (mirror analysis)
m3 <- feols(share_annuity ~ log_pot | period, data = panel, cluster = ~period)
cat("\nModel 3: share_annuity ~ log_pot | period FE\n")
summary(m3)

# Drawdown share
m4 <- feols(share_drawdown ~ log_pot | period, data = panel, cluster = ~period)
cat("\nModel 4: share_drawdown ~ log_pot | period FE\n")
summary(m4)

# ============================================================
# ANALYSIS 2: Persistence — Time Trends by Pot Size
# ============================================================
cat("\n=== Analysis 2: Persistence ===\n")

# Test whether the pot-size gradient changes over time
m5 <- feols(share_fullwd ~ pot_factor * time, data = panel, cluster = ~period)
cat("\nModel 5: share_fullwd ~ pot_factor × time\n")
summary(m5)

# ============================================================
# ANALYSIS 3: Advice Gap — Mechanism
# ============================================================
cat("\n=== Analysis 3: Advice Gap ===\n")

# Advice rate on log(pot size) — 2018-24 only
m6 <- feols(advice_rate ~ log_pot | period, data = advice, cluster = ~period)
cat("\nModel 6: advice_rate ~ log_pot | period FE\n")
summary(m6)

# Any help rate (advice + Pension Wise)
m7 <- feols(any_help_rate ~ log_pot | period, data = advice, cluster = ~period)
cat("\nModel 7: any_help_rate ~ log_pot | period FE\n")
summary(m7)

# ============================================================
# ANALYSIS 4: Welfare Loss from Dominated Strategies
# ============================================================
cat("\n=== Analysis 4: Welfare Loss ===\n")

# Compute welfare loss from full encashment
# Key insight: Full encashment triggers income tax on the ENTIRE pot immediately,
# while drawdown allows phased withdrawal over multiple tax years.
#
# Tax wedge: Full encashment of a £20K pot by a basic-rate taxpayer in one year:
#   25% is tax-free (£5K), remaining £15K taxed at 20% = £3K tax
#   Net: £17K
#
# Drawdown of same £20K pot over 10 years:
#   Each year: £2K (25% tax-free = £500, remaining £1,500 at 20% = £300 tax)
#   Total tax over 10 years: £3K (same if within basic rate)
#   BUT: many drawdown payments fall within personal allowance
#   AND: pot continues to earn investment returns
#
# Simplified welfare loss = investment return forgone + tax penalty from bunching
#
# Use FCA's reported pot-size midpoints and a 5% annual return assumption

# Average pot values by band (GBP)
pot_mids <- c(5000, 19500, 39500, 74500, 174500, 375000)
names(pot_mids) <- pot_order

# Parameters
r <- 0.05          # Annual real return
horizon <- 10      # Years of drawdown
tax_basic <- 0.20  # Basic rate
tax_free_frac <- 0.25  # PCLS tax-free fraction

# Opportunity cost: present value of investment returns forgone
# Under drawdown, the pot earns returns. Under encashment, it's gone.
# PV of returns on average remaining balance under phased drawdown:
# Assumes 1/horizon withdrawn each year
pv_returns <- function(pot, r, T) {
  annual_wd <- pot / T
  returns <- 0
  balance <- pot
  for (t in 1:T) {
    returns <- returns + balance * r / (1 + r)^t
    balance <- balance - annual_wd
  }
  returns
}

# Tax penalty: encashing the full pot in one year may push income into higher tax bands
# Simplification: basic-rate taxpayer, personal allowance = £12,570
PA <- 12570
HR_threshold <- 50270  # Higher rate starts

tax_on_encash <- function(pot) {
  tax_free <- pot * tax_free_frac
  taxable <- pot - tax_free
  # Assume no other income for simplicity (retired)
  if (taxable <= PA) return(0)
  basic <- min(taxable - PA, HR_threshold - PA) * tax_basic
  higher <- max(0, taxable - HR_threshold) * 0.40
  basic + higher
}

tax_on_drawdown <- function(pot, T) {
  annual_pot <- pot / T
  tax_free <- annual_pot * tax_free_frac
  taxable <- annual_pot - tax_free
  annual_tax <- max(0, taxable - PA) * tax_basic  # Usually within PA
  annual_tax * T
}

# Compute welfare loss per pot-size band
welfare <- data.table(
  pot_size = pot_order,
  pot_mid = pot_mids,
  pot_idx = 1:6
)

welfare[, return_forgone := sapply(pot_mid, pv_returns, r = r, T = horizon)]
welfare[, tax_encash := sapply(pot_mid, tax_on_encash)]
welfare[, tax_drawdown := sapply(pot_mid, tax_on_drawdown, T = horizon)]
welfare[, tax_penalty := tax_encash - tax_drawdown]
welfare[, total_loss := return_forgone + tax_penalty]
welfare[, loss_pct := total_loss / pot_mid * 100]

# Merge with encashment counts to get aggregate loss
panel_totals <- panel[, .(total_encash = sum(full_withdrawal, na.rm = TRUE)), by = pot_size]
panel_totals[, pot_idx := match(pot_size, pot_order)]
welfare <- merge(welfare, panel_totals, by = c("pot_size", "pot_idx"))
welfare[, aggregate_loss := total_encash * total_loss]

cat("\nWelfare loss by pot size:\n")
print(welfare[, .(pot_size, pot_mid, return_forgone = round(return_forgone),
                  tax_penalty = round(tax_penalty), total_loss = round(total_loss),
                  loss_pct = round(loss_pct, 1), total_encash,
                  agg_loss_M = round(aggregate_loss / 1e6, 1))])

total_agg_loss <- sum(welfare$aggregate_loss, na.rm = TRUE)
cat(sprintf("\nTotal aggregate welfare loss: £%.1f billion\n", total_agg_loss / 1e9))

# ============================================================
# Save all model results and key statistics
# ============================================================

# Diagnostics for validation
diag <- list(
  n_treated = nrow(panel),  # 102 pot-size × period cells
  n_pre = 5L,               # 5 periods in 2015-18
  n_obs = as.integer(sum(panel$total, na.rm = TRUE)),  # 5.5M pots
  n_pots_total = sum(panel$total, na.rm = TRUE),
  n_periods = uniqueN(panel$period),
  total_welfare_loss_gbp = total_agg_loss
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

# Save welfare table
fwrite(welfare, file.path(data_dir, "welfare_results.csv"))

# Save model objects for table generation
save(m1, m2, m3, m4, m5, m6, m7, welfare,
     file = file.path(data_dir, "models.RData"))

cat("\nMain analysis complete.\n")
