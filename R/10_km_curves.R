# Kaplan-Meier survival curves by PHQ-9 severity category

library(survival)
library(survey)

nhanes_design <- readRDS("data/derived/nhanes_design.rds")
design_km <- subset(nhanes_design, mortstat %in% c(0,1))

km_fit <- svykm(Surv(permth_exm, mortstat) ~ phq9_category, design =design_km)

png("docs/km_curves.png", width=1200, height=800, res=150)

plot(km_fit[[1]], col=1, xlab="Follow-up (months)", ylab= "Survival probability", ylim=c(0.7,1))
for (i in 2:5) {
lines(km_fit[[i]], col=i)
}
legend("bottomleft", legend=names(km_fit), col=1:5, lty=1)

dev.off()

cat("Kaplan-Meier curves saved to docs/km_curves.png\n")

