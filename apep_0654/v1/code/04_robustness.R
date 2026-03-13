## 04_robustness.R — Robustness checks
source("00_packages.R")

cat("=== Robustness checks ===\n")

df <- read_parquet("../data/analysis_panel.parquet")
edu_df <- read_parquet("../data/edu_analysis_panel.parquet")

# ------------------------------------------------------------------
# 1. Event study for DDD interaction
# ------------------------------------------------------------------
cat("\n--- Event study ---\n")

# Create relative time to treatment
df <- df %>%
  mutate(rel_time = ifelse(treat_yq > 0, yq - treat_yq, NA_integer_))

# Bin endpoints
df <- df %>%
  mutate(rel_time_binned = case_when(
    is.na(rel_time) ~ NA_integer_,
    rel_time < -8 ~ -8L,
    rel_time > 12 ~ 12L,
    TRUE ~ as.integer(rel_time)
  ))

# Event study on hire rate for licensed sectors only (treated states)
lic_treated <- df %>% filter(licensed == 1 & treated == 1 & !is.na(rel_time_binned))

es_hire <- feols(
  hire_rate ~ i(rel_time_binned, ref = -1) | state_fips + yq,
  data = lic_treated,
  cluster = ~state_fips,
  weights = ~emp
)

# Extract pre-treatment coefficients
es_coefs <- coef(es_hire)
es_se <- se(es_hire)
pre_coefs <- es_coefs[grep("rel_time_binned::-[2-8]", names(es_coefs))]
cat("Pre-treatment coefficients (hire rate):\n")
print(round(pre_coefs, 4))
cat("Max absolute pre-treatment:", round(max(abs(pre_coefs)), 4), "\n")

# ------------------------------------------------------------------
# 2. Placebo: Retail/Food sectors only (should show null)
# ------------------------------------------------------------------
cat("\n--- Placebo: unlicensed sectors ---\n")

unlic_df <- df %>% filter(licensed == 0)
unlic_state <- unlic_df %>%
  group_by(state_fips, year, quarter, yq, treat_yq) %>%
  summarise(
    log_earn_hir = {
      v <- !is.na(earn_hir) & !is.na(hir_n) & hir_n > 0
      if (sum(v) == 0) NA_real_ else log(weighted.mean(earn_hir[v], hir_n[v]))
    },
    emp = sum(emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(is.finite(log_earn_hir))

cs_placebo <- att_gt(
  yname = "log_earn_hir",
  tname = "yq",
  idname = "state_fips",
  gname = "treat_yq",
  data = as.data.frame(unlic_state %>% mutate(state_fips = as.numeric(state_fips))),
  control_group = "nevertreated",
  base_period = "universal"
)
cs_placebo_agg <- aggte(cs_placebo, type = "simple")
cat("Placebo (unlicensed) ATT:", round(cs_placebo_agg$overall.att, 4),
    "SE:", round(cs_placebo_agg$overall.se, 4), "\n")

# ------------------------------------------------------------------
# 3. Exclude COVID quarters (2020Q2-2021Q2)
# ------------------------------------------------------------------
cat("\n--- Exclude COVID ---\n")

no_covid <- df %>%
  filter(!(year == 2020 & quarter >= 2) & !(year == 2021 & quarter <= 2))

ddd_nocovid <- feols(
  log_earn_hir ~ post:licensed + post + licensed |
    state_fips + industry^yq,
  data = no_covid,
  cluster = ~state_fips,
  weights = ~hir_n
)
cat("DDD excl. COVID:", round(coef(ddd_nocovid)["post:licensed"], 4),
    "SE:", round(se(ddd_nocovid)["post:licensed"], 4), "\n")

# ------------------------------------------------------------------
# 4. Education DDD: High-ed (licensed) vs Low-ed within licensed sectors
# ------------------------------------------------------------------
cat("\n--- Education DDD ---\n")

edu_lic <- edu_df %>%
  filter(licensed == 1) %>%
  mutate(
    log_earn_hir = log(earn_hir),
    hire_rate = hir_n / emp
  ) %>%
  filter(is.finite(log_earn_hir), emp > 0)

edu_ddd <- feols(
  log_earn_hir ~ post:high_ed + post + high_ed |
    state_fips + industry^yq,
  data = edu_lic,
  cluster = ~state_fips,
  weights = ~hir_n
)
cat("Education DDD (post × high_ed):", round(coef(edu_ddd)["post:high_ed"], 4),
    "SE:", round(se(edu_ddd)["post:high_ed"], 4), "\n")

edu_hire_ddd <- feols(
  hire_rate ~ post:high_ed + post + high_ed |
    state_fips + industry^yq,
  data = edu_lic,
  cluster = ~state_fips,
  weights = ~emp
)
cat("Education DDD hire rate:", round(coef(edu_hire_ddd)["post:high_ed"], 4),
    "SE:", round(se(edu_hire_ddd)["post:high_ed"], 4), "\n")

# ------------------------------------------------------------------
# 5. Industry-by-industry effects
# ------------------------------------------------------------------
cat("\n--- Industry-level effects ---\n")

ind_labels <- c("62" = "Healthcare", "54" = "Professional",
                "23" = "Construction", "61" = "Education",
                "44-45" = "Retail", "72" = "Accomm/Food",
                "51" = "Information", "42" = "Wholesale",
                "48-49" = "Transport", "56" = "Admin")

industry_results <- map_dfr(unique(df$industry), function(ind) {
  sub <- df %>% filter(industry == ind)
  sub_state <- sub %>%
    group_by(state_fips, year, quarter, yq, treat_yq) %>%
    summarise(
      log_earn_hir = {
        v <- !is.na(earn_hir) & !is.na(hir_n) & hir_n > 0
        if (sum(v) == 0) NA_real_ else log(weighted.mean(earn_hir[v], hir_n[v]))
      },
      hire_rate = sum(hir_n, na.rm=TRUE) / sum(emp, na.rm=TRUE),
      .groups = "drop"
    ) %>%
    filter(is.finite(log_earn_hir))

  tryCatch({
    cs <- att_gt(
      yname = "log_earn_hir", tname = "yq", idname = "state_fips",
      gname = "treat_yq",
      data = as.data.frame(sub_state %>% mutate(state_fips = as.numeric(state_fips))),
      control_group = "nevertreated", base_period = "universal"
    )
    agg <- aggte(cs, type = "simple")
    tibble(
      industry = ind,
      label = ind_labels[ind],
      licensed = ifelse(ind %in% c("62","54","23","61"), "Yes", "No"),
      att = agg$overall.att,
      se = agg$overall.se,
      p = 2 * pnorm(-abs(agg$overall.att / agg$overall.se))
    )
  }, error = function(e) {
    tibble(industry = ind, label = ind_labels[ind],
           licensed = ifelse(ind %in% c("62","54","23","61"), "Yes", "No"),
           att = NA_real_, se = NA_real_, p = NA_real_)
  })
})

cat("\nIndustry-level CS-DiD ATTs:\n")
print(industry_results %>% arrange(desc(licensed), industry), n = 20)

# ------------------------------------------------------------------
# 6. Save robustness results
# ------------------------------------------------------------------
save(cs_placebo_agg, ddd_nocovid, edu_ddd, edu_hire_ddd,
     industry_results, es_hire,
     file = "../data/robustness_results.RData")

cat("\n=== Robustness complete ===\n")
