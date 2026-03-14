# =============================================================================
# 03b_stacked_ddd.R — Stacked DDD: pool 1910-1920 + 1920-1930 panels
# =============================================================================

source("00_packages.R")

main <- fread("../data/analysis_main.csv")
placebo <- fread("../data/analysis_placebo.csv")

# ─────────────────────────────────────────────────────────────────────────────
# Construct stacked panel
# ─────────────────────────────────────────────────────────────────────────────

# Standardize column names for stacking
main_stack <- main[, .(
  histid, d_occscore, upgraded, downgraded,
  age = age_1920, white, literate,
  statefip = statefip_1920,
  occ1950 = occ1950_1920,
  county_id,
  restricted_share,
  skill_group,
  post_quota = 1L
)]

placebo_stack <- placebo[, .(
  histid, d_occscore, upgraded, downgraded,
  age = age_1910, white, literate,
  statefip = statefip_1920,
  occ1950 = occ1950_1910,
  county_id,
  restricted_share,
  skill_group,
  post_quota = 0L
)]

stacked <- rbindlist(list(placebo_stack, main_stack))
cat(sprintf("Stacked panel: %s obs (%s pre-quota, %s post-quota)\n",
            format(nrow(stacked), big.mark=","),
            format(sum(stacked$post_quota == 0), big.mark=","),
            format(sum(stacked$post_quota == 1), big.mark=",")))

# ─────────────────────────────────────────────────────────────────────────────
# Main DDD: exposure × post_quota
# ─────────────────────────────────────────────────────────────────────────────

# DDD with state + occ FE
m_ddd <- feols(d_occscore ~ restricted_share * post_quota + age + I(age^2) + white + literate | statefip + occ1950,
               data = stacked, cluster = ~county_id)

cat("\n=== STACKED DDD: MAIN ===\n")
summary(m_ddd)

# DDD for upgrading
m_ddd_up <- feols(upgraded ~ restricted_share * post_quota + age + I(age^2) + white + literate | statefip + occ1950,
                  data = stacked, cluster = ~county_id)

# DDD for downgrading
m_ddd_down <- feols(downgraded ~ restricted_share * post_quota + age + I(age^2) + white + literate | statefip + occ1950,
                    data = stacked, cluster = ~county_id)

cat("\n=== STACKED DDD: BINARY OUTCOMES ===\n")
etable(m_ddd, m_ddd_up, m_ddd_down)

# ─────────────────────────────────────────────────────────────────────────────
# DDD by skill group
# ─────────────────────────────────────────────────────────────────────────────

m_ddd_low <- feols(d_occscore ~ restricted_share * post_quota + age + I(age^2) + white + literate | statefip + occ1950,
                   data = stacked[skill_group == "low_skill"], cluster = ~county_id)

m_ddd_mid <- feols(d_occscore ~ restricted_share * post_quota + age + I(age^2) + white + literate | statefip + occ1950,
                   data = stacked[skill_group == "mid_skill"], cluster = ~county_id)

m_ddd_high <- feols(d_occscore ~ restricted_share * post_quota + age + I(age^2) + white + literate | statefip + occ1950,
                    data = stacked[skill_group == "high_skill"], cluster = ~county_id)

cat("\n=== STACKED DDD BY SKILL ===\n")
etable(m_ddd_low, m_ddd_mid, m_ddd_high)

# ─────────────────────────────────────────────────────────────────────────────
# Generate DDD table
# ─────────────────────────────────────────────────────────────────────────────

stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", "")))

# Table: DDD main + by skill
ddd_models <- list(m_ddd, m_ddd_up, m_ddd_down, m_ddd_low, m_ddd_mid, m_ddd_high)

# Extract interaction term
get_int <- function(m) {
  nm <- grep("restricted_share:post_quota", names(coef(m)), value = TRUE)
  if (length(nm) == 0) nm <- grep("post_quota:restricted_share", names(coef(m)), value = TRUE)
  return(nm[1])
}

int_names <- sapply(ddd_models, get_int)
int_betas <- mapply(function(m, n) coef(m)[n], ddd_models, int_names)
int_ses <- mapply(function(m, n) se(m)[n], ddd_models, int_names)
int_pvals <- mapply(function(m, n) pvalue(m)[n], ddd_models, int_names)

# Extract exposure level
exp_names <- sapply(ddd_models, function(m) "restricted_share")
exp_betas <- sapply(ddd_models, function(m) coef(m)["restricted_share"])
exp_ses <- sapply(ddd_models, function(m) se(m)["restricted_share"])
exp_pvals <- sapply(ddd_models, function(m) pvalue(m)["restricted_share"])

ddd_ns <- sapply(ddd_models, function(m) m$nobs)

sink("../tables/tab2b_ddd.tex")
cat("\\begin{table}[H]\n\\centering\n")
cat("\\caption{Stacked Difference-in-Differences: Effect of 1924 Quota on Native Occupational Change}\n")
cat("\\begin{threeparttable}\n\\begin{adjustbox}{max width=\\textwidth}\n")
cat("\\begin{tabular}{lcccccc}\n\\toprule\n")
cat("& (1) & (2) & (3) & (4) & (5) & (6) \\\\\n")
cat("& $\\Delta$ OCC & Upgraded & Downgraded & Low-Skill & Mid-Skill & High-Skill \\\\\n")
cat("& All & All & All & $\\Delta$ OCC & $\\Delta$ OCC & $\\Delta$ OCC \\\\\n\\midrule\n")

cat(sprintf("Restricted Share $\\times$ Post-Quota & %s & %s & %s & %s & %s & %s \\\\\n",
            paste0(sprintf("%.3f", int_betas[1]), stars(int_pvals[1])),
            paste0(sprintf("%.4f", int_betas[2]), stars(int_pvals[2])),
            paste0(sprintf("%.4f", int_betas[3]), stars(int_pvals[3])),
            paste0(sprintf("%.3f", int_betas[4]), stars(int_pvals[4])),
            paste0(sprintf("%.3f", int_betas[5]), stars(int_pvals[5])),
            paste0(sprintf("%.3f", int_betas[6]), stars(int_pvals[6]))))
cat(sprintf("& (%.3f) & (%.4f) & (%.4f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
            int_ses[1], int_ses[2], int_ses[3], int_ses[4], int_ses[5], int_ses[6]))
cat("[0.5em]\n")
cat(sprintf("Restricted Share (level) & %s & %s & %s & %s & %s & %s \\\\\n",
            paste0(sprintf("%.3f", exp_betas[1]), stars(exp_pvals[1])),
            paste0(sprintf("%.4f", exp_betas[2]), stars(exp_pvals[2])),
            paste0(sprintf("%.4f", exp_betas[3]), stars(exp_pvals[3])),
            paste0(sprintf("%.3f", exp_betas[4]), stars(exp_pvals[4])),
            paste0(sprintf("%.3f", exp_betas[5]), stars(exp_pvals[5])),
            paste0(sprintf("%.3f", exp_betas[6]), stars(exp_pvals[6]))))
cat(sprintf("& (%.3f) & (%.4f) & (%.4f) & (%.3f) & (%.3f) & (%.3f) \\\\\n",
            exp_ses[1], exp_ses[2], exp_ses[3], exp_ses[4], exp_ses[5], exp_ses[6]))
cat("\\midrule\n")
cat(sprintf("Observations & %s & %s & %s & %s & %s & %s \\\\\n",
            format(ddd_ns[1], big.mark=","), format(ddd_ns[2], big.mark=","),
            format(ddd_ns[3], big.mark=","), format(ddd_ns[4], big.mark=","),
            format(ddd_ns[5], big.mark=","), format(ddd_ns[6], big.mark=",")))
cat("State + Occ.\\ FE & Yes & Yes & Yes & Yes & Yes & Yes \\\\\n")
cat("Clustering & County & County & County & County & County & County \\\\\n")
cat("\\bottomrule\n\\end{tabular}\n\\end{adjustbox}\n")
cat("\\begin{tablenotes}[flushleft]\n\\small\n")
cat("\\item Notes: * p$<$0.10, ** p$<$0.05, *** p$<$0.01. ")
cat("Standard errors clustered at the county level. ")
cat("Stacked panel pools the 1910--1920 (pre-quota) and 1920--1930 (post-quota) linked panels. ")
cat("``Restricted Share $\\times$ Post-Quota'' is the DDD estimand: the change in the exposure--upgrading relationship ")
cat("after the 1924 quota took effect, netting out pre-existing correlations between immigrant settlement and native advancement. ")
cat("A negative coefficient indicates the quota \\emph{reduced} the pace of native upgrading in exposed counties relative to the pre-quota baseline. ")
cat("All specifications include age, age$^2$, white, literate, state FE, and initial occupation FE.\n")
cat("\\end{tablenotes}\n\\end{threeparttable}\n\\label{tab:ddd}\n\\end{table}\n")
sink()

# Save
saveRDS(list(m_ddd = m_ddd, m_ddd_up = m_ddd_up, m_ddd_down = m_ddd_down,
             m_ddd_low = m_ddd_low, m_ddd_mid = m_ddd_mid, m_ddd_high = m_ddd_high),
        "../data/ddd_results.rds")

cat("\nStacked DDD complete.\n")
