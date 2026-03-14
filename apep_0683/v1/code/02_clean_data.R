## 02_clean_data.R — Parse and clean all data for APEP-0683
## Constructs the LA-year analysis panel

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## 1. Parse Table 615 — Long-term vacant dwellings
## ============================================================
cat("=== Parsing Table 615 ===\n")

raw_ltv <- readODS::read_ods(
  file.path(data_dir, "Live_Table_615.ods"),
  sheet = "All_long_term_vacants", col_names = FALSE
)

header_row <- as.character(raw_ltv[3, ])
date_cols <- header_row[3:ncol(raw_ltv)]
years <- as.integer(str_extract(date_cols, "\\d{4}$"))
cat("  Years:", paste(years, collapse = ", "), "\n")

data_rows <- raw_ltv[4:nrow(raw_ltv), ]
names(data_rows) <- c("ons_code", "area_name", paste0("y_", years))

la_ltv <- data_rows %>%
  filter(str_detect(ons_code, "^E0[6789]")) %>%
  mutate(across(starts_with("y_"), ~ {
    x <- as.character(.)
    ifelse(x %in% c("[x]", "[c]", "[z]", "..", "-", "NA", ""), NA_real_, as.numeric(x))
  }))

ltv_long <- la_ltv %>%
  pivot_longer(starts_with("y_"), names_to = "year", values_to = "long_term_vacant") %>%
  mutate(year = as.integer(str_extract(year, "\\d+"))) %>%
  select(ons_code, area_name, year, long_term_vacant) %>%
  filter(!is.na(long_term_vacant))

cat("  LTV panel:", nrow(ltv_long), "obs,", n_distinct(ltv_long$ons_code), "LAs\n")

## All vacants (for normalization)
raw_av <- readODS::read_ods(
  file.path(data_dir, "Live_Table_615.ods"),
  sheet = "All_vacants", col_names = FALSE
)
data_av <- raw_av[4:nrow(raw_av), ]
names(data_av) <- c("ons_code", "area_name", paste0("y_", years))

av_long <- data_av %>%
  filter(str_detect(ons_code, "^E0[6789]")) %>%
  mutate(across(starts_with("y_"), ~ {
    x <- as.character(.)
    ifelse(x %in% c("[x]", "[c]", "[z]", "..", "-", "NA", ""), NA_real_, as.numeric(x))
  })) %>%
  pivot_longer(starts_with("y_"), names_to = "year", values_to = "all_vacant") %>%
  mutate(year = as.integer(str_extract(year, "\\d+"))) %>%
  select(ons_code, year, all_vacant) %>%
  filter(!is.na(all_vacant))

## ============================================================
## 2. Parse CTB — Treatment assignment
## ============================================================
cat("\n=== Parsing CTB data for treatment assignment ===\n")

raw_ep <- readxl::read_excel(
  file.path(data_dir, "CTB_LA_2025.xlsx"),
  sheet = "Empty Properties Data", col_names = FALSE
)

# Column 92 = "Has the premium been applied?" (Yes/No)
# Columns 391-394 = premium counts by duration band
data_ep <- raw_ep[7:nrow(raw_ep), ]

treatment <- data_ep %>%
  transmute(
    ons_code = as.character(.[[2]]),
    la_name = as.character(.[[4]]),
    has_premium = as.character(.[[92]]),
    n_prem_1_2yr = as.numeric(.[[391]]),
    n_prem_2_5yr = as.numeric(.[[392]]),
    n_prem_5_10yr = as.numeric(.[[393]]),
    n_prem_10yr_plus = as.numeric(.[[394]])
  ) %>%
  filter(str_detect(ons_code, "^E0[6789]")) %>%
  mutate(
    ever_treated = has_premium == "Yes",
    # Premium first allowed April 2013; vast majority adopted by Oct 2014
    # 5 LAs never adopted: Amber Valley, Bolsover, Castle Point, Gravesham, Ribble Valley
    # For CS-DiD: first_treat = 2013 for adopters, 0 for never-treated
    first_treat = ifelse(ever_treated, 2013L, 0L),
    # Total premium-charged properties
    n_premium_total = rowSums(cbind(
      replace_na(n_prem_1_2yr, 0),
      replace_na(n_prem_2_5yr, 0),
      replace_na(n_prem_5_10yr, 0),
      replace_na(n_prem_10yr_plus, 0)
    ))
  )

cat("  Treatment distribution:\n")
cat("    Treated (premium applied):", sum(treatment$ever_treated), "\n")
cat("    Never-treated:", sum(!treatment$ever_treated), "\n")
cat("    Never-treated LAs:", paste(treatment$la_name[!treatment$ever_treated], collapse = ", "), "\n")

## ============================================================
## 3. Population data
## ============================================================
cat("\n=== Parsing population data ===\n")
pop_file <- file.path(data_dir, "population_la.csv")
pop <- tibble()
if (file.exists(pop_file)) {
  pop <- read_csv(pop_file, show_col_types = FALSE) %>%
    transmute(
      ons_code = GEOGRAPHY_CODE,
      year = as.integer(str_extract(DATE_NAME, "\\d{4}")),
      population = OBS_VALUE
    )
  cat("  Population:", nrow(pop), "obs\n")
}

## ============================================================
## 4. Construct analysis panel
## ============================================================
cat("\n=== Constructing analysis panel ===\n")

panel <- ltv_long %>%
  left_join(av_long, by = c("ons_code", "year")) %>%
  inner_join(treatment %>% select(ons_code, la_name, ever_treated, first_treat),
             by = "ons_code") %>%
  left_join(pop, by = c("ons_code", "year"))

# Compute derived outcomes
panel <- panel %>%
  mutate(
    # Long-term vacant share (of all vacants)
    ltv_share = ifelse(all_vacant > 0, long_term_vacant / all_vacant * 100, NA_real_),
    # Log outcomes
    log_ltv = ifelse(long_term_vacant > 0, log(long_term_vacant), NA_real_),
    log_av = ifelse(all_vacant > 0, log(all_vacant), NA_real_),
    # Per-capita rate
    ltv_per_1000 = ifelse(!is.na(population) & population > 0,
                          long_term_vacant / population * 1000, NA_real_),
    # Post-treatment indicator
    post = year >= 2013,
    # Treatment x post
    treated_post = ever_treated & post,
    # Numeric LA id for fixest
    la_id = as.integer(factor(ons_code))
  )

# Create balanced panel: keep LAs with data for 2004-2024 (core period)
la_coverage <- panel %>%
  filter(year >= 2004, year <= 2024) %>%
  group_by(ons_code) %>%
  summarise(n_years = n(), .groups = "drop")

panel_balanced <- panel %>%
  semi_join(la_coverage %>% filter(n_years >= 18), by = "ons_code")

cat("  Full panel:", nrow(panel), "obs,", n_distinct(panel$ons_code), "LAs\n")
cat("  Balanced panel (≥18 years):", nrow(panel_balanced), "obs,",
    n_distinct(panel_balanced$ons_code), "LAs\n")
cat("  Balanced treated:", n_distinct(panel_balanced$ons_code[panel_balanced$ever_treated]), "\n")
cat("  Balanced never-treated:", n_distinct(panel_balanced$ons_code[!panel_balanced$ever_treated]), "\n")
cat("  Year range:", min(panel_balanced$year), "-", max(panel_balanced$year), "\n")

# Summary statistics
cat("\n  Summary statistics:\n")
summary_stats <- panel_balanced %>%
  filter(year >= 2004, year <= 2024) %>%
  group_by(ever_treated) %>%
  summarise(
    n_la = n_distinct(ons_code),
    mean_ltv = mean(long_term_vacant, na.rm = TRUE),
    sd_ltv = sd(long_term_vacant, na.rm = TRUE),
    mean_log_ltv = mean(log_ltv, na.rm = TRUE),
    mean_av = mean(all_vacant, na.rm = TRUE),
    mean_ltv_share = mean(ltv_share, na.rm = TRUE),
    .groups = "drop"
  )
print(summary_stats)

# Save
saveRDS(panel_balanced, file.path(data_dir, "analysis_panel.rds"))
saveRDS(panel, file.path(data_dir, "full_panel.rds"))
saveRDS(treatment, file.path(data_dir, "treatment.rds"))

cat("\nData cleaning complete.\n")
