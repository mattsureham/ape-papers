## 02_clean_data.R — Clean and merge all datasets for apep_1103
## Creates: data/panel.rds (canton-year panel, 2000-2024)

source("00_packages.R")

data_dir <- "../data"

# Canton ISO2 to numeric code mapping
canton_map <- tibble(
  canton_code = as.character(1:26),
  canton = c("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG", "FR",
             "SO", "BS", "BL", "SH", "AR", "AI", "SG", "GR", "AG", "TG",
             "TI", "VD", "VS", "NE", "GE", "JU")
)

# ══════════════════════════════════════════════════════════════════════════════
# 1) OKP costs — pivot to wide by cost group
# ══════════════════════════════════════════════════════════════════════════════
cat("── Cleaning OKP costs ──\n")
okp <- readRDS(file.path(data_dir, "okp_costs.rds"))

# Total OKP per-capita costs
okp_total <- okp |>
  filter(cost_group == "Total") |>
  select(year, canton, okp_total_pc = okp_cost_pc)

# Cost decomposition for mechanism analysis
okp_decomp <- okp |>
  filter(cost_group != "Total") |>
  mutate(cost_group_clean = case_when(
    cost_group == "Spitäler ambulant" ~ "ambulatory_hospital",
    cost_group == "Spitäler stationär" ~ "inpatient_hospital",
    cost_group == "Apotheken" ~ "pharmacy",
    cost_group == "Pflegeheime " ~ "nursing_home",
    grepl("^Ärzte", cost_group) ~ "physician",
    cost_group == "PhysiotherapeutInnen" ~ "physiotherapy",
    cost_group == "SPITEX-Organisationen" ~ "home_care",
    cost_group == "Laboratorien " ~ "laboratory",
    TRUE ~ "other"
  )) |>
  group_by(year, canton, cost_group_clean) |>
  summarise(okp_cost_pc = sum(okp_cost_pc, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = cost_group_clean, values_from = okp_cost_pc,
              names_prefix = "okp_")

cat("  OKP total: ", nrow(okp_total), " canton-years\n")
cat("  OKP decomp: ", nrow(okp_decomp), " canton-years\n")

# ══════════════════════════════════════════════════════════════════════════════
# 2) IV integration measures — compute per-capita intensity
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Cleaning IV integration measures ──\n")
iv_raw <- readRDS(file.path(data_dir, "iv_integration_raw.rds"))

# Parse the integration data
iv_integ <- iv_raw |>
  mutate(
    canton_code = `IV-Stelle`,
    year = as.integer(Jahr),
    obs_unit = Beobachtungseinheit,      # 1=count, 2=CHF thousands
    measure_type = Leistungsart           # 20=early intervention, 30=integration, 40=vocational, 60=all
  ) |>
  left_join(canton_map, by = "canton_code")

# Get total integration recipients per canton-year (code 60 = all measures)
iv_recipients <- iv_integ |>
  filter(obs_unit == "1", measure_type == "60") |>
  select(year, canton, integ_recipients = value)

# Get early intervention specifically (code 20) — new from 2008 reform
iv_early <- iv_integ |>
  filter(obs_unit == "1", measure_type == "20") |>
  select(year, canton, early_intev_recipients = value)

# Get integration measures spending (code 60, obs_unit 2)
iv_spending <- iv_integ |>
  filter(obs_unit == "2", measure_type == "60") |>
  select(year, canton, integ_spending_kchf = value)

cat("  IV recipients: ", nrow(iv_recipients), " canton-years\n")
cat("  Early intervention: ", nrow(iv_early), " canton-years\n")

# ══════════════════════════════════════════════════════════════════════════════
# 3) IV pension recipients — derive population
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Cleaning IV pension data and deriving population ──\n")
iv_pens_raw <- readRDS(file.path(data_dir, "iv_pensions_raw.rds"))

iv_pens <- iv_pens_raw |>
  mutate(
    canton_code = Kanton,
    year = as.integer(Jahr),
    obs_unit = Beobachtungseinheit
  ) |>
  left_join(canton_map, by = "canton_code")

# Separate counts and population shares
iv_pens_count <- iv_pens |>
  filter(obs_unit == "1") |>
  select(year, canton, di_recipients = value)

iv_pens_share <- iv_pens |>
  filter(obs_unit == "2") |>
  select(year, canton, di_pop_share = value)

# Derive population: count = share/100 * pop => pop = count / (share/100) * 100
pop_derived <- iv_pens_count |>
  inner_join(iv_pens_share, by = c("year", "canton")) |>
  filter(di_pop_share > 0, !is.na(di_pop_share), !is.na(di_recipients)) |>
  mutate(population = round(di_recipients / (di_pop_share / 100)))

cat("  Derived population for", nrow(pop_derived), "canton-years (",
    range(pop_derived$year), ")\n")

# Backcast population for 2000-2008 using canton-specific linear trend from 2009-2012
pop_for_backcast <- pop_derived |>
  filter(year >= 2009, year <= 2012) |>
  group_by(canton) |>
  summarise(
    pop_2009 = population[year == 2009],
    avg_growth = mean(diff(population)),
    .groups = "drop"
  )

pop_backcast <- pop_for_backcast |>
  crossing(year = 2000:2008) |>
  mutate(
    years_before_2009 = 2009 - year,
    population = round(pop_2009 - avg_growth * years_before_2009)
  ) |>
  select(canton, year, population)

# Combine
pop_all <- bind_rows(
  pop_derived |> select(canton, year, population),
  pop_backcast
) |>
  arrange(canton, year)

cat("  Population panel: ", nrow(pop_all), " canton-years (",
    range(pop_all$year), ")\n")

# ══════════════════════════════════════════════════════════════════════════════
# 4) Merge into panel
# ══════════════════════════════════════════════════════════════════════════════
cat("\n── Merging panel ──\n")

panel <- okp_total |>
  filter(year >= 2000) |>
  left_join(okp_decomp, by = c("year", "canton")) |>
  left_join(pop_all, by = c("year", "canton")) |>
  left_join(iv_recipients, by = c("year", "canton")) |>
  left_join(iv_early, by = c("year", "canton")) |>
  left_join(iv_spending, by = c("year", "canton")) |>
  left_join(
    iv_pens_count, by = c("year", "canton")
  ) |>
  mutate(
    # Per-capita treatment intensity (integration recipients per 1,000 pop)
    integ_intensity = ifelse(!is.na(population) & population > 0,
                             integ_recipients / population * 1000, NA),
    early_intev_intensity = ifelse(!is.na(population) & population > 0,
                                   early_intev_recipients / population * 1000, NA),
    # DI caseload rate (per 1,000 pop)
    di_rate = ifelse(!is.na(population) & population > 0,
                     di_recipients / population * 1000, NA),
    # Reform period indicators
    post_2008 = as.integer(year >= 2008),
    post_2012 = as.integer(year >= 2012),
    # Log outcome
    log_okp_total_pc = log(okp_total_pc),
    # Canton numeric ID for FE
    canton_id = as.integer(factor(canton))
  )

cat("  Panel dimensions: ", nrow(panel), " rows, ", ncol(panel), " columns\n")
cat("  Cantons: ", length(unique(panel$canton)), "\n")
cat("  Years: ", range(panel$year), "\n")
cat("  Integration intensity available: ", sum(!is.na(panel$integ_intensity)), " obs\n")
cat("  DI rate available: ", sum(!is.na(panel$di_rate)), " obs\n")

stopifnot(length(unique(panel$canton)) == 26)
stopifnot(nrow(panel) >= 600)

saveRDS(panel, file.path(data_dir, "panel.rds"))
cat("  Saved panel.rds\n")

# ══════════════════════════════════════════════════════════════════════════════
# 5) Pre-reform treatment intensity (for heterogeneity splits)
# ══════════════════════════════════════════════════════════════════════════════
# Compute pre-2008 average DI rate for splitting high vs low DI cantons
pre_reform <- panel |>
  filter(year >= 2000, year <= 2007, !is.na(di_rate)) |>
  group_by(canton) |>
  summarise(
    pre_di_rate = mean(di_rate, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(high_di = as.integer(pre_di_rate > median(pre_di_rate)))

panel <- panel |>
  left_join(pre_reform, by = "canton")

saveRDS(panel, file.path(data_dir, "panel.rds"))
cat("  Updated panel with pre-reform splits\n")

# Summary stats preview
cat("\n══ Panel summary ══\n")
panel |>
  filter(year >= 2006) |>
  summarise(
    across(c(okp_total_pc, integ_intensity, di_rate),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE),
                min = ~min(.x, na.rm = TRUE),
                max = ~max(.x, na.rm = TRUE)))
  ) |>
  pivot_longer(everything()) |>
  print(n = 20)
