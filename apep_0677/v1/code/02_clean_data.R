## 02_clean_data.R — Clean and construct panel for EUDR DDD analysis

source("code/00_packages.R")

cat("=== CLEANING COMTRADE DATA ===\n")

raw <- fread("data/comtrade_raw.csv")
cat(sprintf("Loaded %d rows\n", nrow(raw)))

stopifnot("primaryValue" %in% names(raw))
stopifnot(nrow(raw) > 0)

# ── Define treatment variables ─────────────────────────────────────
regulated_codes <- c("0102", "0901", "1201", "1511", "1801", "4001", "4403")

# ── Clean variables ────────────────────────────────────────────────
dt <- copy(raw)
dt[, trade_value := as.numeric(primaryValue)]
dt[, trade_qty := as.numeric(netWgt)]
dt[, year := as.integer(period)]
dt[, reporter_code := as.integer(reporterCode)]
dt[, partner_code := as.integer(partnerCode)]
# Pad cmdCode to 4 digits
dt[, hs4 := sprintf("%04d", as.integer(cmdCode))]

# Drop missing/zero trade values
dt <- dt[!is.na(trade_value) & trade_value > 0]

cat(sprintf("After cleaning: %d rows\n", nrow(dt)))
cat(sprintf("Dest groups present: %s\n", paste(unique(dt$dest_group), collapse = ", ")))

# ── Treatment indicators ──────────────────────────────────────────
dt[, regulated := as.integer(hs4 %in% regulated_codes)]

# ── Aggregate EU-27 individual country records to EU-27 total ─────
# EU records come as individual country rows — aggregate to EU-27 total
# Also aggregate World and China (already single partner but confirm)

panel <- dt[, .(
  trade_value = sum(trade_value, na.rm = TRUE),
  trade_qty = sum(trade_qty, na.rm = TRUE),
  n_partners = uniqueN(partner_code)
), by = .(reporter_code, reporterDesc, hs4, cmdDesc, dest_group, year, regulated)]

cat(sprintf("Panel rows after aggregation: %d\n", nrow(panel)))

# ── Compute "Other" destination as World minus EU minus China ──────
# Reshape to wide by dest_group, compute residual
wide <- dcast(panel, reporter_code + reporterDesc + hs4 + cmdDesc + year + regulated ~ dest_group,
              value.var = c("trade_value", "trade_qty"),
              fill = 0)

# Compute Other = World - EU-27 - China (floored at 0)
if ("trade_value_World" %in% names(wide)) {
  wide[, `trade_value_Other` := pmax(0, trade_value_World - `trade_value_EU-27` - trade_value_China)]
  wide[, `trade_qty_Other` := pmax(0, trade_qty_World - `trade_qty_EU-27` - trade_qty_China)]
}

# Melt back to long
id_vars <- c("reporter_code", "reporterDesc", "hs4", "cmdDesc", "year", "regulated")
value_cols <- grep("^trade_value_|^trade_qty_", names(wide), value = TRUE)
value_cols <- value_cols[!grepl("World", value_cols)]

panel_long <- rbindlist(lapply(c("EU-27", "China", "Other"), function(dg) {
  val_col <- paste0("trade_value_", dg)
  qty_col <- paste0("trade_qty_", dg)
  if (!val_col %in% names(wide)) return(NULL)
  out <- wide[, c(id_vars, val_col, qty_col), with = FALSE]
  setnames(out, c(val_col, qty_col), c("trade_value", "trade_qty"))
  out[, dest_group := dg]
  out
}))

cat(sprintf("Panel with Other computed: %d rows\n", nrow(panel_long)))

# ── Post and interaction indicators ────────────────────────────────
panel_long[, eu_dest := as.integer(dest_group == "EU-27")]
panel_long[, china_dest := as.integer(dest_group == "China")]
panel_long[, post_proposal := as.integer(year >= 2022)]
panel_long[, post_passage := as.integer(year >= 2023)]
panel_long[, ddd_proposal := regulated * eu_dest * post_proposal]
panel_long[, ddd_passage := regulated * eu_dest * post_passage]

# Log outcomes
panel_long[, ln_value := log(trade_value + 1)]
panel_long[, ln_qty := log(trade_qty + 1)]

# Fixed effect identifiers
panel_long[, cmd_dest := paste0(hs4, "_", dest_group)]
panel_long[, cmd_year := paste0(hs4, "_", year)]
panel_long[, dest_year := paste0(dest_group, "_", year)]
panel_long[, reporter_cmd := paste0(reporter_code, "_", hs4)]

# ── EU share computation (using World vs EU totals) ────────────────
world_dt <- dt[dest_group == "World", .(total_value = sum(trade_value, na.rm = TRUE)),
               by = .(reporter_code, hs4, year)]
eu_dt <- dt[dest_group == "EU-27", .(eu_value = sum(trade_value, na.rm = TRUE)),
            by = .(reporter_code, hs4, year)]
shares <- merge(world_dt, eu_dt, by = c("reporter_code", "hs4", "year"), all.x = TRUE)
shares[is.na(eu_value), eu_value := 0]
shares[, eu_share := eu_value / total_value]
shares[is.nan(eu_share), eu_share := 0]
shares[, regulated := as.integer(hs4 %in% regulated_codes)]
shares[, post_proposal := as.integer(year >= 2022)]
shares[, post_passage := as.integer(year >= 2023)]

# ── Summary ────────────────────────────────────────────────────────
cat(sprintf("\n=== PANEL SUMMARY ===\n"))
cat(sprintf("Panel rows: %d\n", nrow(panel_long)))
cat(sprintf("Exporters: %d\n", uniqueN(panel_long$reporter_code)))
cat(sprintf("Commodities: %d (regulated: %d, control: %d)\n",
            uniqueN(panel_long$hs4),
            uniqueN(panel_long[regulated == 1]$hs4),
            uniqueN(panel_long[regulated == 0]$hs4)))
cat(sprintf("Destinations: %s\n", paste(unique(panel_long$dest_group), collapse = ", ")))
cat(sprintf("Years: %s\n", paste(range(panel_long$year), collapse = "-")))

# EU share trends
cat("\n=== EU SHARE TRENDS (regulated commodities) ===\n")
eu_trend <- shares[regulated == 1, .(mean_eu_share = round(mean(eu_share, na.rm = TRUE), 3)),
                   by = year]
setorder(eu_trend, year)
print(eu_trend)

cat("\n=== EU SHARE TRENDS (control commodities) ===\n")
ctrl_trend <- shares[regulated == 0, .(mean_eu_share = round(mean(eu_share, na.rm = TRUE), 3)),
                     by = year]
setorder(ctrl_trend, year)
print(ctrl_trend)

# ── Save ───────────────────────────────────────────────────────────
fwrite(panel_long, "data/panel.csv")
fwrite(shares, "data/eu_shares.csv")
cat("\nSaved: data/panel.csv, data/eu_shares.csv\n")
