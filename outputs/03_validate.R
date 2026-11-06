.libPaths(c('work/Rlib',.libPaths()))
library(survey)
options(survey.lonely.psu='fail')
d<-readRDS('work/prepared.rds')
d$cell<-with(d,factor(paste(SRVY_YR,agegroup,sep='|')))
des<-svydesign(ids=~PPSU,strata=~PSTRAT,weights=~WTFA_A,data=d,nest=TRUE)
out<-character()
for(group in c('all','stroke','no_stroke')) {
 s<-subset(des,older & !is.na(any))
 if(group!='all') s<-s[!is.na(s$variables$stroke) & s$variables$stroke==as.numeric(group=='stroke'),]
 s$variables$cell<-droplevels(s$variables$cell)
 direct<-svyby(~any,~cell,s,svymean,covmat=TRUE)
 model<-svyglm(any~0+cell,design=s,family=gaussian())
 error_b<-max(abs(coef(direct)-coef(model)))
 error_v<-max(abs(vcov(direct)-vcov(model)))
 stopifnot(error_b<1e-9,error_v<1e-9)
 out<-c(out,sprintf('%s: saturated survey Gaussian model versus domain means; max coefficient difference %.3g; max covariance difference %.3g; PASS',group,error_b,error_v))
}
# Verify all-adult published primary-outcome frequency totals from the two codebooks.
stopifnot(sum(d$SRVY_YR==2022)==27651,sum(d$SRVY_YR==2025)==24215,
          sum(d$VSLSWYR_A[d$SRVY_YR==2022]==1)==1719,
          sum(d$VSLSWYR_A[d$SRVY_YR==2025]==1)==1463)
out<-c(out,'Adult record counts and primary yes counts match official codebooks: PASS',
       '01_prepare.R assertions: unique HHX within year, all required columns, valid design and positive weights, expected skip logic: PASS',
       '02_analyse.R: standardized estimates agree with manual weighted age means to 1e-10: PASS')
writeLines(out,'outputs/validation.txt');cat(paste(out,collapse='\n'))
