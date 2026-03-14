## 02_clean_data.R — Clean and prepare analysis dataset
## apep_0670: Comment Period Length and Public Participation

source("00_packages.R")

cat("=== Loading and cleaning data ===\n")

df_rules <- read_csv("../data/federal_register_proposed_rules.csv", show_col_types = FALSE)
cat(sprintf("Raw rules: %d\n", nrow(df_rules)))

# --- Clean ---
df_clean <- df_rules |>
  filter(
    !is.na(comment_days),
    comment_days >= 10,
    comment_days <= 180,
    !is.na(reg_gov_comments),
    !is.na(pub_date),
    year >= 2010, year <= 2023
  ) |>
  mutate(
    # Comment variables
    total_comments = reg_gov_comments,
    log_comments = log(pmax(total_comments, 1)),
    has_comments = total_comments > 0,

    # Period bins
    period_bin = case_when(
      comment_days < 30 ~ "Below APA floor",
      comment_days == 30 ~ "At APA floor (30d)",
      comment_days %in% 31:45 ~ "31-45 days",
      comment_days %in% 46:60 ~ "46-60 days",
      comment_days %in% 61:90 ~ "61-90 days",
      TRUE ~ "Over 90 days"
    ),
    period_bin = factor(period_bin, levels = c(
      "Below APA floor", "At APA floor (30d)",
      "31-45 days", "46-60 days", "61-90 days", "Over 90 days"
    )),

    # Controls
    log_pages = log(pmax(page_length, 1)),
    is_significant = coalesce(significant, FALSE),

    # Agency top categories
    agency_top = case_when(
      grepl("Environmental Protection", agency_name) ~ "EPA",
      grepl("Health and Human Services|Centers for Medicare|Food and Drug", agency_name) ~ "HHS/FDA",
      grepl("Transportation|Federal Aviation|Federal Highway|Federal Motor|National Highway", agency_name) ~ "DOT",
      grepl("Interior|Fish and Wildlife|National Park|Bureau of", agency_name) ~ "DOI",
      grepl("Agriculture|Food Safety|Forest Service", agency_name) ~ "USDA",
      grepl("Labor|Occupational Safety|Mine Safety|Wage and Hour", agency_name) ~ "DOL",
      grepl("Energy", agency_name) ~ "DOE",
      grepl("Treasury|Internal Revenue|Comptroller|Financial", agency_name) ~ "Treasury",
      grepl("Commerce|National Oceanic|Patent", agency_name) ~ "DOC",
      grepl("Defense", agency_name) ~ "DOD",
      grepl("Securities|Exchange Commission", agency_name) ~ "SEC",
      grepl("Federal Communications", agency_name) ~ "FCC",
      grepl("Coast Guard|Homeland Security|Customs", agency_name) ~ "DHS",
      TRUE ~ "Other"
    ),

    # RD variables
    above_30 = comment_days > 30,
    dist_30 = comment_days - 30
  )

cat(sprintf("Analysis sample: %d rules\n", nrow(df_clean)))
cat(sprintf("  With comments: %d (%.1f%%)\n",
            sum(df_clean$has_comments), 100 * mean(df_clean$has_comments)))

# --- Summary Statistics ---
cat("\n=== Summary Statistics ===\n")

cat("\nFull sample:\n")
df_clean |>
  summarise(
    N = n(),
    mean_days = mean(comment_days),
    sd_days = sd(comment_days),
    mean_pages = mean(page_length, na.rm = TRUE),
    mean_comments = mean(total_comments),
    median_comments = median(total_comments),
    pct_zero = 100 * mean(total_comments == 0),
    pct_significant = 100 * mean(is_significant)
  ) |>
  print()

cat("\nBy period bin:\n")
df_clean |>
  group_by(period_bin) |>
  summarise(
    n = n(),
    mean_comments = mean(total_comments),
    median_comments = median(total_comments),
    pct_zero = sprintf("%.1f%%", 100 * mean(total_comments == 0)),
    mean_pages = round(mean(page_length, na.rm = TRUE), 1),
    .groups = "drop"
  ) |>
  print()

cat("\nTop agencies:\n")
df_clean |>
  count(agency_top, sort = TRUE) |>
  mutate(pct = sprintf("%.1f%%", 100 * n / sum(n))) |>
  head(10) |>
  print()

# --- Save ---
write_csv(df_clean, "../data/rules_analysis.csv")

# Diagnostics for validator
diagnostics <- list(
  n_treated = as.integer(sum(df_clean$above_30)),
  n_pre = as.integer(length(unique(df_clean$year[df_clean$year < 2015]))),
  n_obs = as.integer(nrow(df_clean))
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nSaved rules_analysis.csv (%d rows)\n", nrow(df_clean)))
cat("=== Cleaning complete ===\n")
