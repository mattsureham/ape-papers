# 02_clean_data.R — Construct treatment variable and analysis panel
# apep_0972: Craft brewery self-distribution deregulation

source("00_packages.R")

# ── Load raw panels ──────────────────────────────────────────────────
panel_sa <- readRDS("../data/panel_sa_raw.rds")
panel_se <- readRDS("../data/panel_se_raw.rds")
panel_rh <- readRDS("../data/panel_rh_raw.rds")

# ══════════════════════════════════════════════════════════════════════
# TREATMENT VARIABLE: Self-Distribution Law Adoption Dates
# ══════════════════════════════════════════════════════════════════════
# Sources: Brewers Association State Law Provisions; Colmenares (2024,
# Contemporary Economic Policy); National Conference of State
# Legislatures alcohol policy compilations; state legislative records.
#
# Treatment = state-quarter when self-distribution for breweries was
# first enacted or substantially expanded. States without a documented
# adoption during 2008-2019 are coded as never-treated (first_treat=0).
# This is conservative: some "never-treated" states already had self-
# distribution, biasing the estimate toward zero.
# ══════════════════════════════════════════════════════════════════════

state_fips <- data.frame(
  statefips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,
                26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,
                47,48,49,50,51,53,54,55,56),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI",
                 "ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN",
                 "MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH",
                 "OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA",
                 "WV","WI","WY")
)

# States that adopted or substantially expanded self-distribution during 2008-2019
treat_map <- tribble(
  ~state_abbr, ~treat_year, ~treat_qtr, ~notes,
  "MN",  2011, 3, "2011 taproom law (HF 1326) — first on-site sales",
  "AL",  2012, 2, "2012 Gourmet Beer Act — legalized craft brewing",
  "MS",  2012, 3, "2012 HB 1087 — legalized craft brewing with self-dist",
  "NC",  2012, 3, "2012 distribution expansion for small brewers",
  "VA",  2012, 3, "2012 SB 604 — farm brewery self-distribution",
  "NJ",  2012, 3, "2012 limited brewery license with self-dist rights",
  "TX",  2013, 3, "2013 HB 660 — brew-pub limited self-distribution",
  "WV",  2013, 3, "2013 Craft Brewery Act — self-distribution permitted",
  "NV",  2013, 3, "2013 AB 153 — craft brewery self-distribution",
  "FL",  2014, 3, "2014 SB 1714 — craft brewery growler/self-dist law",
  "SC",  2014, 2, "2014 Pint Act — doubled production cap + self-dist",
  "KY",  2014, 2, "2014 microbrewery self-distribution authorization",
  "LA",  2014, 3, "2014 limited self-distribution for small breweries",
  "IN",  2015, 3, "2015 SEA 530 — brewery on-site sales",
  "ND",  2015, 3, "2015 HB 1130 — micro-brewery taproom + self-dist",
  "SD",  2015, 3, "2015 SB 126 — on-premises consumption at breweries",
  "TN",  2016, 3, "2016 expansion of brewery self-distribution rights",
  "GA",  2017, 3, "2017 SB 85 — direct sales at brewery tasting rooms",
  "OK",  2018, 4, "2018 SQ 792 — comprehensive alcohol modernization",
  "KS",  2019, 3, "2019 HB 2137 — microbrewery self-distribution"
)

# ── Create time variables ────────────────────────────────────────────
panel_sa <- panel_sa %>%
  mutate(
    yq = year * 10L + as.integer(quarter),
    time_id = (year - 2001L) * 4L + as.integer(quarter)
  )

# Merge treatment timing: all non-treated states get treat_yq = 0
treat_df <- treat_map %>%
  left_join(state_fips, by = "state_abbr") %>%
  mutate(treat_yq = treat_year * 10L + as.integer(treat_qtr)) %>%
  select(statefips, state_abbr, treat_year, treat_qtr, treat_yq)

panel_sa <- panel_sa %>%
  left_join(treat_df %>% select(statefips, treat_yq), by = "statefips") %>%
  mutate(treat_yq = replace_na(treat_yq, 0L))

# Binary treatment indicator
panel_sa <- panel_sa %>%
  mutate(treated = if_else(treat_yq > 0L & yq >= treat_yq, 1L, 0L))

# first_treat for CS-DiD (sequential quarter index)
panel_sa <- panel_sa %>%
  mutate(
    first_treat_time = case_when(
      treat_yq == 0L ~ 0L,
      TRUE ~ (treat_yq %/% 10L - 2001L) * 4L + treat_yq %% 10L
    )
  )

cat(sprintf("Full panel: %d rows, %d counties, %d states\n",
            nrow(panel_sa), n_distinct(panel_sa$countyfips), n_distinct(panel_sa$statefips)))
cat(sprintf("Treated states: %d\n", n_distinct(panel_sa$statefips[panel_sa$treat_yq > 0])))
cat(sprintf("Control states: %d\n", n_distinct(panel_sa$statefips[panel_sa$treat_yq == 0])))

# ── Aggregate to state × quarter × industry ──────────────────────────
# Weighted mean with NA handling
safe_wmean <- function(x, w) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  if (sum(ok) == 0) return(NA_real_)
  weighted.mean(x[ok], w[ok])
}

state_panel <- panel_sa %>%
  group_by(statefips, year, quarter, yq, time_id, industry,
           treat_yq, first_treat_time) %>%
  summarise(
    Emp = sum(Emp, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    Sep = sum(Sep, na.rm = TRUE),
    FrmJbGn = sum(FrmJbGn, na.rm = TRUE),
    FrmJbLs = sum(FrmJbLs, na.rm = TRUE),
    EarnS_mean = safe_wmean(EarnS, Emp),
    n_counties = n_distinct(countyfips),
    .groups = "drop"
  ) %>%
  mutate(
    treated = if_else(treat_yq > 0L & yq >= treat_yq, 1L, 0L),
    is_312 = if_else(industry == "312", 1L, 0L),
    log_emp = log(pmax(Emp, 1)),
    hire_rate = HirN / pmax(Emp, 1),
    sep_rate = Sep / pmax(Emp, 1),
    net_job_creation = (FrmJbGn - FrmJbLs) / pmax(Emp, 1)
  )

# ── Extensive margin: county entry into NAICS 312 ───────────────────
county_entry <- panel_sa %>%
  filter(industry == "312", !is.na(Emp), Emp > 0) %>%
  group_by(statefips, year, quarter, yq, time_id,
           treat_yq, first_treat_time) %>%
  summarise(
    n_counties_312 = n_distinct(countyfips),
    .groups = "drop"
  ) %>%
  mutate(
    treated = if_else(treat_yq > 0L & yq >= treat_yq, 1L, 0L)
  )

# ── Education panel (state-quarter level) ────────────────────────────
panel_se <- panel_se %>%
  mutate(
    statefips = as.integer(countyfips) %/% 1000L,
    yq = year * 10L + as.integer(quarter),
    time_id = (year - 2001L) * 4L + as.integer(quarter)
  ) %>%
  left_join(treat_df %>% select(statefips, treat_yq), by = "statefips") %>%
  mutate(treat_yq = replace_na(treat_yq, 0L))

state_edu <- panel_se %>%
  group_by(statefips, year, quarter, yq, time_id, education, treat_yq) %>%
  summarise(
    Emp = sum(Emp, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    EarnS_mean = safe_wmean(EarnS, Emp),
    .groups = "drop"
  ) %>%
  mutate(
    treated = if_else(treat_yq > 0L & yq >= treat_yq, 1L, 0L),
    first_treat_time = case_when(
      treat_yq == 0L ~ 0L,
      TRUE ~ (treat_yq %/% 10L - 2001L) * 4L + treat_yq %% 10L
    ),
    log_emp = log(pmax(Emp, 1))
  )

# ── Save analysis panels ────────────────────────────────────────────
saveRDS(state_panel, "../data/state_panel.rds")
saveRDS(county_entry, "../data/county_entry.rds")
saveRDS(state_edu, "../data/state_edu.rds")

# ── Summary ──────────────────────────────────────────────────────────
cat("\n=== Analysis Panel Summary ===\n")
sp312 <- state_panel %>% filter(industry == "312")
cat(sprintf("NAICS 312 panel: %d state-quarters\n", nrow(sp312)))
cat(sprintf("  Treated: %d states | Control: %d states\n",
            n_distinct(sp312$statefips[sp312$treat_yq > 0]),
            n_distinct(sp312$statefips[sp312$treat_yq == 0])))
cat(sprintf("  Mean Emp: %.0f | SD: %.0f\n",
            mean(sp312$Emp), sd(sp312$Emp)))
cat(sprintf("  Mean log_emp: %.3f | SD: %.3f\n",
            mean(sp312$log_emp), sd(sp312$log_emp)))

sp311 <- state_panel %>% filter(industry == "311")
cat(sprintf("\nNAICS 311 placebo: %d state-quarters, Mean Emp: %.0f\n",
            nrow(sp311), mean(sp311$Emp)))

cat("\nTreatment cohorts:\n")
treat_df %>% arrange(treat_year, treat_qtr) %>%
  mutate(label = sprintf("  %s: %dQ%d (FIPS %02d)", state_abbr, treat_year, treat_qtr, statefips)) %>%
  pull(label) %>% cat(sep = "\n")

cat("\n\nData cleaning complete.\n")
