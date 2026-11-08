# Revised primary analysis, 8 November 2026. Run from project root after
# outputs/01_prepare.R. Original data and previous >=65-year results are unchanged.
# This script requires the dated, frozen revised analysis plan before execution.
if (.Platform$OS.type == 'windows') Sys.setlocale('LC_CTYPE','English_United States.utf8')
.libPaths(c('work/Rlib',.libPaths()))
suppressPackageStartupMessages(library(survey))
options(survey.lonely.psu='fail')
outdir <- 'outputs/all_adults'
dir.create(outdir,recursive=TRUE,showWarnings=FALSE)
dir.create('work/all_adults',recursive=TRUE,showWarnings=FALSE)
stopifnot(file.exists(file.path(outdir,'Analysis_Plan_Freeze.txt')))
write_tsv <- function(x,name) write.table(x,file.path(outdir,name),sep='\t',row.names=FALSE,na='NA')
validation <- character()
d <- readRDS('work/prepared.rds')
stopifnot(nrow(d)==27651+24215,all(d$WTFA_A>0),!anyNA(d[c('PSTRAT','PPSU','WTFA_A')]))
stopifnot(sum(d$SRVY_YR==2022 & d$VSLSWYR_A==1)==1719,
          sum(d$SRVY_YR==2025 & d$VSLSWYR_A==1)==1463)
d$adult <- d$AGEP_A %in% 18:85
d$agegroup <- cut(d$AGEP_A,breaks=c(17,44,64,74,84,85),
                  labels=c('18-44','45-64','65-74','75-84','85+'))
d$year <- factor(d$SRVY_YR,levels=c(2022,2025))
d$sex <- factor(ifelse(d$SEX_A %in% 1:2,d$SEX_A,NA),levels=1:2,labels=c('male','female'))
d$stroke_group <- factor(ifelse(is.na(d$stroke),NA,ifelse(d$stroke==1,'stroke','no_stroke')),
                         levels=c('no_stroke','stroke'))
d$missing_primary <- as.numeric(is.na(d$any))
d$low <- ifelse(is.na(d$any),0,d$any)
d$high <- ifelse(is.na(d$any),1,d$any)
d$opposite_low <- ifelse(is.na(d$any),as.numeric(d$SRVY_YR==2022),d$any)
d$opposite_high <- ifelse(is.na(d$any),as.numeric(d$SRVY_YR==2025),d$any)

# Response status is not identically identified across years. Unknown status is
# excluded only in the self-response sensitivity analysis.
d$AVAIL_A <- d$PROXY_A <- d$PROXYFLAG_A <- NA_integer_
for (yr in c(2022,2025)) {
  csv <- sprintf('outputs/data_original/adult%s.csv',substr(yr,3,4))
  header <- names(read.csv(csv,nrows=0,check.names=FALSE))
  keep <- c('HHX','SRVY_YR',if(yr==2022)c('AVAIL_A','PROXY_A') else 'PROXYFLAG_A')
  classes <- setNames(rep('NULL',length(header)),header)
  classes[keep] <- 'numeric'; classes['HHX'] <- 'character'
  x <- read.csv(csv,colClasses=classes,na.strings=c('','NA'),check.names=FALSE)
  ix <- which(d$SRVY_YR==yr); m <- match(d$HHX[ix],x$HHX)
  stopifnot(nrow(x)==length(ix),!anyNA(m),!anyDuplicated(x$HHX),all(x$SRVY_YR==yr))
  for (v in setdiff(keep,c('HHX','SRVY_YR'))) d[ix,v] <- x[m,v]
}
d$proxy_status <- 'unknown'
i22 <- d$SRVY_YR==2022; i25 <- d$SRVY_YR==2025
stopifnot(!any(i22 & d$AVAIL_A %in% c(1,2) & !is.na(d$PROXY_A)))
d$proxy_status[i22 & d$AVAIL_A %in% 1 & is.na(d$PROXY_A)] <- 'self'
d$proxy_status[i22 & d$AVAIL_A %in% 3 & d$PROXY_A %in% 1] <- 'proxy'
d$proxy_status[i25 & d$PROXYFLAG_A %in% 2] <- 'self'
d$proxy_status[i25 & d$PROXYFLAG_A %in% 1] <- 'proxy'

# CDC/NCHS US 2000 standard population, restricted to ages >=18.
# https://www.cdc.gov/nchs/hus/sources-definitions/age-adjustment.htm
std_n <- c('18-44'=108151050,'45-64'=60991658,'65-74'=18135514,'75-84'=12314793,'85+'=4259173)
stopifnot(sum(std_n)==203852188)
std <- std_n/sum(std_n)
write_tsv(data.frame(agegroup=names(std),population_2000=unname(std_n),weight=unname(std)),
          'age_standard.tsv')
ref <- expand.grid(agegroup=names(std),sex=c('male','female'),stringsAsFactors=FALSE)
ref$weight <- std[ref$agegroup]*.5
write_tsv(ref,'age_sex_reference.tsv')

# Full adult survey design precedes every domain restriction. For public-use
# NHIS data since 2019 NCHS explicitly says not to differentiate strata by year.
des <- svydesign(ids=~PPSU,strata=~PSTRAT,weights=~WTFA_A,data=d,nest=TRUE)
adult <- subset(des,adult)
domain <- function(obj,gr) {
  if (gr=='all') obj else obj[!is.na(obj$variables$stroke_group) & obj$variables$stroke_group==gr,]
}
write_tsv(do.call(rbind,lapply(c(2022,2025),function(y) {
  z <- d[d$SRVY_YR==y,]
  data.frame(year=y,raw_n=nrow(z),unknown_age=sum(!z$adult),adult_known_age=sum(z$adult),
    primary_valid=sum(z$adult & !is.na(z$any)),primary_yes=sum(z$adult & z$any==1,na.rm=TRUE),
    primary_missing=sum(z$adult & is.na(z$any)),stroke_records=sum(z$adult & z$stroke==1,na.rm=TRUE),
    stroke_primary_valid=sum(z$adult & z$stroke==1 & !is.na(z$any),na.rm=TRUE),
    stroke_primary_yes=sum(z$adult & z$stroke==1 & z$any==1,na.rm=TRUE),
    stroke_unknown=sum(z$adult & is.na(z$stroke)),sex_unknown=sum(z$adult & is.na(z$sex)))
})),'sample_flow.tsv')
cells <- list(); k <- 0
for (yr in c(2022,2025)) for (gr in c('all','stroke','no_stroke'))
  for (ps in c('all','self','proxy','unknown')) for (ag in c('all',names(std))) {
    z <- d[d$adult & d$SRVY_YR==yr,]
    if (gr!='all') z <- z[!is.na(z$stroke_group) & z$stroke_group==gr,]
    if (ps!='all') z <- z[z$proxy_status==ps,]
    if (ag!='all') z <- z[z$agegroup==ag,]
    for (v in c('any','severe','long')) {
      k <- k+1
      cells[[k]] <- data.frame(year=yr,group=gr,proxy_status=ps,agegroup=ag,outcome=v,n=nrow(z),
        valid=sum(!is.na(z[[v]])),yes=sum(z[[v]]==1,na.rm=TRUE),no=sum(z[[v]]==0,na.rm=TRUE),
        missing=sum(is.na(z[[v]])),sex_missing=sum(is.na(z$sex)),
        fragile=sum(!is.na(z[[v]]))<30 || sum(z[[v]]==1,na.rm=TRUE)<10 || sum(z[[v]]==0,na.rm=TRUE)<10)
    }
  }
celltab <- do.call(rbind,cells); write_tsv(celltab,'cell_counts.tsv')
write_tsv(do.call(rbind,lapply(c(2022,2025),function(y) {
  z <- d[d$SRVY_YR==y,]
  as.data.frame(table(year=rep(y,nrow(z)),AVAIL_A=ifelse(is.na(z$AVAIL_A),'NA',z$AVAIL_A),
    PROXY_A=ifelse(is.na(z$PROXY_A),'NA',z$PROXY_A),
    PROXYFLAG_A=ifelse(is.na(z$PROXYFLAG_A),'NA',z$PROXYFLAG_A),proxy_status=z$proxy_status))
})),'proxy_raw_code_audit.tsv')

results <- list(); kr <- 0
add_result <- function(method,gr,outcome,label,est,se,df,n=NA,events=NA,fragile=FALSE,isprev=FALSE,
                       agegroup='all',model_id='') {
  stopifnot(all(is.finite(c(est,se,df))),se>=0,df>=8)
  crit <- qt(.975,df)
  if (isprev && est>0 && est<1) ci <- plogis(qlogis(est)+c(-1,1)*crit*se/(est*(1-est)))
  else ci <- est+c(-1,1)*crit*se
  kr <<- kr+1
  results[[kr]] <<- data.frame(analysis=method,group=gr,outcome=outcome,agegroup=agegroup,
    estimate_type=label,estimate=est,se=se,lcl=ci[1],ucl=ci[2],df=df,n=n,events=events,
    rse=if(isprev && est>0)se/est else NA,
    fragile=fragile || (isprev && est>0 && se/est>.30),
    p=if(isprev || se==0)NA else 2*pt(-abs(est/se),df),model_id=model_id)
}
direct <- function(obj,variable,gr='all',method='main',interaction=FALSE,standard=std,save_cov=FALSE) {
  s <- obj[!is.na(obj$variables[[variable]]),]
  if (interaction) s <- subset(s,!is.na(stroke_group)) else s <- domain(s,gr)
  s$variables$y <- s$variables[[variable]]
  s$variables$cell <- with(s$variables,factor(paste(year,agegroup,if(interaction)stroke_group else gr,sep='|')))
  b <- svyby(~y,~cell,s,svymean,covmat=TRUE,keep.var=TRUE)
  labs <- as.character(b$cell); beta <- coef(b); V <- vcov(b); df <- degf(s)
  stopifnot(all(is.finite(V)))
  if (save_cov) {
    sat <- svyglm(y~0+cell,s,family=gaussian())
    eb <- max(abs(coef(sat)-beta)); ev <- max(abs(vcov(sat)-V))
    stopifnot(eb<1e-8,ev<1e-8)
    validation <<- c(validation,sprintf('%s/%s/%s: Gaussian saturated vs domain mean max coefficient error %.3g; covariance error %.3g PASS',method,gr,variable,eb,ev))
    write_tsv(data.frame(cell=labs,estimate=unname(beta)),paste(method,gr,variable,'cell_estimates.tsv',sep='_'))
    write_tsv(data.frame(cell=labs,V,check.names=FALSE),paste(method,gr,variable,'cell_covariance.tsv',sep='_'))
  }
  cv <- function(yr,g) {
    z <- numeric(length(beta)); ix <- match(paste(yr,names(standard),g,sep='|'),labs)
    stopifnot(!anyNA(ix)); z[ix] <- standard; z
  }
  cr <- function(v,label,isprev=FALSE,n=NA,events=NA,fragile=FALSE) {
    add_result(method,gr,variable,label,sum(v*beta),sqrt(drop(t(v)%*%V%*%v)),df,n,events,fragile,isprev)
  }
  if (interaction) {
    target_proxy <- if(method=='self_direct_age_standardized')'self' else 'all'
    fr <- any(subset(celltab,proxy_status==target_proxy &
                       group!='all' & agegroup!='all' & outcome==variable)$fragile)
    cr(cv(2025,'stroke')-cv(2022,'stroke')-cv(2025,'no_stroke')+cv(2022,'no_stroke'),
       'difference_in_differences',fragile=fr)
  } else {
    anyfrag <- FALSE
    for (yr in c(2022,2025)) {
      z <- s$variables[s$variables$SRVY_YR==yr,]
      cs <- split(z,droplevels(z$agegroup))
      fr <- any(sapply(cs,function(a)nrow(a)<30 || sum(a$y)<10 || sum(a$y==0)<10)); anyfrag <- anyfrag||fr
      cr(cv(yr,gr),paste0('standardized_',yr),TRUE,nrow(z),sum(z$y),fr)
      manual <- sum(standard*sapply(names(standard),function(ag){a<-z[z$agegroup==ag,];weighted.mean(a$y,a$WTFA_A)}))
      stopifnot(abs(manual-sum(cv(yr,gr)*beta))<1e-10)
    }
    cr(cv(2025,gr)-cv(2022,gr),'difference_2025_minus_2022',fragile=anyfrag)
  }
}

for (gr in c('all','stroke','no_stroke')) {
  for (v in c('any','severe','long')) direct(adult,v,gr,save_cov=TRUE)
  direct(subset(adult,quarter %in% 1:3),'any',gr,'Q1_Q3',save_cov=TRUE)
  direct(subset(adult,proxy_status=='self'),'any',gr,'self_direct_age_standardized',save_cov=TRUE)
  for (v in c('low','high','opposite_low','opposite_high')) direct(adult,v,gr,'missing_bounds')
}
direct(adult,'any','stroke_vs_no_stroke','main',TRUE,save_cov=TRUE)
direct(subset(adult,proxy_status=='self'),'any','stroke_vs_no_stroke','self_direct_age_standardized',TRUE,save_cov=TRUE)

# Crude contrasts retain covariance between year-specific estimates. An
# all-records variant includes adults of unknown exact age, as survey eligibility
# itself establishes adulthood; primary standardization requires a valid age.
crude <- function(obj,gr,v='any',method='crude',ag='all') {
  s <- domain(obj,gr); s <- s[!is.na(s$variables[[v]]),]; s$variables$y <- s$variables[[v]]
  b <- svyby(~y,~year,s,svymean,covmat=TRUE); V <- vcov(b); est <- coef(b); df <- degf(s)
  for (i in 1:2) {
    yr <- c(2022,2025)[i]; z <- s$variables[s$variables$SRVY_YR==yr,]
    stopifnot(abs(weighted.mean(z$y,z$WTFA_A)-est[i])<1e-10)
    add_result(method,gr,v,paste0('crude_',yr),est[i],sqrt(V[i,i]),df,nrow(z),sum(z$y),
      nrow(z)<30 || sum(z$y)<10 || sum(z$y==0)<10,TRUE,ag)
  }
  cv <- c(-1,1)
  add_result(method,gr,v,'difference_2025_minus_2022',sum(cv*est),sqrt(drop(t(cv)%*%V%*%cv)),df,agegroup=ag,
    fragile=any(sapply(split(s$variables,s$variables$year),function(z)nrow(z)<30 || sum(z$y)<10 || sum(z$y==0)<10)))
}
for (gr in c('all','stroke','no_stroke')) {
  for (v in c('any','severe','long','missing_primary')) crude(adult,gr,v)
  crude(des,gr,method='crude_including_unknown_age')
  for (ag in names(std)) crude(subset(adult,agegroup==ag),gr,ag=ag,method='age_specific')
  for (ag in c('18-64','65+')) {
    ss <- if(ag=='18-64')subset(adult,AGEP_A<65) else subset(adult,AGEP_A>=65)
    crude(ss,gr,ag=ag,method='broad_age_specific')
  }
}

# Age/sex sensitivity, standardized to a fixed hypothetical population with the
# same age weights and 50% each sex. The grouped model allows distinct age and sex
# associations by stroke status and has the same group-specific fitted values as
# separate regressions, while preserving cross-group covariance for interaction.
models <- list(); km <- 0
run_models <- function(obj,method) {
  for (which in c('overall','stroke','no_stroke','stroke_groups')) {
    s <- subset(obj,!is.na(any)&!is.na(sex))
    if(which %in% c('stroke','no_stroke'))s <- domain(s,which)
    if(which=='stroke_groups')s <- subset(s,!is.na(stroke_group))
    form <- if(which!='stroke_groups')any~year+agegroup+sex else any~year*stroke_group+agegroup*stroke_group+sex*stroke_group
    fit <- svyglm(form,design=s,family=quasibinomial())
    stopifnot(fit$converged,all(is.finite(coef(fit))),all(is.finite(vcov(fit))),fit$df.residual>=8)
    model_id <- paste(method,which,sep='_'); df <- fit$df.residual; b <- coef(fit); V <- vcov(fit)
    capture.output(summary(fit),file=file.path(outdir,paste0(model_id,'_model.txt')))
    write_tsv(data.frame(term=names(b),estimate=unname(b)),paste0(model_id,'_coefficients.tsv'))
    write_tsv(data.frame(term=rownames(V),V,check.names=FALSE),paste0(model_id,'_coefficient_covariance.tsv'))
    groups <- if(which=='overall')'all' else if(which=='stroke_groups')c('no_stroke','stroke') else which
    estimates <- list(); gradients <- list(); meta <- list(); m <- 0
    for(gr in groups)for(yr in c(2022,2025)) {
      nd <- ref; nd$year <- factor(yr,levels=c(2022,2025))
      nd$agegroup <- factor(nd$agegroup,levels=names(std)); nd$sex <- factor(nd$sex,levels=c('male','female'))
      nd$stroke_group <- factor(if(gr=='all')'no_stroke' else gr,levels=c('no_stroke','stroke'))
      X <- model.matrix(delete.response(terms(fit)),nd,contrasts.arg=fit$contrasts,xlev=fit$xlevels)[,names(b),drop=FALSE]
      pp <- plogis(drop(X%*%b)); est <- sum(ref$weight*pp)
      g <- colSums(X*as.numeric(ref$weight*pp*(1-pp)))
      ng <- numDeriv::grad(function(bb)sum(ref$weight*plogis(drop(X%*%bb))),b)
      stopifnot(max(abs(ng-g))<1e-7,
                abs(sum(ref$weight*as.numeric(predict(fit,newdata=nd,type='response',se.fit=FALSE)))-est)<1e-10)
      z <- s$variables[s$variables$SRVY_YR==yr,]; if(gr!='all')z <- z[z$stroke_group==gr,]
      if(which!='stroke_groups')add_result(method,gr,'any',paste0('standardized_',yr),est,sqrt(drop(t(g)%*%V%*%g)),df,nrow(z),sum(z$any),
        isprev=TRUE,model_id=model_id)
      m <- m+1; estimates[[m]] <- est; gradients[[m]] <- g; meta[[m]] <- data.frame(group=gr,year=yr)
      validation <<- c(validation,sprintf('%s/%s/%s: marginal gradient numerical error %.3g; predict agreement PASS',model_id,gr,yr,max(abs(ng-g))))
    }
    beta <- unlist(estimates); G <- do.call(rbind,gradients); PV <- G%*%V%*%t(G); mt <- do.call(rbind,meta)
    labs <- paste(mt$group,mt$year,sep='|'); rownames(PV)<-colnames(PV)<-labs
    write_tsv(data.frame(margin=labs,PV,check.names=FALSE),paste0(model_id,'_margin_covariance.tsv'))
    cv <- function(gr){v<-numeric(length(beta));v[mt$group==gr & mt$year==2025]<-1;v[mt$group==gr & mt$year==2022]<- -1;v}
    cr <- function(v,gr,label)add_result(method,gr,'any',label,sum(v*beta),sqrt(drop(t(v)%*%PV%*%v)),df,model_id=model_id)
    if(which!='stroke_groups')for(gr in groups)cr(cv(gr),gr,'difference_2025_minus_2022')
    if(which=='stroke_groups')cr(cv('stroke')-cv('no_stroke'),'stroke_vs_no_stroke','difference_in_differences')
    km <<- km+1; models[[km]] <<- data.frame(model_id=model_id,formula=paste(deparse(form),collapse=''),
      n=nrow(s$variables),events=sum(s$variables$any),design_df=degf(s),model_df=df,rank=fit$rank,
      converged=fit$converged,min_fitted=min(fitted(fit)),max_fitted=max(fitted(fit)))
  }
}
run_models(adult,'age_sex_adjusted')
run_models(subset(adult,proxy_status=='self'),'self_age_sex_adjusted')

ans <- do.call(rbind,results); write_tsv(ans,'all_results.tsv')
write_tsv(subset(ans,analysis=='main'),'standardized_results.tsv')
write_tsv(subset(ans,analysis %in% c('crude','crude_including_unknown_age')),'crude_results.tsv')
write_tsv(subset(ans,analysis %in% c('age_specific','broad_age_specific')),'age_specific_results.tsv')
write_tsv(subset(ans,outcome=='any' & agegroup=='all' & !analysis %in% c('crude_including_unknown_age','age_specific','broad_age_specific')),
          'primary_comparison_all_methods.tsv')
write_tsv(do.call(rbind,models),'model_audit.tsv')
summaryrows <- list(); k <- 0
for (method in c('main','crude','Q1_Q3','self_direct_age_standardized','age_sex_adjusted','self_age_sex_adjusted'))
  for (gr in c('all','stroke','no_stroke')) for(v in if(method %in% c('main','crude'))c('any','severe','long') else 'any') {
    ss <- subset(ans,analysis==method & group==gr & outcome==v & agegroup=='all')
    a <- ss[grepl('_2022$',ss$estimate_type) & ss$estimate_type!='difference_2025_minus_2022',]
    b <- ss[grepl('_2025$',ss$estimate_type),]; dif <- ss[ss$estimate_type=='difference_2025_minus_2022',]
    stopifnot(nrow(a)==1,nrow(b)==1,nrow(dif)==1)
    k<-k+1;summaryrows[[k]] <- data.frame(analysis=method,group=gr,outcome=v,
      prevalence_2022_pct=100*a$estimate,prevalence_2022_lcl_pct=100*a$lcl,prevalence_2022_ucl_pct=100*a$ucl,
      prevalence_2025_pct=100*b$estimate,prevalence_2025_lcl_pct=100*b$lcl,prevalence_2025_ucl_pct=100*b$ucl,
      difference_pp=100*dif$estimate,difference_lcl_pp=100*dif$lcl,difference_ucl_pp=100*dif$ucl,p=dif$p,
      n_2022=a$n,events_2022=a$events,n_2025=b$n,events_2025=b$events,fragile=a$fragile|b$fragile|dif$fragile)
  }
summ <- do.call(rbind,summaryrows); write_tsv(summ,'manuscript_summary_percent_units.tsv')
write.csv(summ,file.path(outdir,'Analysis_Results.csv'),row.names=FALSE,na='')

# Weighted demographics in each year and domain; denominator excludes missing
# information for the corresponding variable only.
demo <- list(); k <- 0
for(gr in c('all','stroke','no_stroke'))for(yr in c(2022,2025))for(v in c('agegroup','sex','proxy_status')) {
  s <- domain(subset(adult,SRVY_YR==yr),gr); s <- s[!is.na(s$variables[[v]]),]
  levels <- sort(unique(as.character(s$variables[[v]])))
  for(lev in levels) {
    s$variables$z <- as.numeric(s$variables[[v]]==lev); b <- svymean(~z,s)
    k<-k+1;demo[[k]] <- data.frame(year=yr,group=gr,variable=v,level=lev,n=nrow(s$variables),
      count=sum(s$variables$z),weighted_proportion=as.numeric(b),se=as.numeric(SE(b)))
  }
}
write_tsv(do.call(rbind,demo),'weighted_demographics.tsv')
audit <- do.call(rbind,lapply(c(2022,2025),function(y){z<-d[d$SRVY_YR==y,];data.frame(year=y,strata=length(unique(z$PSTRAT)),
  psus=nrow(unique(z[c('PSTRAT','PPSU')])))}))
write_tsv(audit,'design_audit.tsv')
writeLines(c('Revised PRIMARY analysis of all adults with known age >=18 years, followed by separate stroke analysis.',
  'Study hierarchy revised after the earlier >=65-year results had been inspected; no prospective preregistration is claimed.',
  'Primary direct age standard: US2000 adult population with 5 age categories, identical in all domains/years.',
  'Model sensitivity reference is hypothetical: US2000 adult age weights crossed with 50% male and 50% female.',
  'Crude levels describe actual annual weighted respondent populations; age-standardized levels describe a fixed age distribution.',
  'Full adult design declared before age/outcome/stroke/response-status domains; annual WTFA_A unchanged.',
  'PSTRAT/PPSU not prefixed by year, following NCHS2025 guidance for public-use files since2019.',
  'Cross-year and cross-group covariance retained. No singleton-PSU adjustment applied.',
  'Q1-Q3 sensitivity retains annual weights; it does not represent separately recalibrated 9-month population estimates.',
  'Sparse-cell flags: any contributing age cell n<30, events<10 or nonevents<10; also prevalence RSE>30%. Not a full NCHS publication reliability assessment.',
  'Stroke estimates include the sparse 18-44-year age cells. Precision flags are reported, not used to redefine the primary analysis.',
  'Self-only2022 requires AVAIL_A=1 and missing PROXY_A. Self-only2025 requires PROXYFLAG_A=2. Classification is asymmetric.',
  'Low/high missing-outcome scenarios assume all missing outcomes negative/positive in both years. Opposite scenarios assign all missing2022 positive and2025 negative, or viceversa.',
  'Any, severe, and long-duration outcomes are population prevalences; severe=a lot of difficulty, long>=180 days in previous year.',
  unique(validation),
  'Manual weighted age-cell arithmetic agrees with every direct standardized point estimate to1e-10.',
  'All raw record counts and any-swallowing-positive counts match NCHS codebooks.',
  paste('Prepared data MD5:',unname(tools::md5sum('work/prepared.rds'))),
  paste('Frozen plan MD5:',unname(tools::md5sum(file.path(outdir,'Analysis_Plan_Freeze.txt'))))),
  file.path(outdir,'validation_and_methods.txt'))
saveRDS(list(data=d,standard=std,results=ans,summary=summ),'work/all_adults/analysis_results.rds')
capture.output(sessionInfo(),file=file.path(outdir,'session_analysis.txt'))
print(subset(summ,analysis %in% c('main','crude') & outcome=='any'),digits=6,row.names=FALSE)
