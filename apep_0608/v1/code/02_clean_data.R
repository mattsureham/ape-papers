## 02_clean_data.R — Clean and prepare analysis dataset
## apep_0608: Japan Women's Participation Disclosure RDD

source("00_packages.R")

data_dir <- "../data"
df <- readRDS(file.path(data_dir, "mhlw_selected.rds"))

cat("Raw data:", nrow(df), "firms\n")

## ---- 1. Parse firm size into numeric midpoints ----
# Firm size categories: 10人未満, 10～100人, 101～300人, 301～500人,
#                       501～1000人, 1001～5000人, 5001人以上
df <- df %>%
  mutate(
    size_cat = case_when(
      str_detect(firm_size, "10人未満")     ~ "0-9",
      str_detect(firm_size, "10～100")      ~ "10-100",
      str_detect(firm_size, "101～300")     ~ "101-300",
      str_detect(firm_size, "301～500")     ~ "301-500",
      str_detect(firm_size, "501～1000")    ~ "501-1000",
      str_detect(firm_size, "1001～5000")   ~ "1001-5000",
      str_detect(firm_size, "5001人以上")   ~ "5001+",
      TRUE ~ NA_character_
    ),
    # Midpoint for parametric specifications
    size_midpoint = case_when(
      size_cat == "0-9"       ~ 5,
      size_cat == "10-100"    ~ 55,
      size_cat == "101-300"   ~ 200,
      size_cat == "301-500"   ~ 400,
      size_cat == "501-1000"  ~ 750,
      size_cat == "1001-5000" ~ 3000,
      size_cat == "5001+"     ~ 7500,
      TRUE ~ NA_real_
    ),
    # Treatment indicator: above the 301-employee threshold
    above_301 = as.integer(size_midpoint >= 301),
    # Centered running variable (midpoint - 301)
    size_centered = size_midpoint - 301
  )

cat("\nFirm size distribution:\n")
df %>% count(size_cat, above_301) %>% print(n = 20)

## ---- 2. Parse outcome variables ----
parse_pct <- function(x) {
  # Handle Japanese-style percentage strings
  x <- as.character(x)
  x <- str_replace_all(x, "[％%]", "")
  x <- str_trim(x)
  val <- suppressWarnings(as.numeric(x))
  # Cap at [0, 100] for percentage variables
  val <- ifelse(val < 0 | val > 100, NA_real_, val)
  return(val)
}

df <- df %>%
  mutate(
    # Female manager share (%)
    fem_manager = parse_pct(female_manager_pct),
    # Gender wage gap: female/male ratio (%)
    # Higher = more equal (100% = perfect parity)
    wage_gap = parse_pct(wage_gap_all),
    wage_gap_reg = parse_pct(wage_gap_regular),
    wage_gap_nonreg = parse_pct(wage_gap_nonreg),
    # Female section chief share (%)
    fem_section = parse_pct(female_section_pct),
    # Female board member share (%)
    fem_board = parse_pct(female_board_pct),
    # Disclosure indicators
    discloses_wage_gap = as.integer(!is.na(wage_gap)),
    discloses_manager  = as.integer(!is.na(fem_manager))
  )

## ---- 3. Create covariate indicators ----
df <- df %>%
  mutate(
    # Listed company indicator
    is_listed = as.integer(!is.na(market) & market != "" & market != "非上場"),
    # Industry dummies (top-level)
    industry_clean = ifelse(is.na(industry) | industry == "", "Unknown", industry)
  )

cat("\nOutcome variable coverage by size category:\n")
df %>%
  filter(!is.na(size_cat)) %>%
  group_by(size_cat) %>%
  summarise(
    n = n(),
    pct_wage_gap = mean(discloses_wage_gap) * 100,
    pct_manager  = mean(discloses_manager) * 100,
    mean_wage_gap = mean(wage_gap, na.rm = TRUE),
    mean_fem_mgr  = mean(fem_manager, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print(n = 10)

## ---- 4. Analysis sample: firms around the threshold ----
# Primary sample: 101-300 vs 301-500 (adjacent bins)
df_primary <- df %>%
  filter(size_cat %in% c("101-300", "301-500"))

cat("\nPrimary analysis sample:", nrow(df_primary), "firms\n")
cat("  101-300:", sum(df_primary$size_cat == "101-300"), "\n")
cat("  301-500:", sum(df_primary$size_cat == "301-500"), "\n")

# Extended sample: all bins for parametric specifications
df_extended <- df %>%
  filter(!is.na(size_cat))

cat("Extended sample:", nrow(df_extended), "firms\n")

## ---- 5. First stage: disclosure compliance ----
cat("\n=== FIRST STAGE: Disclosure rates ===\n")
df_primary %>%
  group_by(size_cat) %>%
  summarise(
    n = n(),
    discloses_wage = mean(discloses_wage_gap) * 100,
    discloses_mgr  = mean(discloses_manager) * 100,
    .groups = "drop"
  ) %>%
  print()

## ---- 6. Save analysis datasets ----
saveRDS(df_primary, file.path(data_dir, "analysis_primary.rds"))
saveRDS(df_extended, file.path(data_dir, "analysis_extended.rds"))
saveRDS(df, file.path(data_dir, "analysis_full.rds"))

cat("\nSaved analysis datasets.\n")
cat("Primary sample (101-300 vs 301-500):", nrow(df_primary), "firms\n")
cat("Extended sample (all categories):", nrow(df_extended), "firms\n")
