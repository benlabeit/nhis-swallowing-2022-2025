# Run from repository root: Rscript outputs/08_dementia_year_comparison.R
# Exploratory year comparison within dementia groups, requested after the dementia-adjusted stroke analysis.
# Source files are read only; only aggregate outputs are written.
.libPaths(c('work/Rlib', .libPaths()))
suppressPackageStartupMessages(library(survey))
options(survey.lonely.psu='fail')
out <- 'outputs/dementia_year_comparison'
dir.create(out, recursive=TRUE, showWarnings=FALSE)
stopifnot(file.exists(file.path(out,'Analysis_Plan.txt')))
put <- function(x,n) write.table(x,file.path(out,n),sep='\t',row.names=FALSE,na='NA')
vars <- c('SRVY_YR','HHX','AGEP_A','SEX_A','STREV_A','VSLSWYR_A','DEMENEV_A','WTFA_A','PSTRAT','PPSU')
sources <- list(); ds <- list()
for (yr in c(2022,2025)) {
  csv <- sprintf('work/raw/%s/adult%s.csv',yr,substr(yr,3,4))
  if(!file.exists(csv)) {
    archive <- sprintf('work/raw/adult%scsv.zip',substr(yr,3,4))
    dir.create(dirname(archive),recursive=TRUE,showWarnings=FALSE)
    if(!file.exists(archive)) download.file(sprintf('https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/%s/adult%scsv.zip',yr,substr(yr,3,4)),archive,mode='wb')
    unzip(archive,exdir=dirname(csv))
  }
  x <- read.csv(csv,check.names=FALSE,na.strings=c('','NA'))
  stopifnot(all(vars %in% names(x)), all(x$SRVY_YR==yr),!anyDuplicated(x$HHX),nrow(x)==if(yr==2022)27651 else 24215)
  sources[[as.character(yr)]] <- data.frame(year=yr,rows=nrow(x),columns=ncol(x),csv_md5=unname(tools::md5sum(csv)))
  ds[[as.character(yr)]] <- x[vars]
}
d <- do.call(rbind,ds);rownames(d)<-NULL
yesno <- function(x) ifelse(x %in% 1:2,as.integer(x==1),NA)
d$any<-yesno(d$VSLSWYR_A);d$dementia<-yesno(d$DEMENEV_A)
d$older<-d$AGEP_A %in% 65:85
d$agegroup<-factor(ifelse(d$older,ifelse(d$AGEP_A<75,'65-74',ifelse(d$AGEP_A<85,'75-84','85+')),NA),levels=c('65-74','75-84','85+'))
d$sex<-factor(ifelse(d$SEX_A %in% 1:2,d$SEX_A,NA),levels=1:2,labels=c('male','female'))
d$stroke_group<-factor(yesno(d$STREV_A),levels=0:1,labels=c('no_stroke','stroke'))
d$year<-factor(d$SRVY_YR,levels=c(2022,2025))
stopifnot(all(d$WTFA_A>0),!anyNA(d[c('PSTRAT','PPSU','WTFA_A')]))
d$stroke<-yesno(d$STREV_A)
d$dementia_group<-factor(d$dementia,levels=0:1,labels=c('no_dementia','dementia'))
des<-svydesign(ids=~PPSU,strata=~PSTRAT,weights=~WTFA_A,data=d,nest=TRUE)
base<-subset(des,older & !is.na(any) & !is.na(sex) & !is.na(dementia_group))
cc<-subset(base,!is.na(stroke))
std<-c('65-74'=18135514,'75-84'=12314793,'85+'=4259173);std<-std/sum(std)
ref<-expand.grid(agegroup=names(std),sex=c('male','female'),stroke=c(0,1),stringsAsFactors=FALSE)
ref$stroke_probability<-mapply(function(a,s) {
 z<-cc$variables;z<-z[z$agegroup==a & z$sex==s,];stopifnot(nrow(z)>0)
 weighted.mean(z$stroke,z$WTFA_A)
},ref$agegroup,ref$sex)
ref$weight<-as.numeric(std[ref$agegroup])*.5*ifelse(ref$stroke==1,ref$stroke_probability,1-ref$stroke_probability)
stopifnot(abs(sum(ref$weight)-1)<1e-12,all(ref$weight>0))
put(ref,'fixed_reference.tsv');put(do.call(rbind,sources),'source_audit.tsv')
cells<-list();flow<-list();k<-0;j<-0
for(yr in c(2022,2025)) for(gr in c('no_dementia','dementia')) {
 z<-base$variables;z<-z[z$SRVY_YR==yr & z$dementia_group==gr,]
 j<-j+1;flow[[j]]<-data.frame(year=yr,group=gr,baseline_n=nrow(z),baseline_events=sum(z$any),stroke_missing=sum(is.na(z$stroke)),complete_n=sum(!is.na(z$stroke)),complete_events=sum(z$any[!is.na(z$stroke)]))
 for(ag in names(std)) for(dm in 0:1) {
  a<-z[!is.na(z$stroke) & z$stroke==dm & z$agegroup==ag,]
  k<-k+1;cells[[k]]<-data.frame(year=yr,group=gr,agegroup=ag,stroke=dm,n=nrow(a),events=sum(a$any),nonevents=sum(a$any==0))
 }
}
put(do.call(rbind,flow),'sample_flow.tsv');put(do.call(rbind,cells),'cell_counts.tsv')
results<-list();audit<-list();checks<-character();nr<-0
fit_one<-function(domain,label,adjust) {
 form<-if(adjust) any~year*dementia_group+agegroup+sex+stroke else any~year*dementia_group+agegroup+sex
 fit<-svyglm(form,domain,family=quasibinomial())
 stopifnot(fit$converged,fit$rank==length(coef(fit)),all(is.finite(coef(fit))),all(is.finite(vcov(fit))),fit$df.residual>=8)
 b<-coef(fit);V<-vcov(fit);df<-fit$df.residual;crit<-qt(.975,df)
 capture.output(summary(fit),file=file.path(out,paste0(label,'_model.txt')))
 put(data.frame(term=names(b),estimate=b,SE=sqrt(diag(V))),paste0(label,'_coefficients.tsv'))
 put(data.frame(term=names(b),V,check.names=FALSE),paste0(label,'_coefficient_covariance.tsv'))
 margins<-expand.grid(year=c(2022,2025),group=c('no_dementia','dementia'),stringsAsFactors=FALSE)
 est<-numeric(4);G<-matrix(NA,4,length(b));maxerr<-0
 for(i in 1:4) {
  nd<-ref;nd$agegroup<-factor(nd$agegroup,levels=names(std));nd$sex<-factor(nd$sex,levels=c('male','female'))
  nd$year<-factor(margins$year[i],levels=c(2022,2025));nd$dementia_group<-factor(margins$group[i],levels=c('no_dementia','dementia'))
  X<-model.matrix(delete.response(terms(fit)),nd,contrasts.arg=fit$contrasts,xlev=fit$xlevels)[,names(b),drop=FALSE]
  p<-plogis(drop(X%*%b));est[i]<-sum(ref$weight*p);G[i,]<-colSums(X*as.numeric(ref$weight*p*(1-p)))
  ng<-numDeriv::grad(function(bb)sum(ref$weight*plogis(drop(X%*%bb))),b)
  maxerr<-max(maxerr,max(abs(ng-G[i,])))
  stopifnot(max(abs(ng-G[i,]))<1e-7,abs(sum(ref$weight*as.numeric(predict(fit,newdata=nd,type='response',se.fit=FALSE)))-est[i])<1e-10)
 }
 PV<-G%*%V%*%t(G)
 put(data.frame(margin=paste(margins$group,margins$year,sep='|'),PV),paste0(label,'margin_covariance.tsv'))
 add<-function(gr,type,e,se,prev=FALSE) {
  ci<-if(prev)plogis(qlogis(e)+c(-1,1)*crit*se/(e*(1-e))) else e+c(-1,1)*crit*se
  nr<<-nr+1;results[[nr]]<<-data.frame(analysis=label,group=gr,estimate_type=type,estimate=e,se=se,lcl=ci[1],ucl=ci[2],df=df,p=if(prev)NA else 2*pt(-abs(e/se),df))
 }
 for(i in 1:4)add(margins$group[i],paste0('standardized_',margins$year[i]),est[i],sqrt(PV[i,i]),TRUE)
 contrasts<-list(no_dementia=c(-1,1,0,0),dementia=c(0,0,-1,1),dementia_vs_no_dementia=c(1,-1,-1,1))
 for(gr in names(contrasts)) {v<-contrasts[[gr]];add(gr,if(gr=='dementia_vs_no_dementia')'difference_in_differences' else 'difference_2025_minus_2022',sum(v*est),sqrt(drop(t(v)%*%PV%*%v)))}
 audit[[label]]<<-data.frame(model=label,n=nrow(domain$variables),events=sum(domain$variables$any),design_df=degf(domain),residual_df=df,rank=fit$rank,converged=fit$converged,min_fitted=min(fitted(fit)),max_fitted=max(fitted(fit)),gradient_max_error=maxerr)
 checks<<-c(checks,paste(label,': convergence, rank, finite covariance, numerical gradients and predict() checks PASS'))
}
fit_one(base,'baseline_full',FALSE)
fit_one(cc,'baseline_complete',FALSE)
fit_one(cc,'stroke_adjusted',TRUE)
ans<-do.call(rbind,results)

put(ans,'results.tsv');put(do.call(rbind,audit),'model_audit.tsv')
pct<-ans;pct[c('estimate','se','lcl','ucl')]<-100*pct[c('estimate','se','lcl','ucl')];put(pct,'results_percent_units.tsv')
writeLines(checks,file.path(out,'validation.txt'));capture.output(sessionInfo(),file=file.path(out,'sessionInfo.txt'))
print(pct,row.names=FALSE)
raw<-subset(des,older & !is.na(any) & !is.na(dementia_group))
counts<-list();direct<-list();k<-0
for(yr in c(2022,2025)) for(gr in c('no_dementia','dementia')) {
 sub<-subset(raw,SRVY_YR==yr & dementia_group==gr)
 z<-sub$variables;k<-k+1
 counts[[k]]<-data.frame(year=yr,group=gr,n=nrow(z),events=sum(z$any),stroke_yes=sum(z$stroke==1,na.rm=TRUE))
 b<-svyby(~any,~agegroup,sub,svymean,covmat=TRUE)
 w<-std[as.character(b$agegroup)];e<-sum(w*coef(b));se<-sqrt(drop(t(w)%*%vcov(b)%*%w));df<-degf(sub)
 ci<-plogis(qlogis(e)+c(-1,1)*qt(.975,df)*se/(e*(1-e)))
 direct[[k]]<-data.frame(year=yr,group=gr,crude_percent=100*coef(svymean(~any,sub)),age_standardized_percent=100*e,lcl=100*ci[1],ucl=100*ci[2])
}
put(do.call(rbind,counts),'unweighted_counts.tsv');put(do.call(rbind,direct),'direct_prevalence_percent.tsv')
print(do.call(rbind,counts));print(do.call(rbind,direct))
