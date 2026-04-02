# 02_clean_data.R — Construct analysis panel
# APEP-1310: The Compression Shock

source("00_packages.R")

# ── Load raw data ───────────────────────────────────────────────
emp_raw <- readRDS("../data/emp_raw.rds")
wage_raw <- readRDS("../data/wage_raw.rds")
mw_raw <- readRDS("../data/mw_raw.rds")

# ── Clean employment data ───────────────────────────────────────
emp <- emp_raw %>%
  filter(
    sex == "SEX_T",
    grepl("^ECO_ISIC4_[A-U]$", classif1)
  ) %>%
  mutate(
    country = ref_area_fetched,
    year = as.integer(time),
    sector = gsub("ECO_ISIC4_", "", classif1),
    employment = as.numeric(obs_value)
  ) %>%
  filter(year >= 2013 & year <= 2023, !is.na(employment)) %>%
  select(country, year, sector, employment)

cat("Employment panel rows:", nrow(emp), "\n")
cat("Countries:", paste(unique(emp$country), collapse = ", "), "\n")
cat("Employment sectors:", paste(sort(unique(emp$sector)), collapse = ", "), "\n")
cat("Years:", paste(range(emp$year), collapse = "-"), "\n")

# ── Clean wage data ─────────────────────────────────────────────
wage <- wage_raw %>%
  filter(
    sex == "SEX_T",
    grepl("^ECO_ISIC4_[A-U]$", classif1),
    classif2 == "CUR_TYPE_LCU"  # Local currency (EUR for Baltics)
  ) %>%
  mutate(
    country = ref_area_fetched,
    year = as.integer(time),
    sector = gsub("ECO_ISIC4_", "", classif1),
    mean_wage = as.numeric(obs_value)
  ) %>%
  filter(year >= 2013 & year <= 2023, !is.na(mean_wage), mean_wage > 0) %>%
  select(country, year, sector, mean_wage)

cat("\nWage panel rows:", nrow(wage), "\n")
cat("Wage sectors:", paste(sort(unique(wage$sector)), collapse = ", "), "\n")

# ── Identify common sectors ────────────────────────────────────
common_sectors <- intersect(unique(emp$sector), unique(wage$sector))
cat("\nCommon sectors:", paste(sort(common_sectors), collapse = ", "), "\n")
cat("N common:", length(common_sectors), "\n")

emp <- emp %>% filter(sector %in% common_sectors)
wage <- wage %>% filter(sector %in% common_sectors)

# ── Clean minimum wage data ─────────────────────────────────────
geo_map <- c("LT" = "LTU", "LV" = "LVA", "EE" = "EST")

mw <- mw_raw %>%
  filter(currency == "EUR") %>%
  mutate(
    country = geo_map[geo],
    year = as.integer(substr(time, 1, 4))
  ) %>%
  filter(!is.na(country), !is.na(year)) %>%
  group_by(country, year) %>%
  summarise(min_wage = min(mw_value, na.rm = TRUE), .groups = "drop")

cat("\nMinimum wage panel:\n")
print(mw %>% pivot_wider(names_from = country, values_from = min_wage))

# ── Merge and construct Kaitz index ─────────────────────────────
panel <- emp %>%
  inner_join(wage, by = c("country", "year", "sector")) %>%
  left_join(mw, by = c("country", "year"))

panel <- panel %>%
  mutate(kaitz = min_wage / mean_wage)

cat("\nMerged panel rows:", nrow(panel), "\n")

# ── Pre-reform (2018) Kaitz index for Lithuania ─────────────────
kaitz_2018 <- panel %>%
  filter(country == "LTU", year == 2018) %>%
  select(sector, kaitz_2018 = kaitz)

cat("\n2018 Lithuania Kaitz indices:\n")
print(kaitz_2018 %>% arrange(desc(kaitz_2018)))

# Merge pre-reform Kaitz onto all observations
panel <- panel %>%
  left_join(kaitz_2018, by = "sector")

# ── Construct treatment variables ───────────────────────────────
panel <- panel %>%
  mutate(
    lt = as.integer(country == "LTU"),
    post2019 = as.integer(year >= 2019),
    treat_intensity = lt * post2019 * kaitz_2018,
    ln_emp = log(employment),
    cs = paste0(country, "_", sector),
    cy = paste0(country, "_", year)
  )

# ── ISIC4 sector labels ────────────────────────────────────────
sector_labels <- c(
  A = "Agriculture", B = "Mining", C = "Manufacturing",
  D = "Utilities", E = "Water/Waste", F = "Construction",
  G = "Retail/Wholesale", H = "Transport", I = "Accommodation/Food",
  J = "ICT", K = "Finance", L = "Real Estate",
  M = "Professional Services", N = "Administrative Services",
  O = "Public Admin", P = "Education", Q = "Health",
  R = "Arts/Entertainment", S = "Other Services",
  T = "Households as Employers", U = "Extraterritorial"
)
panel$sector_label <- sector_labels[panel$sector]

# ── Drop sectors with missing Kaitz ─────────────────────────────
n_before <- nrow(panel)
panel <- panel %>% filter(!is.na(kaitz_2018))
cat("\nDropped", n_before - nrow(panel), "rows with missing 2018 Kaitz\n")

# ── Summary ─────────────────────────────────────────────────────
cat("\nFinal panel:\n")
cat("  Rows:", nrow(panel), "\n")
cat("  Countries:", length(unique(panel$country)), "\n")
cat("  Sectors:", length(unique(panel$sector)), "\n")
cat("  Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("  Country-sector units:", length(unique(panel$cs)), "\n")

# Verify all 3 countries present
stopifnot(length(unique(panel$country)) == 3)
stopifnot(nrow(panel) > 100)

# ── Save ────────────────────────────────────────────────────────
saveRDS(panel, "../data/panel.rds")
cat("\nPanel saved to data/panel.rds\n")
