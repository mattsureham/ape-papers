# 04_robustness.R — Robustness checks for apep_1319
# Placebo outcomes, leave-one-out, permutation inference

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

# Load main results
main <- readRDS(file.path(data_dir, "main_results.rds"))
df <- main$df
pre_sd <- main$pre_sd

cat("Panel loaded:", nrow(df), "obs\n")

# ============================================================================
# TABLE 4: Robustness Checks
# ============================================================================

cat("\n=== Robustness Checks ===\n")

# --- 4a. Placebo: Burglary rate (should not respond to ASB toolkit change) ---
m_placebo <- feols(burglary_rate ~ post_asbo_std | cjs_area + year_month,
                   data = df[!is.na(burglary_rate)], cluster = ~cjs_area)
cat("Placebo (burglary):\n")
summary(m_placebo)

# --- 4b. Leave-one-out: Drop Greater Manchester (highest ASBO count) ---
m_loo_gm <- feols(asb_rate ~ post_asbo_std | cjs_area + year_month,
                  data = df[cjs_area != "Greater Manchester"], cluster = ~cjs_area)

# --- 4c. Leave-one-out: Drop London (largest force) ---
m_loo_ldn <- feols(asb_rate ~ post_asbo_std | cjs_area + year_month,
                   data = df[cjs_area != "London"], cluster = ~cjs_area)

# --- 4d. Drop Welsh forces (different legal tradition) ---
welsh <- c("Dyfed-Powys", "Gwent", "North Wales", "South Wales")
m_eng_only <- feols(asb_rate ~ post_asbo_std | cjs_area + year_month,
                    data = df[!cjs_area %in% welsh], cluster = ~cjs_area)

# --- 4e. Alternative treatment: top quartile binary ---
q75 <- quantile(df[, first(asbo_rate_pc), by = cjs_area]$V1, 0.75)
df[, high_asbo := as.integer(asbo_rate_pc >= q75)]
df[, post_high := post * high_asbo]
m_binary <- feols(asb_rate ~ post_high | cjs_area + year_month,
                  data = df, cluster = ~cjs_area)

# --- 4f. Shorter post-period: 2 years only ---
m_short <- feols(asb_rate ~ post_asbo_std | cjs_area + year_month,
                 data = df[year_month <= as.Date("2016-10-01")],
                 cluster = ~cjs_area)

# --- 4g. Permutation inference (Fisher exact test) ---
cat("\nRunning permutation inference (1000 permutations)...\n")
set.seed(42)
n_perms <- 1000

# Actual test statistic
actual_t <- coef(main$m1)["post_asbo_std"] / sqrt(vcov(main$m1)["post_asbo_std", "post_asbo_std"])

# Permute treatment intensity across forces
force_intensities <- df[, .(asbo_rate_std = first(asbo_rate_std)), by = cjs_area]
perm_stats <- numeric(n_perms)

for (p in seq_len(n_perms)) {
  # Shuffle ASBO rates across forces
  shuffled <- force_intensities[sample(.N)]
  perm_map <- data.table(
    cjs_area = force_intensities$cjs_area,
    perm_asbo_std = shuffled$asbo_rate_std
  )

  df_perm <- merge(df, perm_map, by = "cjs_area")
  df_perm[, perm_post_asbo := post * perm_asbo_std]

  m_perm <- tryCatch(
    feols(asb_rate ~ perm_post_asbo | cjs_area + year_month,
          data = df_perm, cluster = ~cjs_area),
    error = function(e) NULL
  )

  if (!is.null(m_perm)) {
    perm_stats[p] <- coef(m_perm)["perm_post_asbo"] /
      sqrt(vcov(m_perm)["perm_post_asbo", "perm_post_asbo"])
  } else {
    perm_stats[p] <- NA
  }

  if (p %% 200 == 0) cat(sprintf("  Permutation %d/%d\n", p, n_perms))
}

ri_pvalue <- mean(abs(perm_stats) >= abs(actual_t), na.rm = TRUE)
cat(sprintf("Permutation inference p-value: %.3f (actual t = %.2f)\n", ri_pvalue, actual_t))

# ============================================================================
# Write Table 4
# ============================================================================

extract_row <- function(model, var_name, label) {
  b <- coef(model)[var_name]
  s <- sqrt(vcov(model)[var_name, var_name])
  p <- 2 * pnorm(-abs(b/s))
  stars_fn <- function(p) {
    if (p < 0.01) return("^{***}")
    if (p < 0.05) return("^{**}")
    if (p < 0.10) return("^{*}")
    return("")
  }
  list(label = label, coef = b, se = s, p = p, stars = stars_fn(p),
       n = nobs(model), forces = length(unique(model$fixef_sizes)))
}

sink(file.path(tables_dir, "tab4_robustness.tex"))
cat("\\begin{table}[htbp]\n")
cat("\\centering\n")
cat("\\caption{Robustness Checks}\n")
cat("\\label{tab:robustness}\n")
cat("\\begin{tabular}{lccccc}\n")
cat("\\hline\\hline\n")
cat(" & Coefficient & SE & $p$-value & Forces & $N$ \\\\\n")
cat("\\hline\n")
cat("\\multicolumn{6}{l}{\\textit{Panel A: Baseline}} \\\\\n")

b1 <- coef(main$m1)["post_asbo_std"]; s1 <- sqrt(vcov(main$m1)["post_asbo_std", "post_asbo_std"])
p1 <- 2*pnorm(-abs(b1/s1))
cat(sprintf("Baseline (Table 2, col 1) & %.3f & (%.3f) & %.3f & %d & %s \\\\\n",
            b1, s1, p1, uniqueN(df$cjs_area), format(nobs(main$m1), big.mark = ",")))

cat("\\hline\n")
cat("\\multicolumn{6}{l}{\\textit{Panel B: Placebo Outcome}} \\\\\n")
bp <- coef(m_placebo)["post_asbo_std"]; sp <- sqrt(vcov(m_placebo)["post_asbo_std", "post_asbo_std"])
pp <- 2*pnorm(-abs(bp/sp))
cat(sprintf("Burglary rate & %.3f & (%.3f) & %.3f & %d & %s \\\\\n",
            bp, sp, pp, uniqueN(df[!is.na(burglary_rate)]$cjs_area),
            format(nobs(m_placebo), big.mark = ",")))

cat("\\hline\n")
cat("\\multicolumn{6}{l}{\\textit{Panel C: Sample Restrictions}} \\\\\n")

bgm <- coef(m_loo_gm)["post_asbo_std"]; sgm <- sqrt(vcov(m_loo_gm)["post_asbo_std", "post_asbo_std"])
pgm <- 2*pnorm(-abs(bgm/sgm))
cat(sprintf("Drop Greater Manchester & %.3f & (%.3f) & %.3f & %d & %s \\\\\n",
            bgm, sgm, pgm, uniqueN(df[cjs_area != "Greater Manchester"]$cjs_area),
            format(nobs(m_loo_gm), big.mark = ",")))

bld <- coef(m_loo_ldn)["post_asbo_std"]; sld <- sqrt(vcov(m_loo_ldn)["post_asbo_std", "post_asbo_std"])
pld <- 2*pnorm(-abs(bld/sld))
cat(sprintf("Drop London & %.3f & (%.3f) & %.3f & %d & %s \\\\\n",
            bld, sld, pld, uniqueN(df[cjs_area != "London"]$cjs_area),
            format(nobs(m_loo_ldn), big.mark = ",")))

beng <- coef(m_eng_only)["post_asbo_std"]; seng <- sqrt(vcov(m_eng_only)["post_asbo_std", "post_asbo_std"])
peng <- 2*pnorm(-abs(beng/seng))
cat(sprintf("England only (drop Wales) & %.3f & (%.3f) & %.3f & %d & %s \\\\\n",
            beng, seng, peng, uniqueN(df[!cjs_area %in% welsh]$cjs_area),
            format(nobs(m_eng_only), big.mark = ",")))

bshort <- coef(m_short)["post_asbo_std"]; sshort <- sqrt(vcov(m_short)["post_asbo_std", "post_asbo_std"])
pshort <- 2*pnorm(-abs(bshort/sshort))
cat(sprintf("Short post-period (2 years) & %.3f & (%.3f) & %.3f & %d & %s \\\\\n",
            bshort, sshort, pshort, uniqueN(df[year_month <= as.Date("2016-10-01")]$cjs_area),
            format(nobs(m_short), big.mark = ",")))

cat("\\hline\n")
cat("\\multicolumn{6}{l}{\\textit{Panel D: Alternative Treatment}} \\\\\n")
bbin <- coef(m_binary)["post_high"]; sbin <- sqrt(vcov(m_binary)["post_high", "post_high"])
pbin <- 2*pnorm(-abs(bbin/sbin))
cat(sprintf("Binary (top quartile ASBO) & %.3f & (%.3f) & %.3f & %d & %s \\\\\n",
            bbin, sbin, pbin, uniqueN(df$cjs_area), format(nobs(m_binary), big.mark = ",")))

cat("\\hline\n")
cat("\\multicolumn{6}{l}{\\textit{Panel E: Inference}} \\\\\n")
cat(sprintf("Permutation $p$-value (1,000 draws) & \\multicolumn{5}{c}{%.3f} \\\\\n", ri_pvalue))
cat("\\hline\\hline\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}\n")
cat("\\item \\textit{Notes:} All regressions include force area and year-month fixed effects. ")
cat("Standard errors clustered by police force area. The baseline is the specification from ")
cat("Table \\ref{tab:main}, column (1). Panel B uses burglary rate as a placebo outcome ")
cat("(the ASB toolkit consolidation should not directly affect burglary enforcement). ")
cat("Panel C tests sensitivity to influential observations and sample composition. ")
cat("Panel D replaces continuous treatment with a binary indicator for top-quartile ")
cat("pre-reform ASBO issuance. Panel E reports a Fisher exact permutation $p$-value from ")
cat("1,000 random reassignments of ASBO rates across force areas. ")
cat("$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.\n")
cat("\\end{tablenotes}\n")
cat("\\end{table}\n")
sink()

cat("Table 4 saved.\n")

# Save robustness results
saveRDS(list(
  m_placebo = m_placebo, m_loo_gm = m_loo_gm, m_loo_ldn = m_loo_ldn,
  m_eng_only = m_eng_only, m_binary = m_binary, m_short = m_short,
  ri_pvalue = ri_pvalue, actual_t = actual_t, perm_stats = perm_stats
), file.path(data_dir, "robustness_results.rds"))

cat("Robustness analysis complete.\n")
