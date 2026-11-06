# Run after 01_prepare.R, from project root. Requires survey >=4.5.
.libPaths(c('work/Rlib',.libPaths()))
library(survey)
options(survey.lonely.psu='fail')
d<-readRDS('work/prepared.rds')
d$year<-factor(d$SRVY_YR)
d$sex<-factor(ifelse(d$SEX_A %in% 1:2,d$SEX_A,NA),levels=1:2,labels=c('male','female'))
d$missing_primary<-as.numeric(is.na(d$any))
d$low<-ifelse(is.na(d$any),0,d$any)
d$high<-ifelse(is.na(d$any),1,d$any)
d$opposite_low<-ifelse(is.na(d$any),as.numeric(d$SRVY_YR==2022),d$any)
d$opposite_high<-ifelse(is.na(d$any),as.numeric(d$SRVY_YR==2025),d$any)
d$stroke_group<-factor(ifelse(is.na(d$stroke),NA,ifelse(d$stroke==1,'stroke','no_stroke')))
des<-svydesign(ids=~PPSU,strata=~PSTRAT,weights=~WTFA_A,data=d,nest=TRUE)
std<-c('65-74'=18135514,'75-84'=12314793,'85+'=4259173);std<-std/sum(std)
write.table(data.frame(agegroup=names(std),weight=std),'outputs/age_standard.tsv',sep='\t',row.names=FALSE)
rows<-list(); k<-0
calc<-function(obj,variable,group='all',analysis='main',interaction=FALSE) {
  obj<-obj[!is.na(obj$variables[[variable]]),]
  obj$variables$y<-obj$variables[[variable]]
  obj$variables$cell<-with(obj$variables,paste(year,agegroup,if(interaction) stroke_group else group,sep='|'))
  b<-svyby(~y,~cell,obj,svymean,covmat=TRUE,keep.var=TRUE)
  labs<-as.character(b$cell); beta<-coef(b);V<-vcov(b);df<-degf(obj)
  stopifnot(df>=8,all(is.finite(V)))
  cc<-function(yr,gr) {
    z<-numeric(length(beta)); ix<-match(paste(yr,names(std),gr,sep='|'),labs)
    stopifnot(!anyNA(ix));z[ix]<-std;z
  }
  append_result<-function(cvec,label,isprevalence=FALSE,n=NA,events=NA,fragile=FALSE) {
    est<-sum(cvec*beta);se<-sqrt(drop(t(cvec)%*%V%*%cvec));crit<-qt(.975,df)
    ci<-if(isprevalence) plogis(qlogis(est)+c(-1,1)*crit*se/(est*(1-est))) else est+c(-1,1)*crit*se
    k<<-k+1; rows[[k]]<<-data.frame(analysis=analysis,group=group,outcome=variable,estimate_type=label,
      estimate=est,se=se,lcl=ci[1],ucl=ci[2],df=df,n=n,events=events,rse=if(isprevalence) se/est else NA,
      fragile=fragile || (isprevalence && se/est>.30),p=if(isprevalence) NA else 2*pt(-abs(est/se),df))
  }
  if(interaction) {
    cv<-(cc(2025,'stroke')-cc(2022,'stroke'))-(cc(2025,'no_stroke')-cc(2022,'no_stroke'))
    append_result(cv,'difference_in_differences')
  } else {
    fragile<-FALSE
    for(yr in c(2022,2025)) {
      x<-obj$variables[obj$variables$SRVY_YR==yr,]
      cells<-split(x,x$agegroup)
      fr<-any(sapply(cells,function(z) nrow(z)<30 || sum(z$y==1)<10 || sum(z$y==0)<10))
      fragile<-fragile||fr
      append_result(cc(yr,group),paste0('standardized_',yr),TRUE,nrow(x),sum(x$y),fr)
      # Independent arithmetic check of each point estimate against manual weighted age means.
      manual<-sum(std*sapply(names(std),function(ag) {z<-x[x$agegroup==ag,];weighted.mean(z$y,z$WTFA_A)}))
      stopifnot(abs(manual-sum(cc(yr,group)*beta))<1e-10)
    }
    append_result(cc(2025,group)-cc(2022,group),'difference_2025_minus_2022',fragile=fragile)
  }
}
older<-subset(des,older)
for(gr in c('all','stroke','no_stroke')) {
  sub<-if(gr=='all') older else older[!is.na(older$variables$stroke) & older$variables$stroke==as.integer(gr=='stroke'),]
  for(v in c('any','severe','long')) calc(sub,v,gr)
  calc(subset(sub,quarter %in% 1:3),'any',gr,'Q1_Q3')
  for(v in c('low','high','opposite_low','opposite_high')) calc(sub,v,gr,'missing_bounds')
}
cells<-read.delim('outputs/cell_counts.tsv')
gate<-subset(cells,group!='all' & agegroup!='all' & outcome=='any')
stopifnot(all(gate$valid>=30 & gate$yes>=10 & gate$no>=10))
calc(subset(older,!is.na(stroke)),'any','stroke_vs_no_stroke','main',TRUE)
results<-do.call(rbind,rows)
write.table(results,'outputs/standardized_results.tsv',sep='\t',row.names=FALSE)

# Crude proportions and design-based CIs, including conditional severity/duration.
raw<-list();j<-0
for(gr in c('all','stroke','no_stroke')) for(yr in c(2022,2025)) {
 sub<-subset(older,SRVY_YR==yr)
 if(gr!='all') sub<-sub[!is.na(sub$variables$stroke) & sub$variables$stroke==as.integer(gr=='stroke'),]
 for(v in c('any','severe','long','missing_primary')) {
   s<-sub[!is.na(sub$variables[[v]]),];s$variables$y<-s$variables[[v]]
   b<-svyciprop(~y,s,method='logit',df=degf(s));ci<-confint(b)
   j<-j+1;raw[[j]]<-data.frame(group=gr,year=yr,outcome=v,estimate=as.numeric(b),se=as.numeric(SE(b)),lcl=ci[1],ucl=ci[2],n=nrow(s$variables))
 }
 for(v in c('VSLSWDIF_A','VSLSWDYS_A')) for(code in seq_len(if(v=='VSLSWDIF_A')3 else 6)) {
   s<-subset(sub,any==1);valid<-if(v=='VSLSWDIF_A')1:3 else 1:6
   s<-s[s$variables[[v]] %in% valid,];s$variables$y<-as.numeric(s$variables[[v]]==code)
   b<-svyciprop(~y,s,method='logit',df=degf(s));ci<-confint(b)
   j<-j+1;raw[[j]]<-data.frame(group=gr,year=yr,outcome=paste(v,code,'among_affected',sep='_'),estimate=as.numeric(b),se=as.numeric(SE(b)),lcl=ci[1],ucl=ci[2],n=nrow(s$variables))
 }
}
write.table(do.call(rbind,raw),'outputs/crude_and_conditional_results.tsv',sep='\t',row.names=FALSE)
desc<-svyby(~agegroup+sex,~year,older,svymean,na.rm=TRUE)
write.table(as.data.frame(desc),'outputs/weighted_demographics.tsv',sep='\t',row.names=FALSE)
audit<-data.frame(year=c(2022,2025),strata=sapply(c(2022,2025),function(y)length(unique(d$PSTRAT[d$SRVY_YR==y]))),psus=sapply(c(2022,2025),function(y)nrow(unique(d[d$SRVY_YR==y,c('PSTRAT','PPSU')]))))
write.table(audit,'outputs/design_audit.tsv',sep='\t',row.names=FALSE)
saveRDS(list(results=results,design_audit=audit,standard=std),'work/analysis_results.rds')
capture.output(sessionInfo(),file='outputs/session_analysis.txt')
print(subset(results,analysis=='main' & (outcome=='any'|group=='all')),digits=5,row.names=FALSE)
