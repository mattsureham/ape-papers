## 04b_reviewer_checks.R — Additional checks from reviewer feedback
## apep_1007: Banking the Unbanked by Mandate

source("00_packages.R")

panel <- fread("../data/panel_internet_banking.csv")

# ------------------------------------------------------------------
# 1. CS-DiD using ONLY not-yet-treated (exclude never-treated)
# ------------------------------------------------------------------
cat("=== 1. CS-DiD with only not-yet-treated comparison ===\n")

panel_nyt <- panel[group > 0]  # Drop never-treated (group == 0)
panel_nyt[, country_id_nyt := as.integer(factor(country_code))]

cs_nyt <- att_gt(
  yname = "internet_banking_pct",
  tname = "year",
  idname = "country_id_nyt",
  gname = "group",
  data = as.data.frame(panel_nyt),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "varying",
  clustervars = "country_id_nyt",
  print_details = FALSE
)

cs_nyt_simple <- aggte(cs_nyt, type = "simple", na.rm = TRUE)
cat("CS-DiD (not-yet-treated only) ATT:\n")
summary(cs_nyt_simple)
saveRDS(cs_nyt_simple, "../data/cs_nyt_simple.rds")

# ------------------------------------------------------------------
# 2. Sun-Abraham overall ATT (mean of post-treatment coefficients)
# ------------------------------------------------------------------
cat("\n=== 2. Sun-Abraham aggregate ATT ===\n")

panel[, cohort := fifelse(group == 0, 10000L, group)]
sa_fit <- feols(internet_banking_pct ~ sunab(cohort, year) | country_id + year,
                 data = panel, cluster = ~country_id)

sa_coefs <- coef(sa_fit)
sa_names <- names(sa_coefs)
# Post-treatment coefficients (positive event times)
post_idx <- grep("year::([0-9])", sa_names)
sa_post_coefs <- sa_coefs[post_idx]
sa_att_mean <- mean(sa_post_coefs)
cat("Sun-Abraham mean post-treatment ATT:", round(sa_att_mean, 2), "\n")

# Compute approximate SE via delta method (mean of coefficients)
vcov_sa <- vcov(sa_fit)
n_post <- length(post_idx)
sa_se_mean <- sqrt(sum(vcov_sa[post_idx, post_idx]) / n_post^2)
cat("Sun-Abraham approximate SE:", round(sa_se_mean, 2), "\n")

saveRDS(list(att = sa_att_mean, se = sa_se_mean), "../data/sa_aggregate.rds")

cat("\n=== REVIEWER CHECKS COMPLETE ===\n")
