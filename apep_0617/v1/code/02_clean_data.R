## 02_clean_data.R — Construct analysis dataset
## Merges QWI data with state EITC adoption timeline

source("00_packages.R")

# ============================================================
# Step 1: Load QWI data
# ============================================================
cat("Loading QWI data...\n")
df <- fread("../data/qwi_state_year_ind_sex_edu.csv")
cat(sprintf("  %s rows loaded\n", format(nrow(df), big.mark = ",")))

# ============================================================
# Step 2: State EITC adoption timeline
# ============================================================
# Source: NBER TAXSIM (https://users.nber.org/~taxsim/state-eitc.html)
# Credit rates as % of federal EITC at time of adoption
eitc_states <- data.table(
  state_abbr = c("WI", "MD", "VT", "IA", "NY", "MA", "OR", "KS",
                 "CO", "IN", "DC", "IL", "ME", "NJ", "RI", "OK",
                 "DE", "NE", "VA", "NM", "LA", "MI", "CT", "OH",
                 "CA", "HI", "SC"),
  statefip = c("55", "24", "50", "19", "36", "25", "41", "20",
               "08", "18", "11", "17", "23", "34", "44", "40",
               "10", "31", "51", "35", "22", "26", "09", "39",
               "06", "15", "45"),
  eitc_adopt_year = c(1984, 1987, 1988, 1990, 1994, 1997, 1997, 1998,
                      1999, 1999, 2000, 2000, 2000, 2000, 2001, 2002,
                      2006, 2006, 2006, 2007, 2008, 2008, 2011, 2013,
                      2015, 2018, 2018),
  eitc_pct = c(4, 45, 38, 15, 30, 40, 12, 17,
               25, 9, 40, 18, 25, 40, 15, 5,
               20, 10, 20, 25, 3.5, 6, 30.5, 30,
               85, 20, 125),
  refundable = c(0, 1, 1, 0, 1, 1, 1, 1,
                 1, 0, 1, 0, 1, 1, 1, 1,
                 0, 1, 0, 1, 1, 1, 1, 0,
                 1, 0, 1)
)
# Note: NC (37) adopted 2008, repealed 2014 — EXCLUDED due to reversal

# All 50 states + DC FIPS codes
all_states <- sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56))
never_treated <- setdiff(all_states, eitc_states$statefip)

cat(sprintf("EITC states: %d treated, %d never-treated\n",
            nrow(eitc_states), length(never_treated)))
cat(sprintf("Post-2001 adopters (event study): %d\n",
            sum(eitc_states$eitc_adopt_year >= 2002)))

# ============================================================
# Step 3: Construct analysis variables
# ============================================================

# Pad statefip to 2 chars
df[, statefip := sprintf("%02s", statefip)]

# Filter to relevant states (exclude territories, etc.)
df <- df[statefip %in% all_states]

# Merge EITC treatment info
df <- merge(df, eitc_states[, .(statefip, eitc_adopt_year, eitc_pct, refundable)],
            by = "statefip", all.x = TRUE)

# Never-treated states: set gname = 0 for CS-DiD
df[is.na(eitc_adopt_year), eitc_adopt_year := 0]
df[is.na(eitc_pct), eitc_pct := 0]
df[is.na(refundable), refundable := 0]

# Treatment indicator
df[, treated := as.integer(eitc_adopt_year > 0 & year >= eitc_adopt_year)]

# ============================================================
# Step 4: Compute industry employment shares
# ============================================================

# Define education groups
df[, edu_group := fcase(
  education %in% c("E1", "E2"), "low",
  education %in% c("E3"),       "mid",
  education %in% c("E4", "E5"), "high"
)]

# Aggregate to state x year x industry x sex x edu_group
df_agg <- df[, .(
  emp = sum(total_emp, na.rm = TRUE),
  earnings = weighted.mean(avg_earnings, w = pmax(total_emp, 1, na.rm = TRUE), na.rm = TRUE),
  hires = sum(total_hires, na.rm = TRUE),
  sep = sum(total_sep, na.rm = TRUE)
), by = .(statefip, year, industry, sex, edu_group,
          eitc_adopt_year, eitc_pct, refundable, treated)]

# Compute total state employment by sex x edu_group (across all industries)
total_emp <- df_agg[, .(total_state_emp = sum(emp, na.rm = TRUE)),
                     by = .(statefip, year, sex, edu_group)]

df_agg <- merge(df_agg, total_emp, by = c("statefip", "year", "sex", "edu_group"))

# Industry employment share
df_agg[, ind_share := emp / pmax(total_state_emp, 1)]

# ============================================================
# Step 5: Create main analysis dataset — low-edu women
# ============================================================
# Focus on key sectors
key_sectors <- c("62",     # Healthcare & Social Assistance
                 "72",     # Accommodation & Food Services
                 "44-45",  # Retail Trade
                 "56",     # Admin & Support & Waste Management
                 "31-33")  # Manufacturing

df_main <- df_agg[sex == 2 & edu_group == "low"]

# Create wide panel: state x year with industry shares as outcomes
panel_list <- list()
for (sector in key_sectors) {
  sector_data <- df_main[industry == sector,
                         .(statefip, year, eitc_adopt_year, treated,
                           eitc_pct, refundable, emp, ind_share, earnings)]
  sector_name <- gsub("-", "", sector)
  setnames(sector_data,
           c("emp", "ind_share", "earnings"),
           paste0(c("emp_", "share_", "earn_"), sector_name))
  if (length(panel_list) == 0) {
    panel_list[[sector]] <- sector_data
  } else {
    panel_list[[sector]] <- sector_data[, .SD, .SDcols = c("statefip", "year",
                                                            paste0(c("emp_", "share_", "earn_"), sector_name))]
  }
}

# Merge all sectors into wide panel
panel <- panel_list[[1]]
for (i in 2:length(panel_list)) {
  panel <- merge(panel, panel_list[[i]], by = c("statefip", "year"), all = TRUE)
}

# Add total employment for low-edu women
total_low <- df_main[, .(total_emp = sum(emp, na.rm = TRUE)),
                      by = .(statefip, year)]
panel <- merge(panel, total_low, by = c("statefip", "year"), all.x = TRUE)

# Numeric state ID for CS-DiD
panel[, state_id := as.integer(factor(statefip))]

# Log employment
panel[, log_total_emp := log(pmax(total_emp, 1))]

cat(sprintf("\nMain panel: %d state-year observations\n", nrow(panel)))
cat(sprintf("  States: %d\n", length(unique(panel$statefip))))
cat(sprintf("  Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("  Treatment groups: %s\n",
            paste(sort(unique(panel$eitc_adopt_year[panel$eitc_adopt_year > 0])), collapse = ", ")))

# ============================================================
# Step 6: Create triple-diff dataset (low vs high edu women)
# ============================================================
df_triple <- df_agg[sex == 2 & edu_group %in% c("low", "high") &
                    industry %in% key_sectors]

df_triple[, state_id := as.integer(factor(statefip))]
df_triple[, low_edu := as.integer(edu_group == "low")]
df_triple[, treated_low := treated * low_edu]

# ============================================================
# Step 7: Create placebo dataset (men, low-edu)
# ============================================================
df_placebo_men <- df_agg[sex == 1 & edu_group == "low" & industry %in% key_sectors]
df_placebo_men[, state_id := as.integer(factor(statefip))]

# ============================================================
# Step 8: Save all datasets
# ============================================================
fwrite(panel, "../data/panel_main.csv")
fwrite(df_agg, "../data/panel_full.csv")
fwrite(df_triple, "../data/panel_triple.csv")
fwrite(df_placebo_men, "../data/panel_placebo_men.csv")

cat("\nSaved analysis datasets to data/\n")
cat(sprintf("  panel_main.csv: %s rows (state x year, low-edu women)\n",
            format(nrow(panel), big.mark = ",")))
cat(sprintf("  panel_full.csv: %s rows (all cells)\n",
            format(nrow(df_agg), big.mark = ",")))
cat(sprintf("  panel_triple.csv: %s rows (women, low vs high edu)\n",
            format(nrow(df_triple), big.mark = ",")))
cat(sprintf("  panel_placebo_men.csv: %s rows (men, low edu)\n",
            format(nrow(df_placebo_men), big.mark = ",")))

cat("\n=== Data cleaning complete ===\n")
