## 02_clean_data.R — Construct analysis dataset
## apep_1022: Affirmative action bans and minority enrollment cascades

source("00_packages.R")

cat("=== Constructing analysis dataset ===\n")

## -------------------------------------------------------------------
## 1. Load raw data
## -------------------------------------------------------------------
ef_list <- readRDS("../data/ef_raw_list.rds")
hd_list <- readRDS("../data/hd_raw_list.rds")
adm_list <- readRDS("../data/adm_raw_list.rds")
acs_raw <- readRDS("../data/acs_demographics.rds")

## -------------------------------------------------------------------
## 2. Build institution panel from HD (directory) files
##    Identify public 4-year institutions
## -------------------------------------------------------------------
cat("Building institution panel...\n")

hd_panel <- lapply(names(hd_list), function(yr) {
  d <- hd_list[[yr]]
  # sector: 1 = public 4-year
  cols_need <- c("unitid", "instnm", "stabbr", "fips", "sector", "year")
  cols_have <- intersect(cols_need, names(d))
  # Some years have "obereg" or "iclevel" instead of sector
  if (!"sector" %in% names(d) && "iclevel" %in% names(d) && "control" %in% names(d)) {
    d$sector <- ifelse(d$iclevel == 1 & d$control == 1, 1, NA_real_)
  }
  if (all(c("unitid", "sector") %in% names(d))) {
    d[, intersect(c("unitid", "instnm", "stabbr", "fips", "sector", "year",
                     "carnegie", "c18basic", "c15basic"), names(d)), with = FALSE]
  }
}) %>% bind_rows()

# Keep only public 4-year institutions (sector == 1)
pub4 <- hd_panel %>%
  filter(sector == 1) %>%
  select(unitid, instnm, stabbr, fips, year) %>%
  distinct()

cat(sprintf("Public 4-year institutions: %d unique UNITID, %d inst-years\n",
            n_distinct(pub4$unitid), nrow(pub4)))

## -------------------------------------------------------------------
## 3. Harmonize enrollment data across IPEDS format changes
##    Pre-2008: efrace columns (1-24); Post-2008: named columns
## -------------------------------------------------------------------
cat("Harmonizing enrollment data...\n")

harmonize_ef <- function(d, yr) {
  # Filter to total UG enrollment by race
  # 2001: no efalevel column; use lstudy == 1, line == 1
  # 2002-2003: efalevel == 22, lstudy == 1 (FT UG; efalevel=2 only has grad)
  # 2004+: efalevel == 2, lstudy == 1

  if (!"efalevel" %in% names(d)) {
    # 2001 format
    d <- d[d$lstudy == 1 & d$line == 1, ]
  } else if (yr <= 2003) {
    d <- d[d$efalevel == 22 & d$lstudy == 1, ]
  } else {
    d <- d[d$efalevel == 2 & d$lstudy == 1, ]
  }

  if (nrow(d) == 0) return(data.frame())

  if (yr <= 2007) {
    # Pre-2008 format: efrace columns
    # efrace03 + efrace04 = Black men + women
    # efrace09 + efrace10 = Hispanic men + women
    # efrace11 + efrace12 = White men + women
    out <- data.frame(
      unitid = d$unitid,
      year = yr,
      enroll_black = as.numeric(d$efrace03) + as.numeric(d$efrace04),
      enroll_hisp = as.numeric(d$efrace09) + as.numeric(d$efrace10),
      enroll_white = as.numeric(d$efrace11) + as.numeric(d$efrace12),
      stringsAsFactors = FALSE
    )

    # Total: use grand total column if available, else sum men + women
    if ("efrace24" %in% names(d)) {
      out$enroll_total <- as.numeric(d$efrace24)
    } else if ("efrace15" %in% names(d)) {
      out$enroll_total <- as.numeric(d$efrace15) + as.numeric(d$efrace16)
    }
  } else {
    # Post-2008: named columns (EFBKAAT, EFHISPT, etc.)
    out <- data.frame(
      unitid = d$unitid,
      year = yr,
      enroll_black = as.numeric(d$efbkaat),
      enroll_hisp = as.numeric(d$efhispt),
      enroll_white = as.numeric(d$efwhitt),
      enroll_total = as.numeric(d$eftotlt),
      stringsAsFactors = FALSE
    )
  }

  out
}

enroll_all <- lapply(names(ef_list), function(yr) {
  harmonize_ef(ef_list[[yr]], as.integer(yr))
}) %>% bind_rows()

# Remove NA/zero totals and aggregate to institution-year
# (some institutions have multiple rows per efalevel/line combo)
enroll_clean <- enroll_all %>%
  filter(!is.na(enroll_total), enroll_total > 0) %>%
  group_by(unitid, year) %>%
  summarise(
    enroll_total = sum(enroll_total, na.rm = TRUE),
    enroll_black = sum(enroll_black, na.rm = TRUE),
    enroll_hisp = sum(enroll_hisp, na.rm = TRUE),
    enroll_white = sum(enroll_white, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("Enrollment panel: %d inst-years\n", nrow(enroll_clean)))

## -------------------------------------------------------------------
## 4. Merge enrollment with institution characteristics
## -------------------------------------------------------------------
cat("Merging enrollment with institution info...\n")

panel <- enroll_clean %>%
  inner_join(pub4, by = c("unitid", "year")) %>%
  mutate(
    share_black = enroll_black / enroll_total,
    share_hisp = enroll_hisp / enroll_total,
    share_white = enroll_white / enroll_total,
    share_minority = (enroll_black + enroll_hisp) / enroll_total
  )

cat(sprintf("Panel after merge: %d inst-years, %d institutions, %d states\n",
            nrow(panel), n_distinct(panel$unitid), n_distinct(panel$stabbr)))

## -------------------------------------------------------------------
## 5. Add treatment timing
## -------------------------------------------------------------------
cat("Adding treatment timing...\n")

# Treatment = first enrollment year affected by ban
ban_states <- data.frame(
  stabbr = c("CA", "WA", "FL", "MI", "NE", "AZ", "NH", "OK", "ID"),
  ban_year = c(1998, 1999, 2000, 2007, 2009, 2011, 2012, 2013, 2020),
  stringsAsFactors = FALSE
)

panel <- panel %>%
  left_join(ban_states, by = "stabbr") %>%
  mutate(
    # For CS estimator: first_treat = ban_year for ban states, 0 for never-treated
    first_treat = ifelse(is.na(ban_year), 0, ban_year),
    # Binary post indicator
    post = ifelse(!is.na(ban_year) & year >= ban_year, 1, 0),
    # Treatment group label
    group = case_when(
      is.na(ban_year) ~ "Never banned",
      ban_year <= 2000 ~ "Early ban (CA/WA/FL)",
      TRUE ~ sprintf("Ban %d", ban_year)
    )
  )

cat("Treatment timing:\n")
print(table(panel$group, panel$year >= 2007))

## -------------------------------------------------------------------
## 6. Add admissions selectivity (admission rate)
## -------------------------------------------------------------------
cat("Adding selectivity measures...\n")

# Build admission rate from ADM/IC files
adm_panel <- lapply(names(adm_list), function(yr) {
  d <- adm_list[[yr]]
  # Look for admissions/applicant columns
  cols <- names(d)
  if (all(c("unitid", "admssn", "applcn") %in% cols)) {
    data.frame(
      unitid = d$unitid,
      year = as.integer(yr),
      n_admitted = as.numeric(d$admssn),
      n_applied = as.numeric(d$applcn),
      stringsAsFactors = FALSE
    )
  } else if (all(c("unitid", "admssn", "applcnm", "applcnw") %in% cols)) {
    data.frame(
      unitid = d$unitid,
      year = as.integer(yr),
      n_admitted = as.numeric(d$admssn),
      n_applied = as.numeric(d$applcnm) + as.numeric(d$applcnw),
      stringsAsFactors = FALSE
    )
  }
}) %>% bind_rows()

if (nrow(adm_panel) > 0) {
  adm_panel <- adm_panel %>%
    filter(!is.na(n_applied), n_applied > 0, !is.na(n_admitted)) %>%
    mutate(admit_rate = n_admitted / n_applied)

  # Compute pre-ban average selectivity for each institution
  pre_ban_select <- panel %>%
    left_join(adm_panel, by = c("unitid", "year")) %>%
    filter(post == 0 | is.na(ban_year)) %>%
    group_by(unitid) %>%
    summarise(
      avg_admit_rate = mean(admit_rate, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(!is.na(avg_admit_rate))

  # Assign selectivity quintiles (1 = most selective = lowest admit rate)
  pre_ban_select <- pre_ban_select %>%
    mutate(selectivity_q = ntile(desc(avg_admit_rate), 5))

  panel <- panel %>%
    left_join(pre_ban_select, by = "unitid")

  cat(sprintf("Selectivity data (admissions) for %d institutions\n", nrow(pre_ban_select)))
}

# Also create size-based selectivity proxy (works for all institutions)
# Larger institutions are generally more selective
size_proxy <- panel %>%
  filter(post == 0 | is.na(ban_year)) %>%
  group_by(unitid) %>%
  summarise(avg_enroll = mean(enroll_total, na.rm = TRUE), .groups = "drop")

size_proxy <- size_proxy %>%
  mutate(size_q = ntile(avg_enroll, 3))  # 3 = large, 1 = small

panel <- panel %>%
  left_join(size_proxy %>% select(unitid, size_q), by = "unitid")

cat(sprintf("Size quintiles assigned for %d institutions\n", nrow(size_proxy)))

## -------------------------------------------------------------------
## 7. Merge ACS demographics
## -------------------------------------------------------------------
cat("Merging ACS demographics...\n")

# Map state abbreviation to FIPS for ACS merge
state_fips <- data.frame(
  stabbr = c(state.abb, "DC"),
  fips_state = c(as.integer(
    c("01","02","04","05","06","08","09","10","12","13",
      "15","16","17","18","19","20","21","22","23","24",
      "25","26","27","28","29","30","31","32","33","34",
      "35","36","37","38","39","40","41","42","44","45",
      "46","47","48","49","50","51","53","54","55","56")),
    11),
  stringsAsFactors = FALSE
)

panel <- panel %>%
  left_join(state_fips, by = "stabbr") %>%
  left_join(acs_raw %>% select(fips, year, pop_18_24, pop_18_24_black, pop_18_24_hisp),
            by = c("fips_state" = "fips", "year"))

## -------------------------------------------------------------------
## 8. Summary and save
## -------------------------------------------------------------------
cat("\n=== Analysis panel summary ===\n")

# Focus on 2001-2022 (full data window)
panel_final <- panel %>%
  filter(year >= 2001, year <= 2022)

cat(sprintf("Final panel: %d inst-years\n", nrow(panel_final)))
cat(sprintf("Institutions: %d\n", n_distinct(panel_final$unitid)))
cat(sprintf("States: %d\n", n_distinct(panel_final$stabbr)))
cat(sprintf("Years: %d-%d\n", min(panel_final$year), max(panel_final$year)))
cat(sprintf("Ban states in panel: %s\n",
            paste(sort(unique(panel_final$stabbr[panel_final$first_treat > 0])),
                  collapse = ", ")))

cat("\nMean minority share by group:\n")
panel_final %>%
  group_by(group) %>%
  summarise(
    n_inst = n_distinct(unitid),
    mean_black_share = mean(share_black, na.rm = TRUE),
    mean_hisp_share = mean(share_hisp, na.rm = TRUE),
    mean_total_enroll = mean(enroll_total, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

saveRDS(panel_final, "../data/analysis_panel.rds")
cat("\nSaved analysis_panel.rds\n")
