## 02_clean_data.R — Build analysis panel for Italy AUU fertility study
source("00_packages.R")

cat("=== Building analysis panel ===\n")

# Load fetched data
births <- readRDS("../data/nuts3_birth_rates.rds")
births_abs <- readRDS("../data/nuts3_birth_counts.rds")
pop_total <- readRDS("../data/nuts3_population.rds")
pop_women <- readRDS("../data/nuts3_women_15_49.rds")
selfemp_2019 <- readRDS("../data/selfemp_2019.rds")
gdp <- readRDS("../data/nuts2_gdp.rds")
unemp <- readRDS("../data/nuts2_unemployment.rds")

# ---------------------------------------------------------------
# 1. Create NUTS3 → NUTS2 mapping
# ---------------------------------------------------------------
# NUTS3 codes: first 4 chars = NUTS2 (e.g., ITF32 → ITF3)
births <- births %>%
  mutate(
    nuts2 = str_sub(nuts3, 1, 4),
    country = str_sub(nuts3, 1, 2)
  )

births_abs <- births_abs %>%
  mutate(
    nuts2 = str_sub(nuts3, 1, 4),
    country = str_sub(nuts3, 1, 2)
  )

# ---------------------------------------------------------------
# 2. Merge birth rates with population and treatment intensity
# ---------------------------------------------------------------
# Merge population
panel <- births %>%
  left_join(pop_total, by = c("nuts3", "year")) %>%
  left_join(pop_women, by = c("nuts3", "year"))

# Merge absolute birth counts
panel <- panel %>%
  left_join(births_abs %>% select(nuts3, year, births), by = c("nuts3", "year"))

# Compute fertility rate per 1000 women 15-49 where possible
panel <- panel %>%
  mutate(fertility_rate = ifelse(women_15_49 > 0, (births / women_15_49) * 1000, NA))

# ---------------------------------------------------------------
# 3. Merge self-employment share (treatment intensity)
# ---------------------------------------------------------------
# Italian regions get their self-employment share
panel <- panel %>%
  left_join(selfemp_2019, by = "nuts2")

# For non-Italian regions, self_emp_share_2019 = 0 (no AUU treatment)
panel <- panel %>%
  mutate(self_emp_share_2019 = ifelse(country == "IT",
                                       self_emp_share_2019,
                                       0))

# ---------------------------------------------------------------
# 4. Merge controls (GDP, unemployment)
# ---------------------------------------------------------------
panel <- panel %>%
  left_join(gdp, by = c("nuts2", "year")) %>%
  left_join(unemp, by = c("nuts2", "year"))

# ---------------------------------------------------------------
# 5. Create treatment variables
# ---------------------------------------------------------------
panel <- panel %>%
  mutate(
    post = as.integer(year >= 2022),
    italy = as.integer(country == "IT"),
    # Continuous treatment intensity (within Italy)
    treatment_intensity = post * self_emp_share_2019,
    # DDD interaction
    ddd = post * italy * self_emp_share_2019,
    # For Italian-only DD
    dd_post_selfemp = post * self_emp_share_2019
  )

# ---------------------------------------------------------------
# 6. Data quality checks
# ---------------------------------------------------------------
cat("\n--- Panel summary ---\n")
cat(sprintf("Total obs: %d\n", nrow(panel)))
cat(sprintf("Italian NUTS3 regions: %d\n", n_distinct(panel$nuts3[panel$country == "IT"])))
cat(sprintf("EU comparator NUTS3 regions: %d\n", n_distinct(panel$nuts3[panel$country != "IT"])))
cat(sprintf("Years: %d to %d\n", min(panel$year), max(panel$year)))
cat(sprintf("Missing birth_rate: %d (%.1f%%)\n",
            sum(is.na(panel$birth_rate)),
            100 * mean(is.na(panel$birth_rate))))
cat(sprintf("Missing fertility_rate: %d (%.1f%%)\n",
            sum(is.na(panel$fertility_rate)),
            100 * mean(is.na(panel$fertility_rate))))

# Italian NUTS2 self-employment distribution
cat("\n--- Self-employment share (2019), Italian NUTS2 ---\n")
it_panel <- panel %>% filter(country == "IT", year == 2019) %>%
  distinct(nuts2, self_emp_share_2019)
cat(sprintf("  Min: %.1f%%  Max: %.1f%%  Mean: %.1f%%  SD: %.1f%%\n",
            100*min(it_panel$self_emp_share_2019, na.rm=TRUE),
            100*max(it_panel$self_emp_share_2019, na.rm=TRUE),
            100*mean(it_panel$self_emp_share_2019, na.rm=TRUE),
            100*sd(it_panel$self_emp_share_2019, na.rm=TRUE)))

# Check birth rate trends
cat("\n--- Italian mean birth rate by year ---\n")
panel %>%
  filter(country == "IT") %>%
  group_by(year) %>%
  summarise(mean_br = mean(birth_rate, na.rm = TRUE), .groups = "drop") %>%
  print(n = 20)

# ---------------------------------------------------------------
# 7. Create Italy-only panel (for main DD specification)
# ---------------------------------------------------------------
it_panel_full <- panel %>%
  filter(country == "IT") %>%
  filter(!is.na(birth_rate), !is.na(self_emp_share_2019))

cat(sprintf("\nItaly-only panel: %d obs, %d NUTS3 regions\n",
            nrow(it_panel_full), n_distinct(it_panel_full$nuts3)))

# ---------------------------------------------------------------
# 8. Save analysis-ready panels
# ---------------------------------------------------------------
saveRDS(panel, "../data/analysis_panel.rds")
saveRDS(it_panel_full, "../data/italy_panel.rds")

cat("=== Panel construction complete ===\n")
