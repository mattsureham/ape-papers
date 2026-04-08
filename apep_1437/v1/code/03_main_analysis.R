source("00_packages.R")
dm <- fread("../data/panel_dept_month.csv")
dg <- fread("../data/panel_dept_grade_month.csv")

# 1) Time-series total: civilian vs military monthly totals
ts <- dm[, .(vacancies=sum(vacancies)), by=.(year,month,treated)]
ts[, time := year + (month-1)/12]
ts[, group := ifelse(treated==1, "Civilian (treated)", "Military (control)")]
fwrite(ts, "../data/ts_civ_mil.csv")

# 2) Main DiD: dept-month, log(1+vacancies) ~ treated*post
m1 <- feols(log_vac ~ i(post, treated, ref=0) | department + paste(year,month), data=dm,
            cluster = ~ department)
m2 <- feols(log_vac ~ treated:post | department + paste(year,month), data=dm,
            cluster = ~ department)
m3 <- feols(log_vac ~ treated:post | department, data=dm, cluster = ~ department)
# Levels (Poisson) robustness
m4 <- fepois(vacancies ~ treated:post | department + paste(year,month), data=dm,
             cluster = ~ department)

etable(m1, m2, m3, m4)

# 3) Event study (months relative to Feb 2025 = 0). Drop period -1 as base.
dm[, ev := pmin(pmax(period, -24), 2)]
es <- feols(log_vac ~ i(ev, treated, ref=-1) | department + paste(year,month), data=dm,
            cluster = ~ department)
es_coef <- as.data.frame(summary(es)$coeftable)
es_coef$term <- rownames(es_coef)
fwrite(es_coef, "../data/event_study.csv")

# 4) Grade composition: same DiD by grade bin
fit_grade <- function(gb){
  sub <- dg[grade_bin==gb]
  tryCatch(feols(log_vac ~ treated:post | department + paste(year,month), data=sub, cluster=~department),
           error=function(e){ message("skip ",gb,": ",e$message); NULL })
}
m_gs5  <- fit_grade("GS5_9")
m_gs10 <- fit_grade("GS10_12")
m_gs13 <- fit_grade("GS13plus")
m_oth  <- fit_grade("other")

# 5) Per-civilian-department effect (post coefficient by dept, military baseline)
dept_list <- sort(unique(dm[treated==1]$department))
het <- rbindlist(lapply(dept_list, function(d){
  sub <- dm[department %in% c(d, dm[treated==0, unique(department)])]
  fit <- feols(log_vac ~ treated:post | department + paste(year,month), data=sub, cluster=~department)
  ct <- coeftable(fit)
  data.table(department=d, est=ct[1,1], se=ct[1,2], pval=ct[1,4],
             pre_mean=mean(sub[treated==1 & post==0]$vacancies),
             post_mean=mean(sub[treated==1 & post==1]$vacancies))
}))
fwrite(het, "../data/het_dept.csv")

# Save main coefs for tables
main_coef <- coeftable(m2)
fwrite(data.table(term=rownames(main_coef), main_coef), "../data/main_coef.csv")
grow <- function(label, fit){
  if (is.null(fit)) return(data.table(grade=label, est=NA_real_, se=NA_real_, p=NA_real_))
  ct <- coeftable(fit); data.table(grade=label, est=ct[1,1], se=ct[1,2], p=ct[1,4])
}
gs_coefs <- rbindlist(list(
  grow("GS5-9",   m_gs5),
  grow("GS10-12", m_gs10),
  grow("GS13+",   m_gs13),
  grow("Other",   m_oth)
))
fwrite(gs_coefs, "../data/grade_coef.csv")

# Pre-trend test: joint F on pre-period interactions
prejoint <- wald(es, "ev::-")
saveRDS(list(prejoint=prejoint), "../data/wald.rds")
print(prejoint)

cat("\nMAIN treated:post coefficient (log vacancies):\n")
print(coeftable(m2))

# SDE: SD of log_vac across pooled obs
sd_y <- sd(dm$log_vac)
beta <- coeftable(m2)[1,1]; se <- coeftable(m2)[1,2]
sde <- beta / sd_y; sde_se <- se / sd_y
cat(sprintf("\nSDE (log vacancies): %.4f (SE %.4f); SD(Y)=%.3f\n", sde, sde_se, sd_y))

# Summary stats
ss <- dm[, .(N_dept_months=.N, depts=uniqueN(department), pre_mean=mean(vacancies[post==0]),
             post_mean=mean(vacancies[post==1])), by=treated]
fwrite(ss, "../data/summary.csv")
print(ss)
