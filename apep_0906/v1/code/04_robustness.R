## 04_robustness.R — Robustness checks
## apep_0906: Panama Canal Expansion and Port Labor Markets

library(tidyverse)
library(fixest)

data_dir <- file.path(dirname(getwd()), "data")

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
load(file.path(data_dir, "models.RData"))

# ============================================================
# 1. PLACEBO INDUSTRIES
# ============================================================
cat("=== Placebo Industries ===\n")

if (file.exists(file.path(data_dir, "qwi_placebo.rds"))) {
  placebo <- readRDS(file.path(data_dir, "qwi_placebo.rds"))

  placebo <- placebo %>%
    mutate(
      county_id = paste0(state, county),
      time_q = (year - 2010) * 4 + quarter,
      post = as.integer(year > 2016 | (year == 2016 & quarter >= 3)),
      treated = as.integer(region %in% c("East", "Gulf")),
      log_emp = ifelse(Emp > 0, log(Emp), NA_real_)
    )

  # Healthcare (NAICS 62)
  healthcare <- placebo %>% filter(industry == "62", Emp > 0)
  m_health <- feols(log_emp ~ treated:post | county_id + time_q,
                    data = healthcare, cluster = "county_id")
  cat("Healthcare placebo:\n")
  summary(m_health)

  # Professional services (NAICS 54)
  profsvc <- placebo %>% filter(industry == "54", Emp > 0)
  m_prof <- feols(log_emp ~ treated:post | county_id + time_q,
                  data = profsvc, cluster = "county_id")
  cat("\nProfessional services placebo:\n")
  summary(m_prof)

  save(m_health, m_prof, file = file.path(data_dir, "robustness_placebo.RData"))
} else {
  cat("No placebo data available\n")
}

# ============================================================
# 2. EXCLUDE LA/LONG BEACH (dominant West Coast port)
# ============================================================
cat("\n=== Excluding LA County ===\n")

transport_no_la <- panel %>%
  filter(industry == "48-49", Emp > 0, county_id != "06037")

m_no_la <- feols(log_emp ~ treated:post | county_id + time_q,
                 data = transport_no_la, cluster = "county_id")
cat("Without LA County:\n")
summary(m_no_la)

# ============================================================
# 3. LEAVE-ONE-OUT: Drop each port county
# ============================================================
cat("\n=== Leave-One-Out ===\n")

transport_main <- panel %>%
  filter(industry == "48-49", Emp > 0)

loo_results <- data.frame(
  dropped = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

treated_counties <- unique(transport_main$county_id[transport_main$treated == 1])

for (cty in treated_counties) {
  m_loo <- feols(log_emp ~ treated:post | county_id + time_q,
                 data = transport_main %>% filter(county_id != cty),
                 cluster = "county_id")

  port_label <- transport_main %>%
    filter(county_id == cty) %>%
    pull(port_name) %>%
    unique() %>%
    first()

  loo_results <- rbind(loo_results, data.frame(
    dropped = port_label,
    coef = coef(m_loo)["treated:post"],
    se = sqrt(vcov(m_loo)["treated:post", "treated:post"])
  ))
}

cat("Leave-one-out coefficient range:\n")
cat("  Min:", round(min(loo_results$coef), 4), "\n")
cat("  Max:", round(max(loo_results$coef), 4), "\n")
cat("  Main:", round(coef(m1)["treated:post"], 4), "\n")

# ============================================================
# 4. PRE-TREATMENT TREND TEST
# ============================================================
cat("\n=== Pre-Treatment Trend Test ===\n")

pre_data <- transport_main %>% filter(post == 0)

m_pretrend <- feols(log_emp ~ treated:time_q | county_id + time_q,
                    data = pre_data, cluster = "county_id")
cat("Pre-treatment differential trend:\n")
summary(m_pretrend)

# ============================================================
# 5. SAVE ROBUSTNESS RESULTS
# ============================================================

save(m_no_la, loo_results, m_pretrend,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\nRobustness checks complete.\n")
