## 03_main_analysis.R — Main regressions for Italy AUU fertility study
source("00_packages.R")

cat("=== Main Analysis ===\n")

it_panel <- readRDS("../data/italy_panel.rds")
full_panel <- readRDS("../data/analysis_panel.rds")

# ---------------------------------------------------------------
# 1. Summary statistics
# ---------------------------------------------------------------
cat("\n--- Summary Statistics ---\n")

# Pre-reform (2015-2021) by self-employment tertile
it_panel <- it_panel %>%
  mutate(
    selfemp_tercile = ntile(self_emp_share_2019, 3),
    selfemp_label = case_when(
      selfemp_tercile == 1 ~ "Low",
      selfemp_tercile == 2 ~ "Medium",
      selfemp_tercile == 3 ~ "High"
    )
  )

pre_stats <- it_panel %>%
  filter(year < 2022) %>%
  group_by(selfemp_label) %>%
  summarise(
    n_regions = n_distinct(nuts3),
    mean_br = mean(birth_rate, na.rm = TRUE),
    sd_br = sd(birth_rate, na.rm = TRUE),
    mean_selfemp = mean(self_emp_share_2019, na.rm = TRUE),
    mean_unemp = mean(unemp_rate, na.rm = TRUE),
    .groups = "drop"
  )
cat("Pre-reform (2015-2021) by self-employment tercile:\n")
print(pre_stats)

# ---------------------------------------------------------------
# 2. Main specification: Italy-only DD
# ---------------------------------------------------------------
# Birth rate ~ Post * SelfEmpShare + region FE + year FE
cat("\n--- Main DD: Birth rate ~ Post x SelfEmpShare ---\n")

# Specification 1: Basic DD
m1 <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
            data = it_panel, cluster = ~nuts2)

# Specification 2: DD with controls
m2 <- feols(birth_rate ~ dd_post_selfemp + unemp_rate + log(gdp_mio + 1) |
              nuts3 + year,
            data = it_panel, cluster = ~nuts2)

# Specification 3: Event study (year-by-year interactions)
it_panel <- it_panel %>%
  mutate(
    rel_year = year - 2022,
    event_int = rel_year * self_emp_share_2019
  )

# Create year dummies interacted with self-employment share
m3 <- feols(birth_rate ~ i(year, self_emp_share_2019, ref = 2021) |
              nuts3 + year,
            data = it_panel, cluster = ~nuts2)

cat("Model 1 (Basic DD):\n")
summary(m1)
cat("\nModel 2 (DD + controls):\n")
summary(m2)
cat("\nModel 3 (Event study):\n")
summary(m3)

# ---------------------------------------------------------------
# 3. DDD: Italy vs EU comparators
# ---------------------------------------------------------------
cat("\n--- DDD: Italy vs EU comparators ---\n")

# Full panel with EU comparators
full_panel <- full_panel %>%
  filter(!is.na(birth_rate)) %>%
  mutate(
    selfemp_for_ddd = ifelse(country == "IT", self_emp_share_2019, 0)
  )

m4 <- feols(birth_rate ~ post:italy:selfemp_for_ddd +
              post:italy + post:selfemp_for_ddd |
              nuts3 + year,
            data = full_panel, cluster = ~nuts2)

cat("Model 4 (DDD):\n")
summary(m4)

# ---------------------------------------------------------------
# 4. Heterogeneity by Southern vs Northern Italy
# ---------------------------------------------------------------
cat("\n--- Heterogeneity: South vs North ---\n")

# Southern NUTS2 codes: ITF (Sud), ITG (Isole)
it_panel <- it_panel %>%
  mutate(south = as.integer(str_sub(nuts2, 1, 3) %in% c("ITF", "ITG")))

m5_north <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                  data = it_panel %>% filter(south == 0), cluster = ~nuts2)
m5_south <- feols(birth_rate ~ dd_post_selfemp | nuts3 + year,
                  data = it_panel %>% filter(south == 1), cluster = ~nuts2)

cat("North:\n"); summary(m5_north)
cat("\nSouth:\n"); summary(m5_south)

# ---------------------------------------------------------------
# 5. Save results
# ---------------------------------------------------------------
results <- list(
  m1_basic_dd = m1,
  m2_dd_controls = m2,
  m3_event_study = m3,
  m4_ddd = m4,
  m5_north = m5_north,
  m5_south = m5_south
)
saveRDS(results, "../data/main_results.rds")

# ---------------------------------------------------------------
# 6. Diagnostics for validator
# ---------------------------------------------------------------
diag <- list(
  n_treated = n_distinct(it_panel$nuts3[it_panel$self_emp_share_2019 > median(it_panel$self_emp_share_2019)]),
  n_pre = length(unique(it_panel$year[it_panel$year < 2022])),
  n_obs = nrow(it_panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\n--- Diagnostics ---\n"))
cat(sprintf("n_treated (above-median SE share): %d\n", diag$n_treated))
cat(sprintf("n_pre periods: %d\n", diag$n_pre))
cat(sprintf("n_obs: %d\n", diag$n_obs))

cat("\n=== Main analysis complete ===\n")
