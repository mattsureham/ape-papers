## ============================================================
## 03_main_analysis.R — Primary DiD regressions
## Paper: Does Foreign Aid Buffer Oil Revenue Shocks?
##        Geocoded Evidence from Nigeria
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"

panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
cat(sprintf("Panel loaded: %d obs, %d states, %d months\n",
            nrow(panel), uniqueN(panel$state), uniqueN(panel$ym)))

## ============================================================
## 1) Main DiD specifications — continuous treatment
## ============================================================

cat("\n========== MAIN DiD RESULTS ==========\n")

## Specification 1: Baseline — log(events+1) on aid × post, state + time FE
m1 <- feols(log_events ~ log_aid_x_post | state + ym,
            data = panel, cluster = ~state)

## Specification 2: Binary treatment
m2 <- feols(log_events ~ high_aid_x_post | state + ym,
            data = panel, cluster = ~state)

## Specification 3: Continuous project count
m3 <- feols(log_events ~ aid_x_post | state + ym,
            data = panel, cluster = ~state)

## Specification 4: With oil price interaction
m4 <- feols(log_events ~ log_aid_x_post + oil_price | state + ym,
            data = panel, cluster = ~state)

## Specification 5: Control for oil-producing state × post
m5 <- feols(log_events ~ log_aid_x_post + oil_state:post_shock | state + ym,
            data = panel, cluster = ~state)

cat("\n--- Table 2: Main DiD Results ---\n")
etable(m1, m2, m3, m4, m5,
       headers = c("Log Aid", "Binary", "Count", "+Oil Price", "+Oil State"),
       dict = c(log_aid_x_post = "Log(Aid) × Post",
                high_aid_x_post = "High Aid × Post",
                aid_x_post = "Aid Projects × Post",
                oil_price = "Oil Price",
                "oil_state:post_shock" = "Oil State × Post"))

## Save coefficients for figures
main_coefs <- data.table(
  spec = c("Log Aid × Post", "High Aid × Post", "Count × Post",
           "+Oil Price", "+Oil State"),
  estimate = c(coef(m1)["log_aid_x_post"],
               coef(m2)["high_aid_x_post"],
               coef(m3)["aid_x_post"],
               coef(m4)["log_aid_x_post"],
               coef(m5)["log_aid_x_post"]),
  se = c(se(m1)["log_aid_x_post"],
         se(m2)["high_aid_x_post"],
         se(m3)["aid_x_post"],
         se(m4)["log_aid_x_post"],
         se(m5)["log_aid_x_post"]),
  pval = c(pvalue(m1)["log_aid_x_post"],
           pvalue(m2)["high_aid_x_post"],
           pvalue(m3)["aid_x_post"],
           pvalue(m4)["log_aid_x_post"],
           pvalue(m5)["log_aid_x_post"])
)
main_coefs[, ci_lo := estimate - 1.96 * se]
main_coefs[, ci_hi := estimate + 1.96 * se]
fwrite(main_coefs, file.path(DATA_DIR, "main_coefs.csv"))

## ============================================================
## 2) Outcome heterogeneity
## ============================================================

cat("\n========== OUTCOME HETEROGENEITY ==========\n")

## State-based conflict
m_state_based <- feols(log_state_based ~ log_aid_x_post | state + ym,
                       data = panel, cluster = ~state)

## Non-state conflict
m_non_state <- feols(log_non_state ~ log_aid_x_post | state + ym,
                     data = panel, cluster = ~state)

## Fatalities
m_fatal <- feols(log_fatalities ~ log_aid_x_post | state + ym,
                 data = panel, cluster = ~state)

## Civilian deaths
m_civ <- feols(log_civ_deaths ~ log_aid_x_post | state + ym,
               data = panel, cluster = ~state)

cat("\n--- Table 3: Outcome Heterogeneity ---\n")
etable(m_state_based, m_non_state, m_fatal, m_civ,
       headers = c("State-Based", "Non-State", "Fatalities", "Civilian Deaths"),
       dict = c(log_aid_x_post = "Log(Aid) × Post"))

outcome_coefs <- data.table(
  outcome = c("State-Based Conflict", "Non-State Conflict",
              "Fatalities", "Civilian Deaths"),
  estimate = c(coef(m_state_based)["log_aid_x_post"],
               coef(m_non_state)["log_aid_x_post"],
               coef(m_fatal)["log_aid_x_post"],
               coef(m_civ)["log_aid_x_post"]),
  se = c(se(m_state_based)["log_aid_x_post"],
         se(m_non_state)["log_aid_x_post"],
         se(m_fatal)["log_aid_x_post"],
         se(m_civ)["log_aid_x_post"])
)
outcome_coefs[, ci_lo := estimate - 1.96 * se]
outcome_coefs[, ci_hi := estimate + 1.96 * se]
fwrite(outcome_coefs, file.path(DATA_DIR, "outcome_coefs.csv"))

## ============================================================
## 3) Event study — monthly leads and lags
## ============================================================

cat("\n========== EVENT STUDY ==========\n")

## Bin event time at -24 and +24 to avoid sparse cells
panel[, event_time_bin := pmax(pmin(event_time, 24), -24)]

## Drop the -1 reference period
m_es <- feols(log_events ~ i(event_time_bin, log_aid, ref = -1) | state + ym,
              data = panel[event_time_bin >= -24 & event_time_bin <= 24],
              cluster = ~state)

cat("\nEvent study coefficients:\n")
summary(m_es)

## Extract event study coefficients for plotting
es_coefs <- as.data.table(coeftable(m_es), keep.rownames = "term")
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pval"))

## Parse event time from coefficient names
## Format: "event_time_bin::-24:log_aid" -> extract -24
es_coefs[, event_time := as.integer(
  gsub("event_time_bin::([-0-9]+):log_aid", "\\1", term)
)]
es_coefs <- es_coefs[!is.na(event_time)]
es_coefs[, ci_lo := estimate - 1.96 * se]
es_coefs[, ci_hi := estimate + 1.96 * se]

fwrite(es_coefs, file.path(DATA_DIR, "event_study_coefs.csv"))

## Pre-trend test: F-test on pre-treatment coefficients
pre_coefs <- es_coefs[event_time < -1]
if (nrow(pre_coefs) > 0) {
  pre_f <- wald(m_es, paste0("event_time_bin::-", 24:2, ":log_aid"))
  cat(sprintf("\nPre-trend F-test: stat=%.3f, p=%.4f\n",
              pre_f$stat, pre_f$p))
}

## ============================================================
## 4) Sector heterogeneity
## ============================================================

cat("\n========== SECTOR HETEROGENEITY ==========\n")

## Load sector-specific aid exposure
locations <- readRDS(file.path(DATA_DIR, "aiddata_locations.rds"))
projects  <- readRDS(file.path(DATA_DIR, "aiddata_projects.rds"))

## Merge locations with projects
loc_proj <- merge(
  locations[precision_code <= 4],
  projects[, .(project_id, ad_sector_names, start_actual_isodate,
               transactions_start_year)],
  by = "project_id", all.x = TRUE
)

## Extract state
loc_proj[, state := {
  parts <- strsplit(gazetteer_adm_name, "\\|")
  sapply(parts, function(p) {
    if (length(p) >= 4) trimws(gsub('"', '', p[4])) else NA_character_
  })
}]
loc_proj[, state := gsub("\\s+State$", "", state)]

## Parse start year
loc_proj[, start_year := year(as.Date(start_actual_isodate))]
loc_proj[is.na(start_year), start_year := as.integer(transactions_start_year)]

## Classify sectors
loc_proj[, sector := fcase(
  grepl("Health|health", ad_sector_names), "Health",
  grepl("Education|education", ad_sector_names), "Education",
  grepl("Agric|agric", ad_sector_names), "Agriculture",
  grepl("Govern|govern|civil society", ad_sector_names), "Governance",
  grepl("Transport|transport|infrastructure", ad_sector_names, ignore.case = TRUE), "Infrastructure",
  grepl("Water|water|sanitation", ad_sector_names, ignore.case = TRUE), "Water/Sanitation",
  default = "Other"
)]

## Compute sector-specific aid exposure by state as of 2007
sector_aid_2007 <- loc_proj[!is.na(start_year) & start_year <= 2007 &
                             !is.na(state) & state != "",
  .(n_projects = uniqueN(project_id)),
  by = .(state, sector)
]

## Pivot to wide
sector_wide <- dcast(sector_aid_2007, state ~ sector,
                     value.var = "n_projects", fill = 0)
setnames(sector_wide, names(sector_wide),
         gsub("[/ ]", "_", paste0("aid_", names(sector_wide))))
setnames(sector_wide, "aid_state", "state")

## Drop any existing sector columns from prior runs to avoid .x/.y duplicates
sector_cols <- setdiff(names(sector_wide), "state")
existing <- intersect(sector_cols, names(panel))
if (length(existing) > 0) panel[, (existing) := NULL]

## Merge into panel
panel <- merge(panel, sector_wide, by = "state", all.x = TRUE)
for (col in names(sector_wide)[names(sector_wide) != "state"]) {
  panel[is.na(get(col)), (col) := 0]
}

## Run sector-specific regressions
if ("aid_Health" %in% names(panel)) {
  m_health <- feols(log_events ~ I(log(aid_Health + 1) * post_shock) | state + ym,
                    data = panel, cluster = ~state)
  cat("Health aid effect:\n")
  print(summary(m_health))
}

if ("aid_Governance" %in% names(panel)) {
  m_gov <- feols(log_events ~ I(log(aid_Governance + 1) * post_shock) | state + ym,
                 data = panel, cluster = ~state)
  cat("Governance aid effect:\n")
  print(summary(m_gov))
}

if ("aid_Agriculture" %in% names(panel)) {
  m_agri <- feols(log_events ~ I(log(aid_Agriculture + 1) * post_shock) | state + ym,
                  data = panel, cluster = ~state)
  cat("Agriculture aid effect:\n")
  print(summary(m_agri))
}

## ============================================================
## 5) Save all model objects
## ============================================================

cat("\n--- Saving model objects ---\n")

save(m1, m2, m3, m4, m5,
     m_state_based, m_non_state, m_fatal, m_civ,
     m_es,
     file = file.path(DATA_DIR, "main_models.RData"))

## Save updated panel with sector variables
saveRDS(panel, file.path(DATA_DIR, "analysis_panel.rds"))
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))

cat("\nMain analysis complete.\n")
