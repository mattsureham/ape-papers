## 03_main_analysis.R — Primary regressions
## Cross-sectional boundary RDD: gained vs retained QPV zones

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("Analysis panel:", format(nrow(panel), big.mark = ","), "transactions\n")
cat("Groups:", paste(unique(panel$nearest_group), collapse = ", "), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")

# ── 1. Primary specification (boundary discontinuity) ────────────────────────
cat("\n=== Primary specification (500m bandwidth) ===\n")

bw <- 500
dt <- panel[dist_to_boundary <= bw]
cat("Transactions within", bw, "m:", format(nrow(dt), big.mark = ","), "\n")

# Model 1: Pooled boundary discontinuity (all QPV zones)
m1 <- feols(log_price_sqm ~ inside_int |
              nearest_boundary_id + transaction_year,
            data = dt, vcov = ~nearest_boundary_id)

# Model 2: Separate inside effects for gained vs retained
m2 <- feols(log_price_sqm ~ inside_x_gained + inside_x_retained |
              nearest_boundary_id + transaction_year,
            data = dt, vcov = ~nearest_boundary_id)

# Model 3: Add property controls and distance polynomial
m3 <- feols(log_price_sqm ~ inside_x_gained + inside_x_retained +
              log(surface) + rooms + is_apartment +
              signed_dist + I(signed_dist^2) |
              nearest_boundary_id + transaction_year,
            data = dt, vcov = ~nearest_boundary_id)

# Model 4: Add commune FE
m4 <- tryCatch(
  feols(log_price_sqm ~ inside_x_gained + inside_x_retained +
          log(surface) + rooms + is_apartment +
          signed_dist + I(signed_dist^2) |
          nearest_boundary_id + transaction_year + code_commune,
        data = dt, vcov = ~nearest_boundary_id),
  error = function(e) {
    cat("  Model 4 with commune FE failed:", e$message, "\n")
    cat("  Running without commune FE\n")
    m3  # Fallback
  }
)

cat("\n--- Model 1: Pooled inside effect ---\n")
print(summary(m1))
cat("\n--- Model 2: By group ---\n")
print(summary(m2))
cat("\n--- Model 3: With controls ---\n")
print(summary(m3))
cat("\n--- Model 4: With commune FE ---\n")
print(summary(m4))

# Save coefficients
key_coefs <- c("inside_x_gained", "inside_x_retained", "inside_int")
coefs_main <- data.table(
  model = character(), coefficient = character(),
  estimate = numeric(), se = numeric()
)
for (i in seq_along(list(m1, m2, m3, m4))) {
  mi <- list(m1, m2, m3, m4)[[i]]
  mn <- paste0("m", i)
  for (cf in key_coefs) {
    if (cf %in% names(coef(mi))) {
      coefs_main <- rbind(coefs_main, data.table(
        model = mn, coefficient = cf,
        estimate = coef(mi)[cf], se = se(mi)[cf]
      ))
    }
  }
}
fwrite(coefs_main, file.path(data_dir, "main_results.csv"))

# ── 2. Year-by-year stability ─────────────────────────────────────────────────
cat("\n=== Year-by-year estimates ===\n")

ref_year <- min(dt$transaction_year)

run_yearly <- function(dt, group_name) {
  dt_g <- dt[nearest_group == group_name]
  if (nrow(dt_g) < 100) return(NULL)

  dt_g[, yr_fac := relevel(factor(transaction_year), ref = as.character(ref_year))]
  es <- tryCatch(
    feols(log_price_sqm ~ i(yr_fac, inside_int) +
            inside_int + log(surface) + rooms + is_apartment |
            nearest_boundary_id,
          data = dt_g, vcov = ~nearest_boundary_id),
    error = function(e) { cat("  Yearly for", group_name, "failed:", e$message, "\n"); NULL }
  )
  if (is.null(es)) return(NULL)

  cf <- coeftable(es)
  es_rows <- grep("yr_fac", rownames(cf))
  if (length(es_rows) == 0) return(NULL)

  yrs <- as.integer(gsub(".*::(\\d+):.*", "\\1", rownames(cf)[es_rows]))
  es_dt <- data.table(
    group = group_name,
    year = yrs,
    estimate = cf[es_rows, "Estimate"],
    se = cf[es_rows, "Std. Error"]
  )
  es_dt <- rbind(es_dt, data.table(group = group_name, year = ref_year, estimate = 0, se = 0))
  setorder(es_dt, year)
  es_dt
}

es_gained <- run_yearly(dt, "gained")
es_retained <- run_yearly(dt, "retained")

event_study <- rbindlist(list(es_gained, es_retained), fill = TRUE)
event_study <- event_study[!is.na(year)]
event_study[, ci_lower := estimate - 1.96 * se]
event_study[, ci_upper := estimate + 1.96 * se]

fwrite(event_study, file.path(data_dir, "event_study.csv"))
cat("Year-by-year:", nrow(event_study), "group-year coefficients\n")

# ── 3. RDD at boundary (rdrobust) ───────────────────────────────────────────
cat("\n=== RDD at boundary ===\n")

run_rdd <- function(dt, group_name) {
  dt_g <- dt[nearest_group == group_name]
  if (nrow(dt_g) < 200) return(NULL)

  rdd <- tryCatch(
    rdrobust(y = dt_g$log_price_sqm, x = dt_g$signed_dist, c = 0),
    error = function(e) { cat("  RDD for", group_name, "failed:", e$message, "\n"); NULL }
  )
  if (!is.null(rdd)) {
    cat("\nRDD for", group_name, ":\n")
    print(summary(rdd))
  }
  rdd
}

rdd_gained <- run_rdd(panel, "gained")
rdd_retained <- run_rdd(panel, "retained")

rdd_results <- data.table(
  group = c("gained", "retained"),
  estimate = sapply(list(rdd_gained, rdd_retained),
                    function(r) if (!is.null(r)) r$coef["Conventional", 1] else NA_real_),
  se = sapply(list(rdd_gained, rdd_retained),
              function(r) if (!is.null(r)) r$se["Conventional", 1] else NA_real_),
  bw = sapply(list(rdd_gained, rdd_retained),
              function(r) if (!is.null(r)) r$bws["h", 1] else NA_real_),
  n_left = sapply(list(rdd_gained, rdd_retained),
                  function(r) if (!is.null(r)) r$N_h[1] else NA_integer_),
  n_right = sapply(list(rdd_gained, rdd_retained),
                   function(r) if (!is.null(r)) r$N_h[2] else NA_integer_)
)
fwrite(rdd_results, file.path(data_dir, "rdd_results.csv"))

# ── 4. Summary ──────────────────────────────────────────────────────────────
cat("\n=== KEY FINDINGS ===\n")
cat("Preferred spec (Model 3, 500m):\n")
for (k in c("inside_x_gained", "inside_x_retained")) {
  if (k %in% names(coef(m3))) {
    cat(sprintf("  %s: %.4f (SE: %.4f, p=%.3f)\n",
                k, coef(m3)[k], se(m3)[k], pvalue(m3)[k]))
  }
}
cat("N =", format(nrow(dt), big.mark = ","), "\n")

saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4),
        file.path(data_dir, "main_models.rds"))
