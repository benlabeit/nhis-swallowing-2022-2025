# Run from project root AFTER 01_prepare.R. No input data are changed.
# Post-hoc analyses 1 and 2 defined in Analyseplan_Addendum.txt.
if(.Platform$OS.type=='windows') Sys.setlocale('LC_CTYPE','English_United States.utf8')
.libPaths(c('work/Rlib',.libPaths()))
suppressPackageStartupMessages(library(survey))
options(survey.lonely.psu='fail')
outdir<-'outputs/extensions'
dir.create(outdir,recursive=TRUE,showWarnings=FALSE)
stopifnot(file.exists('outputs/Analyseplan_Addendum.txt'),file.exists(file.path(outdir,'addendum_frozen.txt')))
write_tsv<-function(x,name) write.table(x,file.path(outdir,name),sep='\t',row.names=FALSE,na='NA')
d<-readRDS('work/prepared.rds')
d$AVAIL_A<-d$PROXY_A<-d$PROXYFLAG_A<-NA_integer_
for(yr in c(2022,2025)) {
 csv<-sprintf('work/raw/%s/adult%s.csv',yr,substr(yr,3,4))
 if(!file.exists(csv)) csv<-sprintf('work/raw/adult%s.csv',substr(yr,3,4))
 header<-names(read.csv(csv,nrows=0,check.names=FALSE))
 keep<-c('HHX','SRVY_YR',if(yr==2022)c('AVAIL_A','PROXY_A') else 'PROXYFLAG_A')
 stopifnot(all(keep %in% header))
 classes<-setNames(rep('NULL',length(header)),header);classes[keep]<-'numeric';classes['HHX']<-'character'
 x<-read.csv(csv,colClasses=classes,na.strings=c('','NA'),check.names=FALSE)
 ix<-which(d$SRVY_YR==yr);m<-match(d$HHX[ix],x$HHX)
 stopifnot(nrow(x)==length(ix),!anyNA(m),!anyDuplicated(x$HHX),all(x$SRVY_YR==yr))
 for(v in setdiff(keep,c('HHX','SRVY_YR'))) d[ix,v]<-x[m,v]
}
d$proxy_status<-'unknown'
ix22<-d$SRVY_YR==2022; ix25<-d$SRVY_YR==2025
contradictory<-ix22 & d$AVAIL_A %in% c(1,2) & !is.na(d$PROXY_A)
stopifnot(!any(contradictory))
d$proxy_status[ix22 & d$AVAIL_A %in% 1 & is.na(d$PROXY_A)]<-'self'
d$proxy_status[ix22 & d$AVAIL_A %in% 3 & d$PROXY_A %in% 1]<-'proxy'
d$proxy_status[ix25 & d$PROXYFLAG_A %in% 2]<-'self'
d$proxy_status[ix25 & d$PROXYFLAG_A %in% 1]<-'proxy'
d$year<-factor(d$SRVY_YR,levels=c(2022,2025))
d$sex<-factor(ifelse(d$SEX_A %in% 1:2,d$SEX_A,NA),levels=c(1,2),labels=c('male','female'))
d$stroke_group<-factor(ifelse(is.na(d$stroke),NA,ifelse(d$stroke==1,'stroke','no_stroke')),levels=c('no_stroke','stroke'))
std<-c('65-74'=18135514,'75-84'=12314793,'85+'=4259173);std<-std/sum(std)
ref<-expand.grid(agegroup=names(std),sex=c('male','female'),stringsAsFactors=FALSE)
ref$weight<-std[ref$agegroup]*.5
write_tsv(ref,'fixed_reference_distribution.tsv')
stopifnot(abs(sum(ref$weight)-1)<1e-12)

# Raw-code audit, plus all relevant unweighted cells. No individual records exported.
aud<-list();k<-0
for(yr in c(2022,2025)) {
 z<-d[d$SRVY_YR==yr,]
 key<-paste(ifelse(is.na(z$AVAIL_A),'NA',z$AVAIL_A),ifelse(is.na(z$PROXY_A),'NA',z$PROXY_A),ifelse(is.na(z$PROXYFLAG_A),'NA',z$PROXYFLAG_A),z$proxy_status,sep='|')
 for(ki in unique(key)) {
  v<-z[key==ki,];parts<-strsplit(ki,'|',fixed=TRUE)[[1]];k<-k+1
  aud[[k]]<-data.frame(year=yr,AVAIL_A=parts[1],PROXY_A=parts[2],PROXYFLAG_A=parts[3],proxy_status=parts[4],n_all=nrow(v),n_65plus=sum(v$older),n_valid_primary_65plus=sum(v$older & !is.na(v$any)),events_65plus=sum(v$older & v$any==1,na.rm=TRUE))
 }
}
write_tsv(do.call(rbind,aud),'proxy_raw_code_audit.tsv')
cells<-list();k<-0
for(yr in c(2022,2025)) for(gr in c('all','stroke','no_stroke')) for(ps in c('all','self','proxy','unknown')) for(ag in c('all',names(std))) {
 z<-d[d$older & d$SRVY_YR==yr,]
 if(gr!='all') z<-z[!is.na(z$stroke_group)&z$stroke_group==gr,]
 if(ps!='all') z<-z[z$proxy_status==ps,]
 if(ag!='all') z<-z[!is.na(z$agegroup)&z$agegroup==ag,]
 k<-k+1;cells[[k]]<-data.frame(year=yr,group=gr,proxy_status=ps,agegroup=ag,n=nrow(z),valid_primary=sum(!is.na(z$any)),events=sum(z$any==1,na.rm=TRUE),nonevents=sum(z$any==0,na.rm=TRUE),primary_missing=sum(is.na(z$any)),sex_missing=sum(is.na(z$sex)),model_n=sum(!is.na(z$any)&!is.na(z$sex)))
}
celltab<-do.call(rbind,cells);write_tsv(celltab,'proxy_cell_counts.tsv')
des<-svydesign(ids=~PPSU,strata=~PSTRAT,weights=~WTFA_A,data=d,nest=TRUE)
older<-subset(des,older)
results<-list();kr<-0;validation<-character();modelaudit<-list();ka<-0
add_result<-function(method,group,label,est,se,df,n=NA,events=NA,fragile=FALSE,isprev=FALSE,model_id='') {
 stopifnot(all(is.finite(c(est,se,df))),se>0,df>=8)
 crit<-qt(.975,df)
 ci<-if(isprev)plogis(qlogis(est)+c(-1,1)*crit*se/(est*(1-est))) else est+c(-1,1)*crit*se
 kr<<-kr+1;results[[kr]]<<-data.frame(analysis=method,group=group,outcome='any',estimate_type=label,estimate=est,se=se,lcl=ci[1],ucl=ci[2],df=df,n=n,events=events,fragile=fragile,p=if(isprev)NA else 2*pt(-abs(est/se),df),model_id=model_id)
}

run_models<-function(domain,method) {
 for(which_model in c('overall','stroke_groups')) {
   sub<-subset(domain,!is.na(any)&!is.na(sex))
   if(which_model=='stroke_groups') sub<-subset(sub,!is.na(stroke_group))
   form<-if(which_model=='overall') any~year+agegroup+sex else any~year*stroke_group+agegroup+sex
   fit<-svyglm(form,design=sub,family=quasibinomial())
   stopifnot(fit$converged,all(is.finite(coef(fit))),all(is.finite(vcov(fit))),fit$df.residual>=8)
   model_id<-paste(method,which_model,sep='_')
   capture.output(summary(fit),file=file.path(outdir,paste0(model_id,'_model.txt')))
   cm<-summary(fit)$coefficients
   write_tsv(data.frame(term=rownames(cm),cm,check.names=FALSE),paste0(model_id,'_coefficients.tsv'))
   write_tsv(data.frame(term=rownames(vcov(fit)),vcov(fit),check.names=FALSE),paste0(model_id,'_coefficient_covariance.tsv'))
   b<-coef(fit);V<-vcov(fit);df<-fit$df.residual
   groups<-if(which_model=='overall')'all' else c('no_stroke','stroke')
   estimates<-list();gradients<-list();meta<-list();m<-0
   for(gr in groups) for(yr in c(2022,2025)) {
     nd<-ref;nd$year<-factor(yr,levels=c(2022,2025));nd$agegroup<-factor(nd$agegroup,levels=names(std));nd$sex<-factor(nd$sex,levels=c('male','female'))
     nd$stroke_group<-factor(if(gr=='all')'no_stroke' else gr,levels=c('no_stroke','stroke'))
     X<-model.matrix(delete.response(terms(fit)),nd,contrasts.arg=fit$contrasts,xlev=fit$xlevels)
     X<-X[,names(b),drop=FALSE]
     p<-plogis(drop(X%*%b));est<-sum(ref$weight*p)
     g<-colSums(X*as.numeric(ref$weight*p*(1-p)))
     f<-function(bb)sum(ref$weight*plogis(drop(X%*%bb)))
     ng<-numDeriv::grad(f,b)
     stopifnot(max(abs(ng-g))<1e-7)
     pred<-as.numeric(predict(fit,newdata=nd,type='response',se.fit=FALSE))
     stopifnot(abs(sum(ref$weight*pred)-est)<1e-10)
     m<-m+1;estimates[[m]]<-est;gradients[[m]]<-g;meta[[m]]<-data.frame(group=gr,year=yr)
     z<-sub$variables[sub$variables$SRVY_YR==yr,]
     if(gr!='all') z<-z[z$stroke_group==gr,]
     add_result(method,gr,paste0('standardized_',yr),est,sqrt(drop(t(g)%*%V%*%g)),df,nrow(z),sum(z$any),isprev=TRUE,model_id=model_id)
     validation<-c(validation,sprintf('%s %s %s: analytic/numerical marginal gradient max error %.3g; predict() agreement PASS',model_id,gr,yr,max(abs(ng-g))))
   }
   beta<-unlist(estimates);G<-do.call(rbind,gradients);PV<-G%*%V%*%t(G);mt<-do.call(rbind,meta)
   labs<-paste(mt$group,mt$year,sep='|');rownames(PV)<-colnames(PV)<-labs
   write_tsv(data.frame(margin=labs,PV,check.names=FALSE),paste0(model_id,'_margin_covariance.tsv'))
   makec<-function(gr) {v<-numeric(length(beta));v[mt$group==gr & mt$year==2025]<-1;v[mt$group==gr & mt$year==2022]<- -1;v}
   contrast<-function(v,gr,label) add_result(method,gr,label,sum(v*beta),sqrt(drop(t(v)%*%PV%*%v)),df,model_id=model_id)
   for(gr in groups) contrast(makec(gr),gr,'difference_2025_minus_2022')
   if(which_model=='stroke_groups') contrast(makec('stroke')-makec('no_stroke'),'stroke_vs_no_stroke','difference_in_differences')
   ka<<-ka+1;modelaudit[[ka]]<<-data.frame(model_id=model_id,formula=paste(deparse(form),collapse=''),n=nrow(sub$variables),events=sum(sub$variables$any),design_df=degf(sub),model_df=df,rank=fit$rank,converged=fit$converged,min_fitted=min(fitted(fit)),max_fitted=max(fitted(fit)))
 }
 validation
}
validation<-c(validation,run_models(older,'age_sex_adjusted'))

self<-subset(older,proxy_status=='self')
direct<-function(domain,gr,interaction=FALSE) {
 s<-subset(domain,!is.na(any))
 if(interaction)s<-subset(s,!is.na(stroke_group)) else if(gr!='all')s<-subset(s,stroke_group==gr)
 s$variables$cell<-with(s$variables,factor(paste(year,agegroup,if(interaction)stroke_group else gr,sep='|')))
 b<-svyby(~any,~cell,s,svymean,covmat=TRUE)
 labs<-as.character(b$cell);beta<-coef(b);V<-vcov(b);df<-degf(s)
 sat<-svyglm(any~0+cell,s,family=gaussian())
 stopifnot(max(abs(coef(sat)-beta))<1e-8,max(abs(vcov(sat)-V))<1e-8)
 validation<<-c(validation,paste('self_direct',gr,'saturated Gaussian survey covariance check PASS'))
 cv<-function(yr,g) {v<-numeric(length(beta));ix<-match(paste(yr,names(std),g,sep='|'),labs);stopifnot(!anyNA(ix));v[ix]<-std;v}
 contrast<-function(v,label,group,isprev=FALSE,n=NA,events=NA,fragile=FALSE) add_result('self_direct_age_standardized',group,label,sum(v*beta),sqrt(drop(t(v)%*%V%*%v)),df,n,events,fragile,isprev)
 if(interaction) {
  gate<-subset(celltab,proxy_status=='self' & group!='all' & agegroup!='all')
  if(all(gate$valid_primary>=30 & gate$events>=10 & gate$nonevents>=10)) contrast(cv(2025,'stroke')-cv(2022,'stroke')-cv(2025,'no_stroke')+cv(2022,'no_stroke'),'difference_in_differences','stroke_vs_no_stroke')
  else validation<<-c(validation,'Self-only additive interaction NOT reported: prespecified event-count gate fails.')
 }else {
  anyfrag<-FALSE
  for(yr in c(2022,2025)) {
   z<-s$variables[s$variables$SRVY_YR==yr,];cs<-split(z,z$agegroup)
   frag<-any(sapply(cs,function(a)nrow(a)<30 || sum(a$any)<10 || sum(a$any==0)<10));anyfrag<-anyfrag||frag
   manual<-sum(std*sapply(names(std),function(ag){a<-z[z$agegroup==ag,];weighted.mean(a$any,a$WTFA_A)}))
   stopifnot(abs(manual-sum(cv(yr,gr)*beta))<1e-10)
   contrast(cv(yr,gr),paste0('standardized_',yr),gr,TRUE,nrow(z),sum(z$any),frag)
  }
  contrast(cv(2025,gr)-cv(2022,gr),'difference_2025_minus_2022',gr,fragile=anyfrag)
 }
}
for(gr in c('all','stroke','no_stroke'))direct(self,gr)
direct(self,'stroke_vs_no_stroke',TRUE)
validation<-c(validation,run_models(self,'self_age_sex_adjusted'))
ans<-do.call(rbind,results);write_tsv(ans,'additional_results.tsv')
write_tsv(do.call(rbind,modelaudit),'model_audit.tsv')
source_main<-read.delim('outputs/standardized_results.tsv')
main<-subset(source_main,analysis=='main' & outcome=='any')
main<-main[c('analysis','group','outcome','estimate_type','estimate','se','lcl','ucl','df','n','events','fragile','p')];main$model_id<-''
write_tsv(rbind(main,ans),'primary_comparison_all_methods.tsv')
writeLines(c('All additional results are post-hoc exploratory analyses.',
             'Fixed marginal reference: US 2000 age standard within 65+ crossed with 50% male / 50% female.',
             'The reference is a hypothetical balanced population; adjusted levels are not actual population prevalence.',
             'Self-only 2022 requires AVAIL_A=1 and missing PROXY_A; all other nonproxy combinations are ambiguous/excluded.',
             'Self-only 2025 requires PROXYFLAG_A=2.',
             unique(validation),
             'No singleton-PSU adjustment applied. Original full adult design retained before domain restriction.',
             paste('Prepared data MD5:',unname(tools::md5sum('work/prepared.rds'))),
             paste('Addendum MD5:',unname(tools::md5sum('outputs/Analyseplan_Addendum.txt')))),file.path(outdir,'validation_and_methods.txt'))
capture.output(sessionInfo(),file=file.path(outdir,'session_extensions.txt'))
summaryrows<-list();ks<-0
for(method in unique(ans$analysis)) for(gr in c('all','stroke','no_stroke')) {
 a<-subset(ans,analysis==method & group==gr & estimate_type=='standardized_2022')
 b<-subset(ans,analysis==method & group==gr & estimate_type=='standardized_2025')
 dif<-subset(ans,analysis==method & group==gr & estimate_type=='difference_2025_minus_2022')
 ks<-ks+1;summaryrows[[ks]]<-data.frame(analysis=method,group=gr,
  prevalence_2022_pct=100*a$estimate,prevalence_2022_lcl_pct=100*a$lcl,prevalence_2022_ucl_pct=100*a$ucl,
  prevalence_2025_pct=100*b$estimate,prevalence_2025_lcl_pct=100*b$lcl,prevalence_2025_ucl_pct=100*b$ucl,
  difference_pp=100*dif$estimate,difference_lcl_pp=100*dif$lcl,difference_ucl_pp=100*dif$ucl,
  n_2022=a$n,events_2022=a$events,n_2025=b$n,events_2025=b$events)
}
write_tsv(do.call(rbind,summaryrows),'manuscript_summary_percent_units.tsv')
print(ans[ans$estimate_type %in% c('difference_2025_minus_2022','difference_in_differences'),],digits=5,row.names=FALSE)
print(subset(celltab,proxy_status!='all' & agegroup=='all' & group %in% c('all','stroke')),row.names=FALSE)
