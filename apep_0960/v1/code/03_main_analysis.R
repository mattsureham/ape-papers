## 03_main_analysis.R — DiD estimation: Zambia mining tax reform
## apep_0960

source("00_packages.R")

# ── 1. Load panel ────────────────────────────────────────────────────────
cat("Loading district panel...\n")
df <- readRDS("../data/district_panel.rds")

cat("Panel: ", nrow(df), "obs,", n_distinct(df$GID_2), "districts,",
    n_distinct(df$year), "years\n")
cat("Treated (mining=1):", n_distinct(df$GID_2[df$mining_district == 1]), "\n")
cat("Control (mining=0):", n_distinct(df$GID_2[df$mining_district == 0]), "\n")

# ── 2. Pre-treatment summary statistics ──────────────────────────────────
cat("\n=== Pre-treatment summary (2012-2018) ===\n")
pre <- df %>% filter(year < 2019)

pre_stats <- pre %>%
  group_by(mining_district) %>%
  summarise(
    n_districts = n_distinct(GID_2),
    mean_ntl = mean(ntl_mean),
    sd_ntl = sd(ntl_mean),
    mean_log_ntl = mean(log_ntl),
    sd_log_ntl = sd(log_ntl),
    mean_asinh_ntl = mean(asinh_ntl),
    sd_asinh_ntl = sd(asinh_ntl),
    .groups = "drop"
  )
print(pre_stats)

# SD of outcome for SDE computation
sd_y_pre_all <- sd(pre$asinh_ntl)
sd_y_pre_treated <- sd(pre$asinh_ntl[pre$mining_district == 1])
sd_y_pre_control <- sd(pre$asinh_ntl[pre$mining_district == 0])
cat("\nPre-treatment SD(asinh NTL):", sd_y_pre_all, "\n")

# ── 3. Main DiD specification ────────────────────────────────────────────
cat("\n=== Main DiD Results ===\n")

# Spec 1: Basic DiD with district + year FE
m1 <- feols(asinh_ntl ~ mining_district:post | GID_2 + year,
            data = df, vcov = ~GID_2)

# Spec 2: Using mining_province (broader treatment)
m2 <- feols(asinh_ntl ~ mining_province:post | GID_2 + year,
            data = df, vcov = ~GID_2)

# Spec 3: Log NTL
m3 <- feols(log_ntl ~ mining_district:post | GID_2 + year,
            data = df, vcov = ~GID_2)

# Spec 4: Controlling for copper price × mining interaction
m4 <- feols(asinh_ntl ~ mining_district:post + mining_district:copper_price |
              GID_2 + year,
            data = df, vcov = ~GID_2)

cat("\n--- Specification 1: asinh(NTL), mining district × post ---\n")
summary(m1)

cat("\n--- Specification 2: asinh(NTL), mining province × post ---\n")
summary(m2)

cat("\n--- Specification 3: log(NTL), mining district × post ---\n")
summary(m3)

cat("\n--- Specification 4: + copper price control ---\n")
summary(m4)

# ── 4. Event study ───────────────────────────────────────────────────────
cat("\n=== Event Study ===\n")

# Create event time dummies (omitting 2018 as reference)
df$event_time <- df$year - 2019
df$event_time_f <- factor(df$event_time)
df$event_time_f <- relevel(df$event_time_f, ref = "-1")

es <- feols(asinh_ntl ~ i(event_time_f, mining_district, ref = "-1") |
              GID_2 + year,
            data = df, vcov = ~GID_2)

cat("Event study coefficients:\n")
coeftable(es)

# Save event study coefficients for table
es_coefs <- as.data.frame(coeftable(es))
es_coefs$event_time <- as.numeric(gsub(".*::", "", gsub(":mining.*", "", rownames(es_coefs))))
saveRDS(es_coefs, "../data/event_study_coefs.rds")

# ── 5. Wild cluster bootstrap (few clusters) ─────────────────────────────
cat("\n=== Wild Cluster Bootstrap ===\n")

# Main spec with WCB
m1_lm <- lm(asinh_ntl ~ mining_district:post + factor(GID_2) + factor(year),
             data = df)

tryCatch({
  wcb <- boottest(
    m1_lm,
    param = "mining_district:post",
    clustid = ~GID_2,
    B = 9999,
    type = "webb"  # Webb weights — better with few clusters
  )
  cat("WCB p-value:", wcb$p_val, "\n")
  cat("WCB 95% CI: [", wcb$conf_int[1], ",", wcb$conf_int[2], "]\n")
  saveRDS(wcb, "../data/wcb_result.rds")
}, error = function(e) {
  cat("WCB error:", conditionMessage(e), "\n")
  # Fallback: just report cluster-robust SEs
  cat("Using cluster-robust SEs from fixest instead.\n")
})

# ── 6. Alternative treatment definitions ─────────────────────────────────
cat("\n=== Alternative Treatment Definitions ===\n")

# Copperbelt only (most intensive mining)
m_cb <- feols(asinh_ntl ~ copperbelt:post | GID_2 + year,
              data = df, vcov = ~GID_2)
cat("Copperbelt × Post:", coef(m_cb)["copperbelt:post"],
    " (", se(m_cb)["copperbelt:post"], ")\n")

# ── 7. Save diagnostics.json ─────────────────────────────────────────────
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = n_distinct(df$GID_2[df$mining_district == 1]),
  n_pre = length(unique(df$year[df$year < 2019])),
  n_obs = nrow(df),
  n_clusters = n_distinct(df$GID_2),
  n_control = n_distinct(df$GID_2[df$mining_district == 0]),
  sd_y_pre = sd_y_pre_all,
  main_coef = as.numeric(coef(m1)["mining_district:post"]),
  main_se = as.numeric(se(m1)["mining_district:post"])
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save all models
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, es = es, m_cb = m_cb),
        "../data/models.rds")

cat("\n=== Main analysis complete ===\n")
cat("Main effect (mining×post on asinh NTL):", diagnostics$main_coef, "\n")
cat("Clustered SE:", diagnostics$main_se, "\n")
