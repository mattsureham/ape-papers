# =============================================================================
# 02_clean_data.R — Construct analysis dataset
# apep_0643: PFL Border County Pairs
# =============================================================================

source("00_packages.R")

qwi_sa <- readRDS("../data/qwi_sa_border.rds")
qwi_ind <- readRDS("../data/qwi_ind_border.rds")
qwi_se <- readRDS("../data/qwi_se_border.rds")
border_pairs <- readRDS("../data/border_pairs.rds")
pfl_waves <- readRDS("../data/pfl_waves.rds")

# ---- Create Year-Quarter Variable ----
add_yq <- function(df) {
  df %>%
    mutate(
      fips = str_pad(as.character(geography), 5, pad = "0"),
      state_fips = as.integer(substr(fips, 1, 2)),
      yq = year + (quarter - 1) / 4,
      yq_str = paste0(year, "Q", quarter)
    )
}

qwi_sa <- add_yq(qwi_sa)
qwi_ind <- add_yq(qwi_ind)
qwi_se <- add_yq(qwi_se)

# ---- Treatment Quarter Mapping ----
treat_quarters <- c(
  NJ = 2009 + 2/4,   # 2009Q3 (July 2009)
  NY = 2018 + 0/4,   # 2018Q1 (January 2018)
  WA = 2020 + 0/4    # 2020Q1 (January 2020)
)

# ---- Build Stacked Panel ----
# For each wave: assign treated/control status, create event time,
# create county-pair identifiers

build_wave_panel <- function(qwi_df, wave_name, pairs_df, treat_yq,
                             pre_quarters = 12, post_quarters = 16) {
  # Filter to this wave's pairs
  wave_pairs <- pairs_df %>% filter(wave == wave_name)
  treated_counties <- unique(wave_pairs$treated_fips)
  control_counties <- unique(wave_pairs$control_fips)
  all_wave_counties <- c(treated_counties, control_counties)

  # Filter QWI to these counties
  wave_qwi <- qwi_df %>%
    filter(fips %in% all_wave_counties)

  if (nrow(wave_qwi) == 0) return(NULL)

  # Add treatment indicator
  wave_qwi <- wave_qwi %>%
    mutate(
      treated = as.integer(fips %in% treated_counties),
      event_time = round((yq - treat_yq) * 4),  # quarters relative to treatment
      post = as.integer(yq >= treat_yq),
      wave = wave_name,
      treat_yq_val = treat_yq
    )

  # Filter to event window
  wave_qwi <- wave_qwi %>%
    filter(event_time >= -pre_quarters & event_time <= post_quarters)

  # Create county-pair identifiers
  # Each treated county is paired with all adjacent control counties
  # For the stacked regression, we use the minimum pair_id approach:
  # each observation gets a pair_id based on closest pair
  pair_map <- wave_pairs %>%
    mutate(pair_id = paste0(wave_name, "_", row_number()))

  # For treated counties: duplicate for each pair they belong to
  treated_qwi <- wave_qwi %>%
    filter(treated == 1) %>%
    inner_join(pair_map %>% select(treated_fips, pair_id),
               by = c("fips" = "treated_fips"),
               relationship = "many-to-many")

  # For control counties: duplicate for each pair they belong to
  control_qwi <- wave_qwi %>%
    filter(treated == 0) %>%
    inner_join(pair_map %>% select(control_fips, pair_id),
               by = c("fips" = "control_fips"),
               relationship = "many-to-many")

  bind_rows(treated_qwi, control_qwi)
}

# Build stacked panel for all-industry (sex = 1 for male, sex = 2 for female)
cat("Building stacked panel for all-industry data...\n")
stacked_panels <- list()
for (wn in names(pfl_waves)) {
  cat(sprintf("  Processing wave %s...\n", wn))
  panel <- build_wave_panel(qwi_sa, wn, border_pairs, treat_quarters[wn])
  if (!is.null(panel)) {
    stacked_panels[[wn]] <- panel
    cat(sprintf("    %d rows, %d counties, event time [%d, %d]\n",
                nrow(panel), n_distinct(panel$fips),
                min(panel$event_time), max(panel$event_time)))
  }
}

stacked_all <- bind_rows(stacked_panels)
cat(sprintf("\nStacked all-industry panel: %d rows, %d unique counties, %d pairs\n",
            nrow(stacked_all), n_distinct(stacked_all$fips),
            n_distinct(stacked_all$pair_id)))

# ---- Build Industry-Specific Panel (Female Only) ----
cat("\nBuilding industry-specific stacked panel...\n")
stacked_ind_panels <- list()
for (wn in names(pfl_waves)) {
  panel <- build_wave_panel(qwi_ind, wn, border_pairs, treat_quarters[wn])
  if (!is.null(panel)) {
    stacked_ind_panels[[wn]] <- panel
  }
}
stacked_ind <- bind_rows(stacked_ind_panels)
cat(sprintf("Industry panel: %d rows\n", nrow(stacked_ind)))

# ---- Build Education Panel (Female Only) ----
cat("\nBuilding education stacked panel...\n")
stacked_edu_panels <- list()
for (wn in names(pfl_waves)) {
  panel <- build_wave_panel(qwi_se, wn, border_pairs, treat_quarters[wn])
  if (!is.null(panel)) {
    stacked_edu_panels[[wn]] <- panel
  }
}
stacked_edu <- bind_rows(stacked_edu_panels)
cat(sprintf("Education panel: %d rows\n", nrow(stacked_edu)))

# ---- Create Key Variables ----
# Log transformations for employment and earnings
transform_outcomes <- function(df) {
  df %>%
    mutate(
      ln_emp = ifelse(Emp > 0, log(Emp), NA_real_),
      ln_earn = ifelse(EarnS > 0, log(EarnS), NA_real_),
      ln_hir = ifelse(HirA > 0, log(HirA), NA_real_),
      ln_sep = ifelse(Sep > 0, log(Sep), NA_real_),
      ln_frmjbgn = ifelse(FrmJbGn > 0, log(FrmJbGn), NA_real_),
      ln_frmjbls = ifelse(FrmJbLs > 0, log(FrmJbLs), NA_real_),
      hire_rate = ifelse(Emp > 0, HirA / Emp, NA_real_),
      sep_rate = ifelse(Emp > 0, Sep / Emp, NA_real_),
      net_flow = HirA - Sep,
      net_flow_rate = ifelse(Emp > 0, (HirA - Sep) / Emp, NA_real_),
      turnover_rate = ifelse(Emp > 0, TurnOvrS / Emp, NA_real_)
    )
}

stacked_all <- transform_outcomes(stacked_all)
stacked_ind <- transform_outcomes(stacked_ind)
stacked_edu <- transform_outcomes(stacked_edu)

# ---- Summary Statistics ----
cat("\n=== Summary: Female All-Industry ===\n")
female_all <- stacked_all %>% filter(sex == 2)
cat(sprintf("N observations: %d\n", nrow(female_all)))
cat(sprintf("N counties: %d\n", n_distinct(female_all$fips)))
cat(sprintf("N treated counties: %d\n", n_distinct(female_all$fips[female_all$treated == 1])))
cat(sprintf("N control counties: %d\n", n_distinct(female_all$fips[female_all$treated == 0])))
cat(sprintf("N pairs: %d\n", n_distinct(female_all$pair_id)))
cat(sprintf("N waves: %d\n", n_distinct(female_all$wave)))
cat(sprintf("Mean employment (treated): %.0f\n", mean(female_all$Emp[female_all$treated == 1], na.rm = TRUE)))
cat(sprintf("Mean employment (control): %.0f\n", mean(female_all$Emp[female_all$treated == 0], na.rm = TRUE)))
cat(sprintf("Mean earnings (treated): $%.0f\n", mean(female_all$EarnS[female_all$treated == 1], na.rm = TRUE)))
cat(sprintf("Mean earnings (control): $%.0f\n", mean(female_all$EarnS[female_all$treated == 0], na.rm = TRUE)))

# ---- Save Analysis Datasets ----
saveRDS(stacked_all, "../data/stacked_all.rds")
saveRDS(stacked_ind, "../data/stacked_ind.rds")
saveRDS(stacked_edu, "../data/stacked_edu.rds")

cat("\nAnalysis datasets saved.\n")
