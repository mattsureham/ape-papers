# 02_clean_data.R — Clean and construct variables
# apep_0710: Ukraine ProZorro Procurement Thresholds

source("00_packages.R")

# ── Load raw data ─────────────────────────────────────────────────
df_raw <- read_csv("../data/prozorro_tenders.csv", show_col_types = FALSE)
cat("Raw observations:", nrow(df_raw), "\n")

stopifnot("value_uah" %in% names(df_raw))
stopifnot(nrow(df_raw) > 100)  # Fail loudly if data is missing

# ── Construct running variable ────────────────────────────────────
df <- df_raw %>%
  filter(!is.na(value_uah)) %>%
  mutate(
    # Running variable: centered at threshold
    running = value_uah - 200000,

    # Above threshold indicator
    above = as.integer(value_uah > 200000),

    # Post-invasion indicator (Feb 24, 2022)
    post = as.integer(date >= "2022-02-24"),

    # Frontline oblast indicator
    frontline = as.integer(is_frontline == 1),

    # Clean savings rate
    savings_pct = ifelse(!is.na(savings_rate) & savings_rate >= -1 & savings_rate <= 1,
                         savings_rate * 100, NA),

    # Year-quarter for panel
    quarter = paste0(year, "Q", ceiling(month / 3)),

    # Period labels for tables
    period = case_when(
      year < 2022 ~ "Pre-war (2017-2021)",
      TRUE ~ "Post-war (2022-2024)"
    ),

    # Oblast group
    oblast_group = case_when(
      frontline == 1 ~ "Frontline",
      TRUE ~ "Rear"
    )
  )

cat("Cleaned observations:", nrow(df), "\n")
cat("Above threshold:", sum(df$above), "\n")
cat("Below threshold:", sum(df$above == 0), "\n")
cat("Pre-war:", sum(df$post == 0), "\n")
cat("Post-war:", sum(df$post == 1), "\n")
cat("Frontline:", sum(df$frontline == 1), "\n")
cat("Rear:", sum(df$frontline == 0), "\n")
cat("Oblasts:", length(unique(df$region_en)), "\n")
cat("Year range:", range(df$year), "\n")

# ── Save cleaned data ─────────────────────────────────────────────
write_csv(df, "../data/prozorro_clean.csv")
saveRDS(df, "../data/prozorro_clean.rds")

cat("Cleaned data saved.\n")
