# Run from repository root: Rscript outputs/09_four_group_comparison.R
# Exploratory year comparison across joint stroke/dementia groups.
# Source files are read only; only aggregate outputs are written.
.libPaths(c('work/Rlib', .libPaths()))
suppressPackageStartupMessages(library(survey))
options(survey.lonely.psu='fail')
out <- 'outputs/four_group_comparison'
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
groups<-c('neither','stroke_only','dementia_only','both')
d$group<-factor(ifelse(is.na(d$stroke)|is.na(d$dementia),NA,groups[1+d$stroke+2*d$dementia]),levels=groups)
des<-svydesign(ids=~PPSU,strata=~PSTRAT,weights=~WTFA_A,data=d,nest=TRUE)
dom<-subset(des,older & !is.na(any) & !is.na(group))
adj<-subset(dom,!is.na(sex))
grid<-expand.grid(year=c(2022,2025),group=groups,stringsAsFactors=FALSE)
labels<-with(grid,paste(year,group,sep='|'))
flow<-do.call(rbind,lapply(1:8,function(i){z<-dom$variables;z<-z[z$SRVY_YR==grid$year[i]&z$group==grid$group[i],];data.frame(grid[i,],n=nrow(z),events=sum(z$any),sex_missing=sum(is.na(z$sex)),adjusted_n=sum(!is.na(z$sex)),adjusted_events=sum(z$any[!is.na(z$sex)]))}))
put(flow,'sample_flow.tsv')
z<-adj$variables
cells<-aggregate(cbind(n=rep(1,nrow(z)),events=z$any),list(year=z$year,group=z$group,agegroup=z$agegroup,sex=z$sex),sum)
put(cells,'cell_counts.tsv');put(do.call(rbind,sources),'source_audit.tsv')
checks<-character();allres<-list();allpairs<-list();alltests<-list()
report<-function(est,V,df,method) {
 stopifnot(all(is.finite(est)),all(is.finite(V)),min(eigen(V,symmetric=TRUE)$values)>-1e-10,df>8)
 crit<-qt(.975,df);se<-sqrt(diag(V));lcl<-plogis(qlogis(est)-crit*se/(est*(1-est)));ucl<-plogis(qlogis(est)+crit*se/(est*(1-est)))
 put(data.frame(grid,estimate=est,se=se,lcl=lcl,ucl=ucl,df=df),paste0(method,'_prevalence.tsv'))
 put(data.frame(margin=labels,V,check.names=FALSE),paste0(method,'_covariance.tsv'))
 C<-matrix(0,4,8);for(i in 1:4)C[i,(2*i-1):(2*i)]<-c(-1,1)
 delta<-drop(C%*%est);DV<-C%*%V%*%t(C);ds<-sqrt(diag(DV))
 ans<-data.frame(method=method,group=groups,prevalence_2022=100*est[c(1,3,5,7)],prevalence_2025=100*est[c(2,4,6,8)],difference_pp=100*delta,lcl_pp=100*(delta-crit*ds),ucl_pp=100*(delta+crit*ds),p=2*pt(-abs(delta/ds),df),df=df)
 allres[[method]]<<-ans
 pair<-list();k<-0
 for(i in 1:3)for(j in (i+1):4){v<-rep(0,4);v[j]<-1;v[i]<- -1;e<-sum(v*delta);s<-sqrt(drop(t(v)%*%DV%*%v));k<-k+1;pair[[k]]<-data.frame(method=method,contrast=paste(groups[j],'-',groups[i]),difference_in_change_pp=100*e,lcl_pp=100*(e-crit*s),ucl_pp=100*(e+crit*s),p=2*pt(-abs(e/s),df))}
 allpairs[[method]]<<-do.call(rbind,pair)
 H<-cbind(-1,diag(3));h<-drop(H%*%delta);HV<-H%*%DV%*%t(H);Fstat<-drop(t(h)%*%solve(HV,h))/3
 alltests[[method]]<<-data.frame(method=method,F=Fstat,df1=3,df2=df,p=pf(Fstat,3,df,lower.tail=FALSE))
}
dom$variables$cell<-factor(paste(dom$variables$SRVY_YR,dom$variables$group,sep='|'),levels=labels)
b<-svyby(~any,~cell,dom,svymean,covmat=TRUE)
stopifnot(identical(as.character(b$cell),labels))
sat<-svyglm(any~0+cell,dom,family=gaussian())
stopifnot(max(abs(coef(sat)-coef(b)))<1e-8,max(abs(vcov(sat)-vcov(b)))<1e-8)
manual<-sapply(labels,function(l){z<-dom$variables;z<-z[z$cell==l,];weighted.mean(z$any,z$WTFA_A)})
stopifnot(max(abs(manual-coef(b)))<1e-12)
checks<-c(checks,'Crude estimates: manual weighted means and saturated Gaussian survey covariance agree: PASS')
report(coef(b),vcov(b),degf(dom),'crude_weighted')
fit<-svyglm(any~year*group+agegroup+sex,adj,family=quasibinomial())
stopifnot(fit$converged,fit$rank==length(coef(fit)),all(is.finite(vcov(fit))))
std<-c('65-74'=18135514,'75-84'=12314793,'85+'=4259173);std<-std/sum(std)
ref<-expand.grid(agegroup=names(std),sex=c('male','female'),stringsAsFactors=FALSE);ref$weight<-as.numeric(std[ref$agegroup])*.5
put(ref,'fixed_reference.tsv');beta<-coef(fit);V<-vcov(fit);est<-numeric(8);G<-matrix(NA,8,length(beta));err<-0
for(i in 1:8){
 nd<-ref;nd$agegroup<-factor(nd$agegroup,levels=names(std));nd$sex<-factor(nd$sex,levels=c('male','female'));nd$year<-factor(grid$year[i],levels=c(2022,2025));nd$group<-factor(grid$group[i],levels=groups)
 X<-model.matrix(delete.response(terms(fit)),nd,contrasts.arg=fit$contrasts,xlev=fit$xlevels)[,names(beta),drop=FALSE]
 p<-plogis(drop(X%*%beta));est[i]<-sum(ref$weight*p);G[i,]<-colSums(X*as.numeric(ref$weight*p*(1-p)))
 ng<-numDeriv::grad(function(bb)sum(ref$weight*plogis(drop(X%*%bb))),beta);err<-max(err,max(abs(ng-G[i,])))
 stopifnot(max(abs(ng-G[i,]))<1e-7,abs(sum(ref$weight*as.numeric(predict(fit,newdata=nd,type='response',se.fit=FALSE)))-est[i])<1e-10)
}
checks<-c(checks,'Adjusted model: convergence/full rank/finite covariance, predict() and numerical gradients PASS',paste('Maximum gradient error',err),'Exploratory contrasts without multiplicity adjustment; sparse cells limit precision.')
report(est,G%*%V%*%t(G),fit$df.residual,'age_sex_adjusted')
put(do.call(rbind,allres),'comparison_percent_units.tsv');put(do.call(rbind,allpairs),'pairwise_change_contrasts.tsv');put(do.call(rbind,alltests),'heterogeneity_tests.tsv')
put(data.frame(term=names(beta),estimate=beta,SE=sqrt(diag(V))),'model_coefficients.tsv');put(data.frame(term=names(beta),V,check.names=FALSE),'model_coefficient_covariance.tsv')
put(data.frame(n=nrow(adj$variables),events=sum(adj$variables$any),rank=fit$rank,design_df=degf(adj),residual_df=fit$df.residual,converged=fit$converged,min_fitted=min(fitted(fit)),max_fitted=max(fitted(fit))),'model_audit.tsv')
capture.output(summary(fit),file=file.path(out,'model_summary.txt'));capture.output(sessionInfo(),file=file.path(out,'sessionInfo.txt'));writeLines(checks,file.path(out,'validation.txt'))
print(flow,row.names=FALSE);print(do.call(rbind,allres),row.names=FALSE);print(do.call(rbind,alltests),row.names=FALSE);print(do.call(rbind,allpairs),row.names=FALSE)
