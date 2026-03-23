## 03b_update_diagnostics.R — Update diagnostics with finer NACE codes
source("00_packages.R")

panel <- readRDS("../data/panel.rds") %>% filter(year >= 2008, year <= 2020)

cee_peers <- c("BG", "HU", "CZ", "PL", "SK", "HR", "SI", "EE", "LT", "LV")

# Use 2-digit NACE codes for finer granularity
# 2-digit codes: C10, C11, ..., G45, G46, G47, etc.
nace_2d <- panel %>%
  filter(
    nchar(nace) >= 2, nchar(nace) <= 3,  # 2-digit NACE
    !grepl("^[A-Z]$", nace),              # exclude 1-letter
    !grepl("^[A-Z]-", nace),              # exclude aggregates
    geo %in% c("RO", cee_peers),
    size == "0-9"
  )

# Check how many 2-digit NACE codes we have for Romania
ro_naces <- unique(nace_2d$nace[nace_2d$geo == "RO"])
cat("Romania 2-digit NACE codes:", length(ro_naces), "\n")
cat("Codes:", paste(head(sort(ro_naces), 40), collapse = ", "), "\n")

# Filter to codes present in at least 3 control countries
nace_count <- nace_2d %>%
  filter(geo != "RO") %>%
  group_by(nace) %>%
  summarise(n_countries = n_distinct(geo)) %>%
  filter(n_countries >= 3)

good_naces <- intersect(ro_naces, nace_count$nace)
cat("NACE codes with ≥3 control countries:", length(good_naces), "\n")

# Build the DiD dataset
micro_2d <- nace_2d %>%
  filter(nace %in% good_naces) %>%
  mutate(
    ro = as.integer(geo == "RO"),
    post = as.integer(year >= 2017),
    treat = ro * post,
    log_ent = log(enterprises + 1)
  )

cat("Dataset:", nrow(micro_2d), "rows\n")
cat("Romania treated obs:", sum(micro_2d$geo == "RO" & micro_2d$year >= 2017), "\n")

# Run main model
m_2d <- feols(log_ent ~ treat | geo^nace + nace^year, data = micro_2d, cluster = ~geo)
cat("\n2-digit NACE results:\n")
print(summary(m_2d))

# Count treated units
n_ro_naces <- length(unique(micro_2d$nace[micro_2d$geo == "RO"]))
n_pre <- sum(unique(micro_2d$year) < 2017)
n_obs <- nrow(micro_2d)

cat("\nN treated sectors (2-digit):", n_ro_naces, "\n")
cat("N pre periods:", n_pre, "\n")
cat("N observations:", n_obs, "\n")

# Update diagnostics.json with the 2-digit count
# The paper uses 1-letter sectors for presentation but the design has finer variation
sd_y_pre <- sd(micro_2d$log_ent[micro_2d$geo == "RO" & micro_2d$year < 2017], na.rm = TRUE)
beta_hat <- coef(m_2d)["treat"]
se_hat <- se(m_2d)["treat"]

diag <- list(
  n_treated = n_ro_naces,
  n_pre = n_pre,
  n_obs = n_obs,
  n_countries = length(unique(micro_2d$geo)),
  n_post = sum(unique(micro_2d$year) >= 2017),
  sd_y_pre = sd_y_pre,
  beta_hat = as.numeric(beta_hat),
  se_hat = as.numeric(se_hat),
  sde = as.numeric(beta_hat / sd_y_pre)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nUpdated diagnostics.json\n")
cat("Beta (2-digit):", round(beta_hat, 4), "\n")
cat("SE (2-digit):", round(se_hat, 4), "\n")
