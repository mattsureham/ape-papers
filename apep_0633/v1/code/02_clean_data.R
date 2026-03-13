## 02_clean_data.R — Parse Census school finance Excel files and build panel
## apep_0633: Marijuana tax earmarking and education spending fungibility

source("00_packages.R")

data_dir <- "../data/"

## ──────────────────────────────────────────────────
## 1. Parse Sheet 1 from each year's Census file
## ──────────────────────────────────────────────────

# Sheet 1 structure (consistent across years):
# col 1: State name (with trailing dots)
# col 3: Total revenue (thousands)
# col 4: Federal revenue (thousands)
# col 5: State revenue (thousands)
# col 6: Local revenue (thousands)
# col 7: Total expenditure (thousands)
# col 8: Current spending (thousands)
# col 9: Capital outlay (thousands)

clean_state_name <- function(x) {
  x <- str_replace_all(x, "\\.*$", "")  # remove trailing dots
  x <- str_replace_all(x, "\\.+", " ")   # replace internal dots with spaces
  str_trim(x)
}

# State name to abbreviation lookup
state_lookup <- tibble(
  state_name = c(state.name, "District of Columbia"),
  state_abbr = c(state.abb, "DC")
)

parse_sheet1 <- function(filepath, year) {
  # Try reading sheet "1" with various skip values
  for (skip_n in c(7, 8, 6, 9)) {
    df <- tryCatch(
      read_excel(filepath, sheet = "1", skip = skip_n, col_names = FALSE,
                 col_types = "text"),
      error = function(e) NULL
    )
    if (is.null(df)) next

    # Find rows with state names (contain at least one letter and dots)
    df <- df %>%
      mutate(state_raw = ...1) %>%
      filter(!is.na(state_raw),
             str_detect(state_raw, "[A-Za-z]"),
             !str_detect(state_raw, "^Table|^\\(|^Source|^Note|^See|^1 |^2 |^3 |^X"))

    # Clean state names
    df <- df %>%
      mutate(state_clean = clean_state_name(state_raw))

    # Match to state abbreviations
    df <- df %>%
      left_join(state_lookup, by = c("state_clean" = "state_name")) %>%
      filter(!is.na(state_abbr))

    if (nrow(df) >= 45) {
      # Extract numeric columns
      result <- df %>%
        transmute(
          state_abbr,
          year = year,
          total_rev    = as.numeric(...3),
          federal_rev  = as.numeric(...4),
          state_rev    = as.numeric(...5),
          local_rev    = as.numeric(...6),
          total_exp    = as.numeric(...7),
          current_exp  = as.numeric(...8),
          capital_exp  = as.numeric(...9)
        ) %>%
        filter(!is.na(total_rev))

      cat(sprintf("  %d: %d states parsed (skip=%d)\n", year, nrow(result), skip_n))
      return(result)
    }
  }

  cat(sprintf("  %d: FAILED to parse\n", year))
  return(NULL)
}

cat("Parsing Census school finance data...\n")

years <- 2008:2022
finance_list <- list()

for (yr in years) {
  yy <- sprintf("%02d", yr %% 100)
  filepath <- file.path(data_dir, sprintf("elsec%s.xls", yy))
  if (file.exists(filepath)) {
    finance_list[[as.character(yr)]] <- parse_sheet1(filepath, yr)
  }
}

finance_panel <- bind_rows(finance_list)
cat(sprintf("\nFinance panel: %d state-year observations\n", nrow(finance_panel)))
cat(sprintf("States: %d | Years: %d\n",
            n_distinct(finance_panel$state_abbr),
            n_distinct(finance_panel$year)))

## ──────────────────────────────────────────────────
## 2. Parse enrollment from Sheet 19 (or estimate from per-pupil)
## ──────────────────────────────────────────────────

# Sheet 19 has enrollment but format varies. Use a simpler approach:
# NCES Common Core of Data state-level enrollment is more reliable.
# For now, approximate enrollment from per-pupil current spending (Sheet 20)
# and total current spending (Sheet 1).

# Sheet 20: Per Pupil Current Spending Amounts
parse_perpupil <- function(filepath, year) {
  # Sheet 20 or the sheet with "Per Pupil Current Spending"
  # Try different sheet names/numbers
  for (sheet_name in c("20", "19", "8")) {
    df <- tryCatch(
      read_excel(filepath, sheet = sheet_name, skip = 6, col_names = FALSE,
                 col_types = "text"),
      error = function(e) NULL
    )
    if (is.null(df)) next

    df <- df %>%
      mutate(state_raw = ...1) %>%
      filter(!is.na(state_raw),
             str_detect(state_raw, "[A-Za-z]"),
             !str_detect(state_raw, "^Table|^\\(|^Source|^Note|^See|^1 |^2 |^3 |^X|^Per|^Pop"))

    df <- df %>%
      mutate(state_clean = clean_state_name(state_raw)) %>%
      left_join(state_lookup, by = c("state_clean" = "state_name")) %>%
      filter(!is.na(state_abbr))

    if (nrow(df) >= 45) {
      # Check if col 3 looks like per-pupil spending (typically $5,000-$30,000)
      test_val <- as.numeric(df$...3[1])
      if (!is.na(test_val) && test_val > 3000 && test_val < 50000) {
        result <- df %>%
          transmute(
            state_abbr,
            year = year,
            ppcs = as.numeric(...3)  # per pupil current spending
          ) %>%
          filter(!is.na(ppcs))
        return(result)
      }
    }
  }
  return(NULL)
}

cat("\nParsing per-pupil current spending...\n")
ppcs_list <- list()
for (yr in years) {
  yy <- sprintf("%02d", yr %% 100)
  filepath <- file.path(data_dir, sprintf("elsec%s.xls", yy))
  if (file.exists(filepath)) {
    result <- parse_perpupil(filepath, yr)
    if (!is.null(result)) {
      ppcs_list[[as.character(yr)]] <- result
      cat(sprintf("  %d: %d states\n", yr, nrow(result)))
    } else {
      cat(sprintf("  %d: no per-pupil data found\n", yr))
    }
  }
}

if (length(ppcs_list) > 0) {
  ppcs_panel <- bind_rows(ppcs_list)
  cat(sprintf("\nPer-pupil panel: %d observations\n", nrow(ppcs_panel)))
} else {
  cat("WARNING: No per-pupil data parsed from any year\n")
  ppcs_panel <- tibble(state_abbr = character(), year = integer(), ppcs = numeric())
}

## ──────────────────────────────────────────────────
## 3. Compute enrollment and per-pupil amounts
## ──────────────────────────────────────────────────

# Enrollment = total current spending / per-pupil current spending
# Then compute per-pupil revenue and expenditure

panel <- finance_panel %>%
  left_join(ppcs_panel, by = c("state_abbr", "year"))

if (any(!is.na(panel$ppcs))) {
  panel <- panel %>%
    mutate(
      enrollment = if_else(!is.na(ppcs) & ppcs > 0,
                           current_exp * 1000 / ppcs,  # current_exp is in thousands
                           NA_real_),
      rev_pp     = total_rev * 1000 / enrollment,
      fed_rev_pp = federal_rev * 1000 / enrollment,
      st_rev_pp  = state_rev * 1000 / enrollment,
      loc_rev_pp = local_rev * 1000 / enrollment,
      exp_pp     = total_exp * 1000 / enrollment,
      cur_exp_pp = ppcs,   # this IS per-pupil current spending
      cap_exp_pp = capital_exp * 1000 / enrollment
    )
} else {
  # Fallback: use log of total amounts (with state FE to absorb levels)
  cat("WARNING: Using log total amounts instead of per-pupil\n")
  panel <- panel %>%
    mutate(
      enrollment = NA_real_,
      rev_pp = log(total_rev),
      exp_pp = log(total_exp)
    )
}

## ──────────────────────────────────────────────────
## 4. Merge treatment data
## ──────────────────────────────────────────────────

treatment <- read_csv(file.path(data_dir, "treatment_data.csv"), show_col_types = FALSE)

# All states panel — never-treated states get treatment_year = 0 for CS-DiD
all_states <- panel %>%
  select(state_abbr) %>%
  distinct() %>%
  left_join(treatment %>% select(state_abbr, treatment_year, earmark_education),
            by = "state_abbr") %>%
  mutate(
    treatment_year = replace_na(treatment_year, 0),  # 0 = never treated (CS-DiD convention)
    earmark_education = replace_na(earmark_education, FALSE),
    treated = treatment_year > 0
  )

panel <- panel %>%
  left_join(all_states, by = "state_abbr") %>%
  mutate(
    post = year >= treatment_year & treatment_year > 0,
    rel_year = if_else(treatment_year > 0, year - treatment_year, NA_integer_)
  )

## ──────────────────────────────────────────────────
## 5. Merge marijuana revenue data
## ──────────────────────────────────────────────────

mj_rev <- read_csv(file.path(data_dir, "mj_revenue.csv"), show_col_types = FALSE)

panel <- panel %>%
  left_join(mj_rev, by = c("state_abbr", "year")) %>%
  mutate(mj_tax_revenue_m = replace_na(mj_tax_revenue_m, 0))

# Compute marijuana revenue per pupil (in dollars)
panel <- panel %>%
  mutate(
    mj_rev_pp = if_else(!is.na(enrollment) & enrollment > 0,
                        mj_tax_revenue_m * 1e6 / enrollment,
                        NA_real_)
  )

## ──────────────────────────────────────────────────
## 6. Summary statistics and validation
## ──────────────────────────────────────────────────

cat("\n=== Panel Summary ===\n")
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("States: %d\n", n_distinct(panel$state_abbr)))
cat(sprintf("Years: %d (%d-%d)\n", n_distinct(panel$year), min(panel$year), max(panel$year)))
cat(sprintf("Treated states: %d\n", sum(all_states$treated)))
cat(sprintf("Never-treated: %d\n", sum(!all_states$treated)))
cat(sprintf("Earmark education: %d\n", sum(all_states$earmark_education)))

cat("\nPer-pupil outcome coverage:\n")
cat(sprintf("  rev_pp non-NA: %d (%.0f%%)\n",
            sum(!is.na(panel$rev_pp)), 100 * mean(!is.na(panel$rev_pp))))
cat(sprintf("  exp_pp non-NA: %d (%.0f%%)\n",
            sum(!is.na(panel$exp_pp)), 100 * mean(!is.na(panel$exp_pp))))

if (any(!is.na(panel$rev_pp))) {
  cat(sprintf("\nPer-pupil total revenue: mean=$%.0f, sd=$%.0f\n",
              mean(panel$rev_pp, na.rm = TRUE), sd(panel$rev_pp, na.rm = TRUE)))
  cat(sprintf("Per-pupil total expenditure: mean=$%.0f, sd=$%.0f\n",
              mean(panel$exp_pp, na.rm = TRUE), sd(panel$exp_pp, na.rm = TRUE)))
}

# Validate: check a known state
co <- panel %>% filter(state_abbr == "CO")
cat(sprintf("\nColorado validation:\n"))
cat(sprintf("  Treatment year: %d\n", unique(co$treatment_year)))
cat(sprintf("  Pre-treatment years: %d\n", sum(co$year < unique(co$treatment_year))))
cat(sprintf("  Post-treatment years: %d\n", sum(co$year >= unique(co$treatment_year))))
if (any(!is.na(co$rev_pp))) {
  cat(sprintf("  Mean rev_pp pre: $%.0f\n",
              mean(co$rev_pp[co$year < unique(co$treatment_year)], na.rm = TRUE)))
  cat(sprintf("  Mean rev_pp post: $%.0f\n",
              mean(co$rev_pp[co$year >= unique(co$treatment_year)], na.rm = TRUE)))
}

## ──────────────────────────────────────────────────
## 7. Save panel
## ──────────────────────────────────────────────────

write_csv(panel, file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("\nPanel saved: %s\n", file.path(data_dir, "analysis_panel.csv")))
cat("=== Data cleaning complete ===\n")
