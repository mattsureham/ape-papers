# 02_clean_data.R — Parse FCC CMA data, construct treatment timing, create panel
# apep_0660: FCC Cellular Lottery and Local Economic Development
#
# DESIGN: Focus on the RSA cellular lottery (CMAs 307-734, processed 1987-1989).
# MSA lotteries (CMAs 31-306) were completed by 1986, before CBP data begins.
# RSA CMA numbers were assigned alphabetically by state, creating exogenous
# staggered treatment timing: Alabama's RSAs (low numbers) were processed before
# Wyoming's RSAs (high numbers).

source("00_packages.R")

data_dir <- "../data"

# ==============================================================================
# 1. Parse FCC MK.dat
# ==============================================================================
cat("=== Parsing FCC market records ===\n")

mk_raw <- readLines(file.path(data_dir, "MK.dat"))
mk_split <- strsplit(mk_raw, "\\|")

mk_df <- data.frame(
  cma_num = as.integer(gsub("CMA", "", trimws(sapply(mk_split, `[`, 6)))),
  description = trimws(sapply(mk_split, `[`, 9)),
  population = suppressWarnings(as.integer(trimws(sapply(mk_split, `[`, 13)))),
  stringsAsFactors = FALSE
)

# Unique CMAs
cma_info <- mk_df %>%
  filter(!is.na(cma_num)) %>%
  distinct(cma_num, .keep_all = TRUE) %>%
  arrange(cma_num)

# ==============================================================================
# 2. Map CMAs to states
# ==============================================================================
cat("=== Mapping CMAs to states ===\n")

fips_codes_50 <- c("01","02","04","05","06","08","09","10","12","13",
                    "15","16","17","18","19","20","21","22","23","24",
                    "25","26","27","28","29","30","31","32","33","34",
                    "35","36","37","38","39","40","41","42","44","45",
                    "46","47","48","49","50","51","53","54","55","56")
state_lookup <- data.frame(
  state_name = c(state.name, "District of Columbia", "Puerto Rico"),
  state_abb = c(state.abb, "DC", "PR"),
  state_fips = c(fips_codes_50, "11", "72"),
  stringsAsFactors = FALSE
)

extract_state <- function(desc) {
  # RSA format: "StateName N - CountyName"
  m <- regmatches(desc, regexpr("^[A-Za-z ]+(?= \\d)", desc, perl = TRUE))
  if (length(m) == 1) {
    st <- trimws(m)
    idx <- which(startsWith(state_lookup$state_name, st))
    if (length(idx) >= 1) return(state_lookup$state_name[idx[1]])
  }
  # MSA format: "City, ST-ST"
  abbs <- regmatches(desc, gregexpr("\\b[A-Z]{2}\\b", desc))[[1]]
  valid <- abbs[abbs %in% state_lookup$state_abb]
  if (length(valid) >= 1) return(state_lookup$state_name[state_lookup$state_abb == valid[1]])
  # Full name match
  for (sn in state_lookup$state_name) {
    if (grepl(paste0("\\b", sn, "\\b"), desc, ignore.case = TRUE)) return(sn)
  }
  NA_character_
}

cma_info$state_name <- sapply(cma_info$description, extract_state)
cma_info <- left_join(cma_info, state_lookup, by = "state_name")

# ==============================================================================
# 3. Focus on RSA CMAs (307-734) — the rural lottery
# ==============================================================================
cat("\n=== RSA lottery: CMA 307-734 ===\n")

rsa <- cma_info %>%
  filter(cma_num >= 307 & cma_num <= 734 & !is.na(state_fips))

cat(sprintf("RSA CMAs with state: %d\n", nrow(rsa)))

# RSA treatment cohorts from CMA numbers (FCC processed in order)
# The FCC began RSA lottery in late 1986, with grants in 1987-1989.
# Lower CMA numbers were processed first (alphabetical by state).
rsa <- rsa %>%
  mutate(
    rsa_cohort = case_when(
      cma_num <= 430 ~ 1987L,  # First RSA batch
      cma_num <= 560 ~ 1988L,  # Second batch
      TRUE           ~ 1989L   # Final batch
    )
  )

cat("RSA cohort distribution:\n")
print(table(rsa$rsa_cohort))

# State-level RSA treatment year = earliest RSA cohort in the state
state_rsa <- rsa %>%
  group_by(state_fips, state_abb) %>%
  summarize(
    n_rsa = n(),
    min_cma = min(cma_num),
    max_cma = max(cma_num),
    rsa_treat_year = min(rsa_cohort),
    total_rsa_pop = sum(population, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("\nStates with RSAs: %d\n", nrow(state_rsa)))
cat("State-level RSA treatment year:\n")
print(table(state_rsa$rsa_treat_year))
cat(sprintf("States per cohort — 1987: %d, 1988: %d, 1989: %d\n",
            sum(state_rsa$rsa_treat_year == 1987),
            sum(state_rsa$rsa_treat_year == 1988),
            sum(state_rsa$rsa_treat_year == 1989)))

# Show state assignments
cat("\nSample state assignments:\n")
state_rsa %>%
  arrange(min_cma) %>%
  select(state_abb, n_rsa, min_cma, max_cma, rsa_treat_year) %>%
  head(15) %>%
  print()

# ==============================================================================
# 4. Create county panel
# ==============================================================================
cat("\n=== Building county panel ===\n")

cbp_raw <- readRDS(file.path(data_dir, "cbp_raw.rds"))

panel <- cbp_raw %>%
  filter(nchar(fips) == 5 & !is.na(emp)) %>%
  mutate(state_fips = substr(fips, 1, 2)) %>%
  inner_join(state_rsa %>% select(state_fips, state_abb, rsa_treat_year, n_rsa),
             by = "state_fips") %>%
  mutate(
    treat_year = rsa_treat_year,
    treated = as.integer(year >= treat_year),
    years_exposed = pmax(0L, as.integer(year - treat_year)),
    log_emp = log(pmax(emp, 1)),
    log_estab = log(pmax(estab, 1)),
    log_payann = log(pmax(payann, 1))
  )

cat(sprintf("Panel: %d county-years, %d counties, %d states\n",
            nrow(panel), n_distinct(panel$fips), n_distinct(panel$state_fips)))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))

# Treatment cohorts
cat("\nCounties per cohort:\n")
panel %>% filter(year == min(year)) %>% count(treat_year) %>% print()

cat("\nPre-treatment years by cohort:\n")
for (ty in sort(unique(panel$treat_year))) {
  n_pre <- sum(unique(panel$year) < ty)
  n_cty <- n_distinct(panel$fips[panel$treat_year == ty])
  cat(sprintf("  Cohort %d: %d pre-years, %d counties\n", ty, n_pre, n_cty))
}

# ==============================================================================
# 5. Summary statistics
# ==============================================================================
cat("\n=== Summary statistics ===\n")
panel %>%
  group_by(treated) %>%
  summarize(
    n = n(),
    mean_emp = mean(emp, na.rm = TRUE),
    mean_estab = mean(estab, na.rm = TRUE),
    mean_log_emp = mean(log_emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# ==============================================================================
# 6. Sector panel
# ==============================================================================
cat("\n=== Building sector panel ===\n")

sector_defs <- list(
  manufacturing = c(20, 39),
  retail = c(52, 59),
  fire = c(60, 67),
  services = c(70, 89)
)

sector_list <- list()
for (yr in c(1986, 1988, 1990, 1993, 1996)) {
  yy <- sprintf("%02d", yr %% 100)
  candidates <- list.files(data_dir, pattern = sprintf("cbp%sco", yy), ignore.case = TRUE,
                           full.names = TRUE)
  if (length(candidates) == 0) next

  dat <- tryCatch(read.csv(candidates[1], stringsAsFactors = FALSE, colClasses = "character"),
                  error = function(e) NULL)
  if (is.null(dat)) next
  names(dat) <- toupper(names(dat))

  for (sec_name in names(sector_defs)) {
    rng <- sector_defs[[sec_name]]
    # SIC codes in CBP files use format "20--" for 2-digit division totals
    sec_dat <- dat %>%
      mutate(
        sic_clean = trimws(SIC),
        sic_2d = suppressWarnings(as.integer(substr(sic_clean, 1, 2))),
        is_division = grepl("--$", sic_clean),  # Division-level totals end with "--"
        fips = paste0(sprintf("%02s", trimws(FIPSTATE)), sprintf("%03s", trimws(FIPSCTY))),
        emp_val = suppressWarnings(as.integer(gsub("[^0-9]", "", EMP))),
        est_val = suppressWarnings(as.integer(gsub("[^0-9]", "", EST)))
      ) %>%
      filter(is_division & !is.na(sic_2d) & sic_2d >= rng[1] & sic_2d <= rng[2]) %>%
      filter(trimws(FIPSCTY) != "000" & nchar(fips) == 5)

    if (nrow(sec_dat) == 0) next

    agg <- sec_dat %>%
      group_by(fips) %>%
      summarize(emp = sum(emp_val, na.rm = TRUE),
                estab = sum(est_val, na.rm = TRUE), .groups = "drop") %>%
      mutate(year = yr, sector = sec_name)
    sector_list[[paste(yr, sec_name)]] <- agg
    cat(sprintf("  %d %s: %d counties\n", yr, sec_name, nrow(agg)))
  }
}

sector_raw <- bind_rows(sector_list)
if (nrow(sector_raw) > 0) {
  sector_panel <- sector_raw %>%
    mutate(state_fips = substr(fips, 1, 2)) %>%
    inner_join(state_rsa %>% select(state_fips, rsa_treat_year), by = "state_fips") %>%
    mutate(
      treat_year = rsa_treat_year,
      treated = as.integer(year >= treat_year),
      log_emp = log(pmax(emp, 1)), log_estab = log(pmax(estab, 1))
    )
  saveRDS(sector_panel, file.path(data_dir, "sector_panel.rds"))
  cat(sprintf("Sector panel: %d obs\n", nrow(sector_panel)))
} else {
  cat("No sector data\n")
}

# ==============================================================================
# 7. Save
# ==============================================================================
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(state_rsa, file.path(data_dir, "state_treatment.rds"))
saveRDS(cma_info, file.path(data_dir, "cma_info.rds"))

diag <- list(
  n_treated = n_distinct(panel$state_fips),
  n_pre = sum(unique(panel$year) < min(panel$treat_year)),
  n_obs = nrow(panel),
  n_counties = n_distinct(panel$fips),
  n_states = n_distinct(panel$state_fips),
  n_cma = nrow(rsa),
  treatment_years = sort(unique(panel$treat_year)),
  data_years = sort(unique(panel$year))
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("\n=== Panel: %d obs, %d counties, %d states, cohorts: %s ===\n",
            nrow(panel), n_distinct(panel$fips), n_distinct(panel$state_fips),
            paste(sort(unique(panel$treat_year)), collapse = ",")))
