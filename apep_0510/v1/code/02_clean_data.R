# =============================================================================
# 02_clean_data.R — Pills and Diplomas (apep_0510)
# =============================================================================
# Constructs the analysis panel by merging IPEDS institution data with
# PDMP mandate dates, overdose mortality, and state-level controls.
# =============================================================================

source("code/00_packages.R")

# --- Load raw data ---
hd       <- fread(file.path(DATA_DIR, "ipeds_hd.csv"))
efd      <- fread(file.path(DATA_DIR, "ipeds_efd.csv"))
gr       <- fread(file.path(DATA_DIR, "ipeds_gr.csv"))
efa      <- fread(file.path(DATA_DIR, "ipeds_efa.csv"))
ca       <- fread(file.path(DATA_DIR, "ipeds_ca.csv"))
sfa      <- fread(file.path(DATA_DIR, "ipeds_sfa.csv"))
pdmp     <- fread(file.path(DATA_DIR, "pdmp_mandate_dates.csv"))
cdc      <- fread(file.path(DATA_DIR, "cdc_drug_poisoning.csv"))
vsrr     <- fread(file.path(DATA_DIR, "vsrr_overdose_by_drug.csv"))
unemp    <- fread(file.path(DATA_DIR, "state_unemployment.csv"))
naloxone <- fread(file.path(DATA_DIR, "naloxone_dates.csv"))
good_sam <- fread(file.path(DATA_DIR, "good_samaritan_dates.csv"))
med_exp  <- fread(file.path(DATA_DIR, "medicaid_expansion_dates.csv"))
cannabis <- fread(file.path(DATA_DIR, "cannabis_legalization_dates.csv"))
st_fips  <- fread(file.path(DATA_DIR, "state_fips.csv"))

# =============================================================================
# CONSTRUCT INSTITUTION-LEVEL PANEL
# =============================================================================
cat("=== Constructing institution panel ===\n")

# Keep only institutions that appear consistently
# Focus on 4-year and 2-year degree-granting institutions
inst_panel <- hd[level %in% c(1, 2),  # 4-year and 2-year
                 .(unitid, year, institution_name, state, sector, control,
                   level, hbcu, latitude, longitude)]

# Merge retention rates
inst_panel <- merge(inst_panel, efd[, .(unitid, year, ret_pcf, ret_pcp)],
                    by = c("unitid", "year"), all.x = TRUE)

# Construct enrollment totals from ef_a
# efalevel = 1 is "All students total"
enroll_total <- efa[efalevel == 1,
                    .(unitid, year, total_enrollment = eftotlt,
                      male_enrollment = eftotlm, female_enrollment = eftotlw)]
inst_panel <- merge(inst_panel, enroll_total,
                    by = c("unitid", "year"), all.x = TRUE)

# Construct undergraduate vs graduate enrollment
enroll_ug <- efa[efalevel == 2,  # Undergraduate total
                 .(unitid, year, ug_enrollment = eftotlt)]
enroll_grad <- efa[efalevel == 12,  # Graduate total (level 12 in some years)
                   .(unitid, year, grad_enrollment = eftotlt)]
# Try alternative efalevel coding if 12 doesn't work
if (nrow(enroll_grad) == 0) {
  enroll_grad <- efa[efalevel == 3,
                     .(unitid, year, grad_enrollment = eftotlt)]
}

inst_panel <- merge(inst_panel, enroll_ug, by = c("unitid", "year"), all.x = TRUE)
inst_panel <- merge(inst_panel, enroll_grad, by = c("unitid", "year"), all.x = TRUE)

# Calculate share graduate (for placebo identification)
inst_panel[, grad_share := grad_enrollment / (ug_enrollment + grad_enrollment)]
inst_panel[is.nan(grad_share), grad_share := 0]

# Flag graduate-heavy institutions (>50% graduate enrollment)
inst_panel[, grad_heavy := as.integer(grad_share > 0.5)]

# Graduation rate: keep 4-year bachelor's cohort (grtype = adjusted cohort)
# chrtstat = 12 is "4-year institutions" adjusted cohort
gr_clean <- gr[!is.na(grtotlt) & grtotlt > 0]
# Use the overall graduation rate row (section = total, grtype = bachelor's)
gr_agg <- gr_clean[, .(grad_rate = mean(grtotlt, na.rm = TRUE),
                       grad_rate_n = .N),
                   by = .(unitid, year)]
inst_panel <- merge(inst_panel, gr_agg, by = c("unitid", "year"), all.x = TRUE)

# Total completions
ca_total <- ca[, .(total_completions = sum(ctotalt, na.rm = TRUE)),
               by = .(unitid, year)]
inst_panel <- merge(inst_panel, ca_total, by = c("unitid", "year"), all.x = TRUE)

# Financial aid
inst_panel <- merge(inst_panel, sfa[, .(unitid, year, pct_any_aid, ug_enrolled_sfa)],
                    by = c("unitid", "year"), all.x = TRUE)

cat("  Institution panel:", nrow(inst_panel), "rows,",
    length(unique(inst_panel$unitid)), "institutions\n")

# =============================================================================
# FIX INSTITUTIONS THAT CHANGE STATES (e.g., online/multi-campus)
# =============================================================================
# Assign each institution its modal state so g is constant within unitid
modal_state <- inst_panel[, .N, by = .(unitid, state)][order(unitid, -N)]
modal_state <- modal_state[, .SD[1], by = unitid][, .(unitid, modal_state = state)]
inst_panel <- merge(inst_panel, modal_state, by = "unitid")
# Replace varying state with fixed modal state
n_changed <- sum(inst_panel$state != inst_panel$modal_state)
cat("  Fixed", n_changed, "inst-year rows with changed state assignment\n")
inst_panel[, state := modal_state]
inst_panel[, modal_state := NULL]

# =============================================================================
# ADD TREATMENT VARIABLES
# =============================================================================
cat("=== Adding treatment variables ===\n")

# PDMP mandate indicator
inst_panel <- merge(inst_panel, pdmp[, .(state, pdmp_mandate_year)],
                    by = "state", all.x = TRUE)
inst_panel[, pdmp_treated := as.integer(!is.na(pdmp_mandate_year) & year >= pdmp_mandate_year)]

# Treatment cohort for CS-DiD (first treated year; 0 for never-treated)
inst_panel[, g := fifelse(is.na(pdmp_mandate_year), 0L, pdmp_mandate_year)]

# Concurrent policy indicators
inst_panel <- merge(inst_panel, naloxone[, .(state, naloxone_year)],
                    by = "state", all.x = TRUE)
inst_panel[, naloxone_active := as.integer(!is.na(naloxone_year) & year >= naloxone_year)]

inst_panel <- merge(inst_panel, good_sam[, .(state, good_sam_year)],
                    by = "state", all.x = TRUE)
inst_panel[, good_sam_active := as.integer(!is.na(good_sam_year) & year >= good_sam_year)]

inst_panel <- merge(inst_panel, med_exp[, .(state, medicaid_exp_year)],
                    by = "state", all.x = TRUE)
inst_panel[, medicaid_expanded := as.integer(!is.na(medicaid_exp_year) & year >= medicaid_exp_year)]

inst_panel <- merge(inst_panel, cannabis[, .(state, cannabis_year)],
                    by = "state", all.x = TRUE)
inst_panel[, cannabis_legal := as.integer(!is.na(cannabis_year) & year >= cannabis_year)]

# =============================================================================
# ADD STATE-LEVEL CONTROLS
# =============================================================================
cat("=== Adding state controls ===\n")

inst_panel <- merge(inst_panel, unemp, by = c("state", "year"), all.x = TRUE)

# =============================================================================
# ADD OVERDOSE MORTALITY DATA
# =============================================================================
cat("=== Adding overdose mortality data ===\n")

# CDC age-specific mortality: map state names to abbreviations
state_name_to_abbr <- data.table(
  state_full = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
    "Connecticut","Delaware","District of Columbia","Florida","Georgia","Hawaii",
    "Idaho","Illinois","Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine",
    "Maryland","Massachusetts","Michigan","Minnesota","Mississippi","Missouri",
    "Montana","Nebraska","Nevada","New Hampshire","New Jersey","New Mexico",
    "New York","North Carolina","North Dakota","Ohio","Oklahoma","Oregon",
    "Pennsylvania","Rhode Island","South Carolina","South Dakota","Tennessee",
    "Texas","Utah","Vermont","Virginia","Washington","West Virginia","Wisconsin","Wyoming"),
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID",
    "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT",
    "NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
    "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

# CDC data uses full state names — map to abbreviations
cdc[, state_full := state]
cdc <- merge(cdc, state_name_to_abbr, by = "state_full", all.x = TRUE)
# After merge, state.x = original (full name), state.y = abbreviation
if ("state.y" %in% names(cdc)) {
  setnames(cdc, "state.y", "state_abbr")
} else {
  cdc[, state_abbr := state]  # Already abbreviated
}

# State-level overdose rate (all ages — youth suppressed by CDC at state level)
cdc_od_rate <- cdc[, .(state = state_abbr, year,
                       od_crude_rate = crude_death_rate,
                       od_adj_rate = as.numeric(age_adjusted_rate),
                       od_deaths = deaths)]
cdc_od_rate <- cdc_od_rate[!is.na(state)]

inst_panel <- merge(inst_panel, cdc_od_rate, by = c("state", "year"), all.x = TRUE)

# VSRR: annual state-level by drug type (map state names)
vsrr[, state_full := state_name]
vsrr <- merge(vsrr, state_name_to_abbr, by = "state_full", all.x = TRUE)

# Create wide format: one column per drug type
vsrr_wide <- dcast(vsrr[!is.na(state)],
                   state + year ~ indicator,
                   value.var = "data_value",
                   fun.aggregate = function(x) mean(x, na.rm = TRUE))
# Clean column names
old_names <- names(vsrr_wide)
new_names <- gsub("[^a-zA-Z0-9_]", "_", old_names)
new_names <- gsub("_+", "_", new_names)
new_names <- gsub("_$", "", new_names)
setnames(vsrr_wide, old_names, new_names)

inst_panel <- merge(inst_panel, vsrr_wide, by = c("state", "year"), all.x = TRUE)

# =============================================================================
# FINAL CLEANING
# =============================================================================
cat("=== Final cleaning ===\n")

# Create institution type categories
inst_panel[, inst_type := fifelse(level == 1, "4-year",
                                  fifelse(level == 2, "2-year", "Other"))]
inst_panel[, inst_control := fifelse(control == 1, "Public",
                                     fifelse(control == 2, "Private nonprofit",
                                             fifelse(control == 3, "Private for-profit", "Other")))]

# Log enrollment
inst_panel[, log_enrollment := log(total_enrollment + 1)]

# Create state numeric ID for clustering
inst_panel[, state_id := as.integer(as.factor(state))]

# Drop Puerto Rico (incomplete policy data)
inst_panel <- inst_panel[state != "PR"]

# Keep only years 2003-2023 (sufficient pre-treatment for 2007 earliest adopter)
inst_panel <- inst_panel[year >= 2003 & year <= 2023]

# Summary statistics
cat("  Final panel:", nrow(inst_panel), "institution-years\n")
cat("  Institutions:", length(unique(inst_panel$unitid)), "\n")
cat("  States:", length(unique(inst_panel$state)), "\n")
cat("  Years:", min(inst_panel$year), "-", max(inst_panel$year), "\n")
cat("  PDMP treated:", sum(inst_panel$pdmp_treated, na.rm = TRUE), "inst-years\n")
cat("  PDMP never-treated:", sum(inst_panel$g == 0, na.rm = TRUE), "inst-years\n")

# Treatment cohort distribution
cat("\n  Treatment cohort sizes:\n")
print(inst_panel[g > 0, .N, by = g][order(g)])

# =============================================================================
# SAVE ANALYSIS PANEL
# =============================================================================
fwrite(inst_panel, file.path(DATA_DIR, "analysis_panel.csv"))
saveRDS(inst_panel, file.path(DATA_DIR, "analysis_panel.rds"))

cat("\nAnalysis panel saved.\n")
