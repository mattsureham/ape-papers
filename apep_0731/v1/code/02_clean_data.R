## 02_clean_data.R — Clean EO BMF data + add state audit threshold info
## apep_0731: Nonprofit bunching at state audit thresholds

source("00_packages.R")

data_dir <- "../data"

## ── Read combined data ─────────────────────────────────────────────────────
bmf <- fread(file.path(data_dir, "eo_bmf_combined.csv"))
cat("Loaded", format(nrow(bmf), big.mark = ","), "organizations\n")

## ── State charitable audit thresholds (as of 2024) ─────────────────────────
## Source: State charity registration statutes, compiled from National Council
## of Nonprofits, Hurwit & Associates, and individual state AG offices
## Thresholds trigger MANDATORY independent CPA audit requirement
## States without entries have no state-level charitable audit mandate

thresholds <- data.table(
  state = c(
    "AL", "AR", "CA", "CO", "CT", "DC", "FL", "GA", "HI",
    "IL", "KS", "KY", "MA", "MD", "ME", "MI", "MN", "MO",
    "MS", "NC", "NH", "NJ", "NM", "NY", "OH", "OK", "OR",
    "PA", "RI", "SC", "TN", "UT", "VA", "WI", "WV"
  ),
  threshold = c(
    500000,   # AL: >$500K total revenue
    500000,   # AR: >$500K contributions (2023 reform)
    2000000,  # CA: >$2M total revenue
    500000,   # CO: >$500K revenue (per CRS)
    500000,   # CT: >$500K total revenue (revised from $200K in 2021)
    500000,   # DC: >$500K
    NA,       # FL: no state audit mandate (registration only)
    500000,   # GA: >$500K contributions
    500000,   # HI: >$500K
    300000,   # IL: >$300K total revenue
    500000,   # KS: >$500K (per KSA 17-1763)
    500000,   # KY: >$500K
    500000,   # MA: >$500K
    500000,   # MD: >$500K contributions
    500000,   # ME: >$500K revenue (30-A MRSA §5405)
    500000,   # MI: >$500K contributions
    750000,   # MN: >$750K revenue (AG requirement)
    500000,   # MO: >$500K (per RSMo 407.462)
    500000,   # MS: >$500K
    500000,   # NC: >$500K contributions
    500000,   # NH: >$500K revenue
    500000,   # NJ: >$500K revenue
    500000,   # NM: >$500K
    750000,   # NY: >$750K total revenue (EPTL 8-1.4)
    500000,   # OH: >$500K
    500000,   # OK: >$500K
    500000,   # OR: >$500K (ORS 128.756)
    500000,   # PA: >$500K total revenue
    500000,   # RI: >$500K
    500000,   # SC: >$500K
    500000,   # TN: >$500K
    500000,   # UT: >$500K
    750000,   # VA: >$750K revenue (Virginia solicitation of contributions law)
    500000,   # WI: >$500K (revised threshold)
    500000    # WV: >$500K contributions
  ),
  has_audit = c(
    TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE,
    TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE,
    TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE
  )
)

## Remove FL (no mandate) and add info about states with no requirement
no_audit_states <- c("AK", "AZ", "DE", "FL", "IA", "ID", "IN", "LA",
                     "MT", "ND", "NE", "NV", "SD", "TX", "VT", "WA",
                     "WY")

## ── Merge thresholds onto BMF data ─────────────────────────────────────────
bmf_clean <- bmf[!is.na(revenue) & revenue > 0]
cat("Organizations with positive revenue:", format(nrow(bmf_clean), big.mark = ","), "\n")

## Merge
bmf_clean <- merge(bmf_clean, thresholds[has_audit == TRUE],
                   by.x = "STATE", by.y = "state", all.x = TRUE)

## Flag: in a state with audit mandate
bmf_clean[, has_audit_mandate := !is.na(threshold)]
bmf_clean[is.na(has_audit_mandate), has_audit_mandate := FALSE]

## For states without mandates, mark as "no threshold"
bmf_clean[STATE %in% no_audit_states, has_audit_mandate := FALSE]

cat("\nOrganizations by audit mandate status:\n")
cat("  With mandate:", format(sum(bmf_clean$has_audit_mandate), big.mark = ","), "\n")
cat("  Without mandate:", format(sum(!bmf_clean$has_audit_mandate), big.mark = ","), "\n")

## ── Create analysis-ready variables ────────────────────────────────────────
## Normalized revenue: distance from threshold (in dollars)
bmf_clean[has_audit_mandate == TRUE, dist_from_threshold := revenue - threshold]

## Normalized as fraction of threshold
bmf_clean[has_audit_mandate == TRUE, dist_pct := (revenue - threshold) / threshold]

## Revenue bins (for density estimation)
## Use $5,000 bins for most thresholds
bmf_clean[, rev_bin_5k := floor(revenue / 5000) * 5000]

## Log revenue for cross-state comparison
bmf_clean[revenue > 0, log_revenue := log(revenue)]

## ── Identify key threshold groups ──────────────────────────────────────────
## Group states by threshold level for pooled analysis
bmf_clean[threshold == 300000, threshold_group := "300K"]
bmf_clean[threshold == 500000, threshold_group := "500K"]
bmf_clean[threshold == 750000, threshold_group := "750K"]
bmf_clean[threshold == 2000000, threshold_group := "2M"]
bmf_clean[is.na(threshold), threshold_group := "None"]

cat("\nOrganizations by threshold group:\n")
print(bmf_clean[, .N, by = threshold_group][order(-N)])

## ── Focus on relevant revenue range for bunching analysis ──────────────────
## Keep organizations within a reasonable range of their state threshold
## For bunching: ±50% of threshold
bmf_analysis <- bmf_clean[
  has_audit_mandate == TRUE &
  abs(dist_pct) <= 0.50
]
cat("\nOrganizations within ±50% of threshold:", format(nrow(bmf_analysis), big.mark = ","), "\n")

## ── Save cleaned data ──────────────────────────────────────────────────────
fwrite(bmf_clean, file.path(data_dir, "bmf_clean.csv"))
fwrite(bmf_analysis, file.path(data_dir, "bmf_analysis.csv"))

## Summary stats
cat("\n== Summary Statistics ==\n")
cat("States with audit mandate:", length(unique(bmf_clean$STATE[bmf_clean$has_audit_mandate])), "\n")
cat("States without mandate:", length(unique(bmf_clean$STATE[!bmf_clean$has_audit_mandate])), "\n")
cat("Unique threshold levels:", length(unique(thresholds$threshold[!is.na(thresholds$threshold)])), "\n")
cat("Threshold range: $", format(min(thresholds$threshold, na.rm=TRUE), big.mark=","),
    "to $", format(max(thresholds$threshold, na.rm=TRUE), big.mark=","), "\n")

cat("\nDone cleaning.\n")
