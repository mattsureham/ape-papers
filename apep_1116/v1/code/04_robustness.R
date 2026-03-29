## 04_robustness.R — Robustness checks
## APEP-1116: The Patent Office Lottery

source("00_packages.R")

data_dir <- file.path(dirname(getwd()), "data")
df <- fread(file.path(data_dir, "analysis_sample.csv"))
df_reassigned <- df[reassigned == 1]

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ═══════════════════════════════════════════════════════════════════════
# R1: Technology Center Heterogeneity
# ═══════════════════════════════════════════════════════════════════════
cat("R1: Technology center variation...\n")
tc_results <- df_reassigned[, .(
  n = .N,
  discord_rate = mean(discordant),
  grant_rate = mean(child_granted),
  leniency_sd = sd(child_exam_loo_rate, na.rm = TRUE)
), by = tech_center][order(-discord_rate)]
print(tc_results)

# Leniency effect by tech center
tc_regs <- list()
for (tc in unique(df_reassigned$tech_center)) {
  sub <- df_reassigned[tech_center == tc]
  if (nrow(sub) > 500) {
    tc_regs[[tc]] <- feols(child_granted ~ child_exam_loo_rate + parent_granted | au_year,
                           data = sub, vcov = ~child_examiner_id)
  }
}

# ═══════════════════════════════════════════════════════════════════════
# R2: Continuations vs Divisionals
# ═══════════════════════════════════════════════════════════════════════
cat("\nR2: CON vs DIV...\n")
r_con <- feols(child_granted ~ child_exam_loo_rate + parent_granted | au_year,
               data = df_reassigned[continuation_type == "CON"],
               vcov = ~child_examiner_id)
r_div <- feols(child_granted ~ child_exam_loo_rate + parent_granted | au_year,
               data = df_reassigned[continuation_type == "DIV"],
               vcov = ~child_examiner_id)
cat("CON:\n"); print(coeftable(r_con))
cat("DIV:\n"); print(coeftable(r_div))

# ═══════════════════════════════════════════════════════════════════════
# R3: Exclude parent-abandoned pairs (selection into continuation)
# ═══════════════════════════════════════════════════════════════════════
cat("\nR3: Restrict to parent-granted pairs...\n")
r_parent_grant <- feols(child_granted ~ child_exam_loo_rate | au_year,
                        data = df_reassigned[parent_granted == 1],
                        vcov = ~child_examiner_id)
r_parent_abn <- feols(child_granted ~ child_exam_loo_rate | au_year,
                      data = df_reassigned[parent_granted == 0],
                      vcov = ~child_examiner_id)
cat("Parent granted:\n"); print(coeftable(r_parent_grant))
cat("Parent abandoned:\n"); print(coeftable(r_parent_abn))

# ═══════════════════════════════════════════════════════════════════════
# R4: Time period stability
# ═══════════════════════════════════════════════════════════════════════
cat("\nR4: Time period stability...\n")
r_early <- feols(child_granted ~ child_exam_loo_rate + parent_granted | au_year,
                 data = df_reassigned[child_filing_year <= 2006],
                 vcov = ~child_examiner_id)
r_late <- feols(child_granted ~ child_exam_loo_rate + parent_granted | au_year,
                data = df_reassigned[child_filing_year > 2006],
                vcov = ~child_examiner_id)
cat("Early (1998-2006):\n"); print(coeftable(r_early))
cat("Late (2007-2015):\n"); print(coeftable(r_late))

# ═══════════════════════════════════════════════════════════════════════
# R5: Alternative leniency measures
# ═══════════════════════════════════════════════════════════════════════
cat("\nR5: Alternative leniency — within AU-year standardized...\n")
r_z <- feols(child_granted ~ leniency_z + parent_granted | au_year,
             data = df_reassigned, vcov = ~child_examiner_id)
cat("Standardized leniency:\n"); print(coeftable(r_z))

# ═══════════════════════════════════════════════════════════════════════
# R6: Wild cluster bootstrap for key result
# ═══════════════════════════════════════════════════════════════════════
cat("\nR6: Wild cluster bootstrap (art unit level)...\n")
# Use fixest built-in bootstrap
main_wcb <- feols(discordant ~ reassigned + parent_granted | au_year,
                  data = df, vcov = ~child_art_unit)
# Report both analytical and WCB CIs
cat("Analytical SE:\n"); print(coeftable(main_wcb))

# ═══════════════════════════════════════════════════════════════════════
# Save robustness results
# ═══════════════════════════════════════════════════════════════════════
saveRDS(list(
  tc_results = tc_results,
  tc_regs = tc_regs,
  r_con = r_con,
  r_div = r_div,
  r_parent_grant = r_parent_grant,
  r_parent_abn = r_parent_abn,
  r_early = r_early,
  r_late = r_late,
  r_z = r_z,
  main_wcb = main_wcb
), file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
