## 02_clean_data.R — Parse HDT scores and PS2 planning data, construct analysis panel
## apep_0686: UK Housing Delivery Test RDD

source("code/00_packages.R")

data_dir <- "data"

## ============================================================
## PART 1: Parse HDT Measurement Files
## ============================================================

## Key insight from data inspection:
## - All files store HDT scores as RATIOS (e.g., 0.81 = 81%)
## - Measurement column position varies: col 11 for most, col 13 for 2019
## - Find consequence column by looking for "Buffer"/"None"/"Presumption" in first data row
## - Measurement column is immediately before consequence column
##
## IMPORTANT: The 75% threshold for "presumption in favour" was PHASED IN:
##   2018: 25% threshold → Presumption
##   2019: 45% threshold → Presumption
##   2020 onwards: 75% threshold → Presumption
## For our RDD at 75%, we use ONLY the 2020-2023 rounds.

parse_hdt <- function(year) {
  ext <- ifelse(year %in% c("2018", "2019"), "xlsx", "ods")
  fpath <- file.path(data_dir, paste0("hdt_", year, ".", ext))

  if (ext == "xlsx") {
    raw <- readxl::read_excel(fpath, sheet = 1, col_names = FALSE, col_types = "text")
  } else {
    raw <- readODS::read_ods(fpath, sheet = 1, col_names = FALSE)
    raw <- data.frame(lapply(raw, as.character), stringsAsFactors = FALSE)
  }

  ## Find data start (first row with E0 code in column 1)
  data_start <- NA
  for (i in 1:15) {
    if (grepl("^E0", as.character(raw[i, 1]))) {
      data_start <- i
      break
    }
  }
  if (is.na(data_start)) stop(sprintf("FATAL: No data rows found in HDT %s", year))

  ## Find consequence column by scanning first data row for known consequence values
  first_data <- unlist(raw[data_start, ])
  consequence_values <- c("Buffer", "None", "Presumption", "Action Plan", "Action plan",
                          "Transitional arrangements did not apply")
  cons_col <- which(first_data %in% consequence_values)
  if (length(cons_col) == 0) {
    ## Try second data row
    second_data <- unlist(raw[data_start + 1, ])
    cons_col <- which(second_data %in% consequence_values)
  }
  if (length(cons_col) == 0) stop(sprintf("FATAL: Cannot find consequence column in HDT %s", year))
  cons_col <- cons_col[1]
  meas_col <- cons_col - 1  ## Measurement is always immediately before consequence

  ## Extract data
  dat <- raw[data_start:nrow(raw), ]

  out <- tibble(
    la_code = as.character(dat[[1]]),
    la_name = as.character(dat[[2]]),
    hdt_score_ratio = as.numeric(dat[[meas_col]]),
    consequence = as.character(dat[[cons_col]])
  ) %>%
    filter(!is.na(la_code), la_code != "", grepl("^E", la_code)) %>%
    mutate(
      hdt_year = as.integer(year),
      ## Convert ratio to percentage
      hdt_score = hdt_score_ratio * 100
    ) %>%
    filter(!is.na(hdt_score))

  cat(sprintf("HDT %s: %d LAs, score range [%.0f%%, %.0f%%], below 75%%: %d, presumption: %d\n",
              year, nrow(out),
              min(out$hdt_score, na.rm = TRUE),
              max(out$hdt_score, na.rm = TRUE),
              sum(out$hdt_score < 75),
              sum(out$consequence == "Presumption", na.rm = TRUE)))

  return(out)
}

hdt_all <- map(c("2018", "2019", "2020", "2021", "2022", "2023"), parse_hdt)
hdt <- bind_rows(hdt_all)

cat(sprintf("\n=== Full HDT Panel: %d LA-year observations ===\n", nrow(hdt)))

## RESTRICT to 2020-2023 where the 75% threshold applies
hdt_rdd <- hdt %>%
  filter(hdt_year >= 2020)

cat(sprintf("=== RDD Panel (2020-2023): %d LA-year observations ===\n", nrow(hdt_rdd)))

## Create treatment indicator and running variable
hdt_rdd <- hdt_rdd %>%
  mutate(
    below_75 = as.integer(hdt_score < 75),
    running_var = hdt_score - 75  # Centered at cutoff
  )

## Summary by year
hdt_rdd %>%
  group_by(hdt_year) %>%
  summarise(
    n_las = n(),
    n_below_75 = sum(below_75),
    n_presumption = sum(consequence == "Presumption", na.rm = TRUE),
    mean_score = round(mean(hdt_score), 0),
    median_score = round(median(hdt_score), 0),
    .groups = "drop"
  ) %>%
  print()

## Also save 2018-2019 for pre-period placebo tests
hdt_pre <- hdt %>%
  filter(hdt_year %in% c(2018, 2019)) %>%
  mutate(
    below_75 = as.integer(hdt_score < 75),
    running_var = hdt_score - 75
  )

## ============================================================
## PART 2: Parse PS2 Planning Statistics
## ============================================================

cat("\nParsing PS2 planning statistics...\n")

## Read with proper header handling (skip first 2 metadata rows)
ps2 <- read_csv(file.path(data_dir, "ps2_full.csv"), skip = 2,
                show_col_types = FALSE, name_repair = "unique")
cat(sprintf("PS2: %d rows, %d columns\n", nrow(ps2), ncol(ps2)))

## Select key columns by position:
## 1=Region, 2=LPANM, 3=LPACD, 4=Quarter
## 5=Total decisions grand total (all), 6=Total granted grand total (all)
## 12=Total decisions major total, 13=Total granted major total, 14=Total refused major total
## 33=Total decisions major dwellings (all), 34=Total granted major dwellings (all)
## 111=Minor dwellings decisions, 112=Minor dwellings granted
## 194=Householder decisions, 195=Householder granted

ps2_clean <- ps2 %>%
  select(
    region = 1,
    la_name_ps2 = 2,
    la_code = 3,
    quarter = 4,
    all_decisions = 5,
    all_granted = 6,
    all_refused = 7,
    major_decisions = 12,
    major_granted = 13,
    major_refused = 14,
    major_dwell_decisions = 33,
    major_dwell_granted = 34,
    major_dwell_refused = 35,
    minor_dwell_decisions = 111,
    minor_dwell_granted = 112,
    householder_decisions = 194,
    householder_granted = 195
  ) %>%
  mutate(across(c(all_decisions:householder_granted), ~as.numeric(as.character(.)))) %>%
  filter(!is.na(la_code), la_code != "", grepl("^E", la_code))

## Parse quarter
ps2_clean <- ps2_clean %>%
  mutate(
    year = as.integer(str_extract(quarter, "\\d{4}")),
    qtr = as.integer(str_extract(quarter, "Q(\\d)", group = 1))
  ) %>%
  filter(!is.na(year), !is.na(qtr))

cat(sprintf("PS2 clean: %d rows, years %d-%d\n",
            nrow(ps2_clean), min(ps2_clean$year), max(ps2_clean$year)))

## ============================================================
## PART 3: Match HDT to Post-Publication PS2 Outcomes
## ============================================================

## HDT publication timeline (for 2020-2023 rounds):
## HDT 2020 → published Jan 2021 → consequence applies from Q1 2021 to ~Q4 2021
## HDT 2021 → published Jan 2022 → consequence applies from Q1 2022 to ~Q4 2023
## HDT 2022 → published Dec 2023 → consequence applies from Q1 2024 to ~Q4 2024
## HDT 2023 → published Dec 2024 → consequence applies from Q1 2025 onwards
##
## Strategy: for each HDT round, take the 4 quarters AFTER publication
## as the outcome window (when the consequence is in effect).

aggregate_ps2_for_window <- function(ps2_data, start_year, start_qtr, end_year, end_qtr) {
  ps2_data %>%
    mutate(yq = year + (qtr - 1) / 4) %>%
    filter(yq >= start_year + (start_qtr - 1) / 4,
           yq <= end_year + (end_qtr - 1) / 4) %>%
    group_by(la_code) %>%
    summarise(
      n_quarters = n(),
      all_decisions = sum(all_decisions, na.rm = TRUE),
      all_granted = sum(all_granted, na.rm = TRUE),
      major_decisions = sum(major_decisions, na.rm = TRUE),
      major_granted = sum(major_granted, na.rm = TRUE),
      major_dwell_decisions = sum(major_dwell_decisions, na.rm = TRUE),
      major_dwell_granted = sum(major_dwell_granted, na.rm = TRUE),
      minor_dwell_decisions = sum(minor_dwell_decisions, na.rm = TRUE),
      minor_dwell_granted = sum(minor_dwell_granted, na.rm = TRUE),
      householder_decisions = sum(householder_decisions, na.rm = TRUE),
      householder_granted = sum(householder_granted, na.rm = TRUE),
      .groups = "drop"
    )
}

## Define outcome windows for each HDT round
windows <- list(
  list(hdt_year = 2020, sy = 2021, sq = 1, ey = 2021, eq = 4),
  list(hdt_year = 2021, sy = 2022, sq = 1, ey = 2022, eq = 4),
  list(hdt_year = 2022, sy = 2024, sq = 1, ey = 2024, eq = 4),
  list(hdt_year = 2023, sy = 2025, sq = 1, ey = 2025, eq = 3)  # Latest available
)

ps2_by_round <- map_dfr(windows, function(w) {
  agg <- aggregate_ps2_for_window(ps2_clean, w$sy, w$sq, w$ey, w$eq)
  agg$hdt_year <- w$hdt_year
  agg
})

## Compute approval rates
ps2_by_round <- ps2_by_round %>%
  mutate(
    approval_rate_all = ifelse(all_decisions > 0, all_granted / all_decisions * 100, NA),
    approval_rate_major = ifelse(major_decisions > 0, major_granted / major_decisions * 100, NA),
    approval_rate_major_dwell = ifelse(major_dwell_decisions > 0,
                                       major_dwell_granted / major_dwell_decisions * 100, NA),
    approval_rate_householder = ifelse(householder_decisions > 0,
                                       householder_granted / householder_decisions * 100, NA)
  )

cat(sprintf("PS2 aggregated: %d LA-round observations\n", nrow(ps2_by_round)))

## ============================================================
## PART 4: Merge HDT + PS2 into Analysis Panel
## ============================================================

panel <- hdt_rdd %>%
  left_join(ps2_by_round, by = c("la_code", "hdt_year"))

cat(sprintf("\n=== Analysis Panel ===\n"))
cat(sprintf("  Total observations: %d\n", nrow(panel)))
cat(sprintf("  Matched with PS2: %d\n", sum(!is.na(panel$approval_rate_all))))
cat(sprintf("  Missing PS2: %d\n", sum(is.na(panel$approval_rate_all))))

## Drop observations with missing outcomes
panel <- panel %>%
  filter(!is.na(approval_rate_all))

cat(sprintf("  Final panel: %d\n", nrow(panel)))
cat(sprintf("  Below 75%%: %d (%d unique LAs)\n",
            sum(panel$below_75), n_distinct(panel$la_code[panel$below_75 == 1])))
cat(sprintf("  Above 75%%: %d (%d unique LAs)\n",
            sum(panel$below_75 == 0), n_distinct(panel$la_code[panel$below_75 == 0])))

## Observations near cutoff (within 15pp)
near_cutoff <- panel %>% filter(abs(running_var) <= 15)
cat(sprintf("  Within ±15pp of cutoff: %d\n", nrow(near_cutoff)))
cat(sprintf("  Within ±10pp of cutoff: %d\n", sum(abs(panel$running_var) <= 10)))

## Summary statistics
cat("\n=== Outcome Summary ===\n")
panel %>%
  group_by(below_75) %>%
  summarise(
    n = n(),
    mean_score = round(mean(hdt_score), 1),
    mean_approval_all = round(mean(approval_rate_all, na.rm = TRUE), 1),
    mean_approval_major = round(mean(approval_rate_major, na.rm = TRUE), 1),
    mean_approval_major_dwell = round(mean(approval_rate_major_dwell, na.rm = TRUE), 1),
    mean_approval_householder = round(mean(approval_rate_householder, na.rm = TRUE), 1),
    .groups = "drop"
  ) %>%
  print()

## Save
write_csv(panel, file.path(data_dir, "analysis_panel.csv"))
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))

## Also save full HDT for pre-period analysis
write_csv(hdt, file.path(data_dir, "hdt_all_years.csv"))
saveRDS(hdt_pre, file.path(data_dir, "hdt_pre.rds"))

cat("\nAnalysis panel and supplementary data saved.\n")
