## 04_robustness.R — Robustness checks
source("00_packages.R")

panel <- read_csv("../data/panel_clean.csv", show_col_types = FALSE)
load("../data/main_results.RData")

cat("=== Robustness Checks ===\n")

# ---------------------------------------------------------------
# 1. Excluding Java/Bali (most urbanized, different labor markets)
# ---------------------------------------------------------------
java_bali <- c(31, 32, 33, 34, 35, 36, 51)  # Jakarta, W/C/E Java, Banten, Yogyakarta, Bali
panel_nojava <- panel %>% filter(!(prov_id %in% java_bali))

r1_unemp <- feols(unemp_rate ~ kaitz_x_post | prov_id + year,
                  data = panel_nojava, cluster = ~prov_id)
r1_emp <- feols(emp_rate ~ kaitz_x_post | prov_id + year,
                data = panel_nojava, cluster = ~prov_id)

cat("Excl. Java/Bali:\n")
cat(sprintf("  Unemployment: β=%.3f, SE=%.3f, p=%.3f\n",
            coef(r1_unemp), se(r1_unemp), pvalue(r1_unemp)))
cat(sprintf("  Employment: β=%.3f, SE=%.3f, p=%.3f\n",
            coef(r1_emp), se(r1_emp), pvalue(r1_emp)))

# ---------------------------------------------------------------
# 2. Excluding resource-dependent provinces (oil/gas/mining)
# ---------------------------------------------------------------
resource_provs <- c(14, 64, 65, 91, 94)  # Riau, E/N Kalimantan, W Papua, Papua
panel_noresource <- panel %>% filter(!(prov_id %in% resource_provs))

r2_unemp <- feols(unemp_rate ~ kaitz_x_post | prov_id + year,
                  data = panel_noresource, cluster = ~prov_id)
r2_emp <- feols(emp_rate ~ kaitz_x_post | prov_id + year,
                data = panel_noresource, cluster = ~prov_id)

cat("\nExcl. resource provinces:\n")
cat(sprintf("  Unemployment: β=%.3f, SE=%.3f\n", coef(r2_unemp), se(r2_unemp)))
cat(sprintf("  Employment: β=%.3f, SE=%.3f\n", coef(r2_emp), se(r2_emp)))

# ---------------------------------------------------------------
# 3. Tercile treatment (low/medium/high Kaitz)
# ---------------------------------------------------------------
kaitz_terciles <- quantile(panel$kaitz_actual[panel$year == 2015], probs = c(1/3, 2/3))
panel <- panel %>%
  mutate(kaitz_tercile = case_when(
    kaitz_actual <= kaitz_terciles[1] ~ "low",
    kaitz_actual <= kaitz_terciles[2] ~ "medium",
    TRUE ~ "high"
  ))

panel$kaitz_tercile <- factor(panel$kaitz_tercile, levels = c("low", "medium", "high"))
panel$high_tercile <- as.integer(panel$kaitz_tercile == "high")
panel$med_tercile <- as.integer(panel$kaitz_tercile == "medium")

r3_unemp <- feols(unemp_rate ~ i(post, high_tercile, ref = 0) + i(post, med_tercile, ref = 0) | prov_id + year,
                  data = panel, cluster = ~prov_id)
r3_emp <- feols(emp_rate ~ i(post, high_tercile, ref = 0) + i(post, med_tercile, ref = 0) | prov_id + year,
                data = panel, cluster = ~prov_id)

cat("\nTercile treatment:\n")
summary(r3_unemp)
summary(r3_emp)

# ---------------------------------------------------------------
# 4. Placebo test: Use 2013 as fake treatment year
# ---------------------------------------------------------------
panel_placebo <- panel %>%
  filter(year <= 2015) %>%
  mutate(
    post_placebo = as.integer(year >= 2013),
    kaitz_x_placebo = kaitz_actual * post_placebo
  )

r4_unemp <- feols(unemp_rate ~ kaitz_x_placebo | prov_id + year,
                  data = panel_placebo, cluster = ~prov_id)
r4_emp <- feols(emp_rate ~ kaitz_x_placebo | prov_id + year,
                data = panel_placebo, cluster = ~prov_id)

cat("\nPlacebo (2013 as fake treatment):\n")
cat(sprintf("  Unemployment: β=%.3f, SE=%.3f, p=%.3f\n",
            coef(r4_unemp), se(r4_unemp), pvalue(r4_unemp)))
cat(sprintf("  Employment: β=%.3f, SE=%.3f, p=%.3f\n",
            coef(r4_emp), se(r4_emp), pvalue(r4_emp)))

# ---------------------------------------------------------------
# 5. Wage bite specification (MW/GRDP instead of Kaitz)
# ---------------------------------------------------------------
# Use 2015 wage bite as alternative treatment intensity
panel <- panel %>%
  group_by(prov_id) %>%
  mutate(bite_2015 = min_wage[year == 2015][1] / grdp_pc[year == 2015][1]) %>%
  ungroup() %>%
  mutate(bite_x_post = bite_2015 * post)

r5_unemp <- feols(unemp_rate ~ bite_x_post | prov_id + year,
                  data = panel, cluster = ~prov_id)
r5_emp <- feols(emp_rate ~ bite_x_post | prov_id + year,
                data = panel, cluster = ~prov_id)

cat("\nWage bite specification:\n")
cat(sprintf("  Unemployment: β=%.3f, SE=%.3f, p=%.3f\n",
            coef(r5_unemp), se(r5_unemp), pvalue(r5_unemp)))

# ---------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------
save(r1_unemp, r1_emp, r2_unemp, r2_emp,
     r3_unemp, r3_emp, r4_unemp, r4_emp,
     r5_unemp, r5_emp,
     file = "../data/robustness_results.RData")

write_csv(panel, "../data/panel_clean.csv")

cat("\n=== Robustness checks complete ===\n")
