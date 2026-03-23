# =============================================================================
# 02_clean_data.R — Construct analysis panel
# APEP Paper apep_0794: Testing Without Tests
# =============================================================================

source("00_packages.R")

adm <- readRDS("../data/adm_raw.rds")
ef  <- readRDS("../data/ef_raw.rds")
sfa <- readRDS("../data/sfa_raw.rds")
hd  <- readRDS("../data/hd_raw.rds")

# =============================================================================
# 1. Define treatment from admissions data
# =============================================================================

# admcon7: SAT/ACT requirement
# 1 = Required, 2 = Recommended, 3 = Neither required nor recommended,
# 5 = Considered but not required

# Treatment group: institutions requiring SAT/ACT in 2019
treat_2019 <- adm %>%
  filter(year == 2019) %>%
  mutate(
    test_required_2019 = as.integer(admcon7 == 1),
    sat_composite_25 = sat_verbal_25th + sat_math_25th
  ) %>%
  select(unitid, test_required_2019, sat_composite_25, admcon7)

cat("Treatment classification (2019 admcon7):\n")
print(table(treat_2019$admcon7, treat_2019$test_required_2019, useNA = "always",
            dnn = c("admcon7", "test_required_2019")))

cat(sprintf("\nTreated (test-required 2019): %d\n", sum(treat_2019$test_required_2019 == 1)))
cat(sprintf("Control (not required 2019): %d\n", sum(treat_2019$test_required_2019 == 0)))

# SAT intensity for treated group
cat("\nSAT composite 25th among treated:\n")
summary(treat_2019$sat_composite_25[treat_2019$test_required_2019 == 1])

# =============================================================================
# 2. Enrollment by race (undergrad total)
# =============================================================================

# efalevel 2, line 99: total undergrad enrollment
enroll <- ef %>%
  filter(efalevel == 2, line == 99) %>%
  select(unitid, year, eftotlt, efbkaat, efhispt, efwhitt, efasiat,
         efaiant, efnhpit) %>%
  mutate(
    # Two or more and unknown are residual
    ef_urm = efbkaat + efhispt + efaiant + efnhpit,
    # Shares (avoid division by zero)
    share_black = ifelse(eftotlt > 0, efbkaat / eftotlt, NA_real_),
    share_hispanic = ifelse(eftotlt > 0, efhispt / eftotlt, NA_real_),
    share_white = ifelse(eftotlt > 0, efwhitt / eftotlt, NA_real_),
    share_asian = ifelse(eftotlt > 0, efasiat / eftotlt, NA_real_),
    share_urm = ifelse(eftotlt > 0, ef_urm / eftotlt, NA_real_)
  )

cat(sprintf("\nEnrollment panel: %d obs across %d institutions, %d years\n",
            nrow(enroll), n_distinct(enroll$unitid), n_distinct(enroll$year)))

# =============================================================================
# 3. Admissions outcomes (applications, admits, yield)
# =============================================================================

# Need to find the right columns - some have varied names across years
adm_cols <- grep("^applcn$|^admssn$|^enrlt$|^enrlft$|^enrlpt$|applcnm|applcnw|admssnm|admssnw|enrlm|enrlw",
                 names(adm), value = TRUE)
cat("\nAdmissions outcome columns:", paste(adm_cols, collapse = ", "), "\n")

adm_out <- adm %>%
  select(unitid, year, admcon7, satpct, actpct,
         sat_verbal_25th, sat_math_25th, sat_verbal_75th, sat_math_75th,
         act_composite_25th, act_composite_75th,
         applicants_total, admissions_total, enrolled_total,
         any_of(c("applicants_men", "applicants_women",
                   "admissions_men", "admissions_women",
                   "enrolled_men", "enrolled_women",
                   "enrlft", "enrlpt"))) %>%
  mutate(
    sat_composite_25 = sat_verbal_25th + sat_math_25th,
    sat_composite_75 = sat_verbal_75th + sat_math_75th,
    sat_composite_mid = (sat_composite_25 + sat_composite_75) / 2,
    admit_rate = ifelse(applicants_total > 0,
                        admissions_total / applicants_total, NA_real_),
    yield_rate = ifelse(admissions_total > 0,
                        enrolled_total / admissions_total, NA_real_)
  )

cat(sprintf("Admissions panel: %d obs\n", nrow(adm_out)))

# =============================================================================
# 4. Financial aid (Pell grants)
# =============================================================================

# Find Pell-related columns
pell_cols <- grep("pell|fgrnt|grant", names(sfa), ignore.case = TRUE, value = TRUE)
cat("\nPell/grant columns (first 20):", paste(head(pell_cols, 20), collapse = ", "), "\n")

sfa_out <- sfa %>%
  select(unitid, year, any_of(c("scfa2", "pgrnt_a", "upgrnta", "upgrntp",
                                  "npist1", "npist2", "npist3", "npist4", "npist5",
                                  "igrnt_a", "floan_a")))

cat(sprintf("Financial aid panel: %d obs\n", nrow(sfa_out)))

# =============================================================================
# 5. Institutional characteristics
# =============================================================================

inst <- hd %>%
  filter(year == 2019) %>%
  select(unitid, institution_name, state, region,
         any_of(c("sector", "control", "hloffer", "c18basic", "instsize",
                   "carnegie", "longitud", "latitude", "instcat", "locale")))

cat(sprintf("Institutional characteristics: %d institutions\n", nrow(inst)))

# =============================================================================
# 6. Merge into analysis panel
# =============================================================================

panel <- enroll %>%
  inner_join(treat_2019 %>% select(unitid, test_required_2019, sat_composite_25),
             by = "unitid") %>%
  left_join(adm_out %>% select(unitid, year, admcon7, satpct, actpct,
                                sat_composite_25, admit_rate, yield_rate,
                                applicants_total, admissions_total, enrolled_total),
            by = c("unitid", "year"),
            suffix = c("", "_adm")) %>%
  left_join(sfa_out, by = c("unitid", "year")) %>%
  left_join(inst %>% select(unitid, institution_name, state, region, sector,
                            any_of(c("c18basic", "instsize", "instcat"))),
            by = "unitid")

# Create treatment variables
panel <- panel %>%
  mutate(
    post = as.integer(year >= 2020),
    # Standardize SAT intensity (mean 0, sd 1) — use treatment group's 2019 distribution
    sat_intensity = (sat_composite_25 - mean(sat_composite_25[test_required_2019 == 1 & year == 2019],
                                              na.rm = TRUE)) /
                     sd(sat_composite_25[test_required_2019 == 1 & year == 2019], na.rm = TRUE),
    # SAT quartiles for heterogeneity
    sat_quartile = ntile(sat_composite_25, 4)
  )

# Drop institutions with missing enrollment
panel <- panel %>% filter(!is.na(eftotlt), eftotlt > 0)

cat(sprintf("\nFinal panel: %d obs, %d institutions, years %d-%d\n",
            nrow(panel), n_distinct(panel$unitid), min(panel$year), max(panel$year)))
cat(sprintf("  Treated: %d institutions\n", n_distinct(panel$unitid[panel$test_required_2019 == 1])))
cat(sprintf("  Control: %d institutions\n", n_distinct(panel$unitid[panel$test_required_2019 == 0])))
cat(sprintf("  Treated with SAT scores: %d\n",
            n_distinct(panel$unitid[panel$test_required_2019 == 1 & !is.na(panel$sat_composite_25)])))

# =============================================================================
# 7. Save
# =============================================================================

saveRDS(panel, "../data/panel.rds")
cat("Panel saved to ../data/panel.rds\n")
