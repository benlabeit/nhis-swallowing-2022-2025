# Run from project root: Rscript outputs/01_prepare.R
options(encoding='UTF-8')
.libPaths(c('work/Rlib', .libPaths()))
dir.create('work/raw', recursive=TRUE, showWarnings=FALSE)
dir.create('work/docs', recursive=TRUE, showWarnings=FALSE)
dir.create('outputs', showWarnings=FALSE)
vars <- c('SRVY_YR','HHX','HHSTAT_A','AGEP_A','SEX_A','STREV_A','VSLSWYR_A',
          'VSLSWDIF_A','VSLSWDYS_A','WTFA_A','PSTRAT','PPSU')
dat <- list(); manifest <- list(); mapping <- list()
for (yr in c(2022,2025)) {
  zip <- sprintf('work/raw/adult%scsv.zip',substr(yr,3,4))
  url <- sprintf('https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/%s/adult%scsv.zip',yr,substr(yr,3,4))
  if (!file.exists(zip)) download.file(url,zip,mode='wb')
  unzip(zip,exdir=sprintf('work/raw/%s',yr))
  f <- list.files(sprintf('work/raw/%s',yr),pattern='csv$',full.names=TRUE)
  d <- read.csv(f,na.strings=c('','NA'),check.names=FALSE)
  stopifnot(all(vars %in% names(d)),all(d$SRVY_YR==yr),!anyDuplicated(d$HHX),
            all(d$WTFA_A>0),!anyNA(d[c('PSTRAT','PPSU','WTFA_A')]))
  qname <- if(yr==2022) 'INTV_QRT' else 'INTV_QRT2'
  d$quarter <- d[[qname]]
  d <- d[c(vars,'quarter')]
  d$older <- !is.na(d$AGEP_A) & d$AGEP_A>=65 & d$AGEP_A<=85
  d$agegroup <- factor(ifelse(d$older,ifelse(d$AGEP_A<75,'65-74',ifelse(d$AGEP_A<85,'75-84','85+')),NA),levels=c('65-74','75-84','85+'))
  d$stroke <- ifelse(d$STREV_A %in% 1:2,as.numeric(d$STREV_A==1),NA)
  d$any <- ifelse(d$VSLSWYR_A %in% 1:2,as.numeric(d$VSLSWYR_A==1),NA)
  d$severe <- ifelse(d$VSLSWYR_A==2,0,ifelse(d$VSLSWYR_A==1 & d$VSLSWDIF_A %in% 1:3,as.numeric(d$VSLSWDIF_A==2),NA))
  d$long <- ifelse(d$VSLSWYR_A==2,0,ifelse(d$VSLSWYR_A==1 & d$VSLSWDYS_A %in% 1:6,as.numeric(d$VSLSWDYS_A==6),NA))
  stopifnot(all(is.na(d$VSLSWDIF_A[d$VSLSWYR_A==2])),all(is.na(d$VSLSWDYS_A[d$VSLSWYR_A==2])))
  dat[[as.character(yr)]] <- d
  manifest[[as.character(yr)]] <- data.frame(year=yr,url=url,file=zip,md5=unname(tools::md5sum(zip)),n=nrow(d))
  for(v in vars) mapping[[paste(yr,v)]] <- data.frame(year=yr,variable=v,present=TRUE)
}
d <- do.call(rbind,dat); rownames(d)<-NULL
saveRDS(d,'work/prepared.rds')
write.table(do.call(rbind,manifest),'outputs/download_manifest.tsv',sep='\t',row.names=FALSE)
flow <- do.call(rbind,lapply(dat,function(x) data.frame(year=unique(x$SRVY_YR),total=nrow(x),age_unknown=sum(!x$AGEP_A %in% 18:85),age65plus=sum(x$older),primary_valid=sum(x$older & !is.na(x$any)),primary_yes=sum(x$older & x$any==1,na.rm=TRUE),primary_missing=sum(x$older & is.na(x$any)),stroke_yes=sum(x$older & x$stroke==1,na.rm=TRUE),stroke_unknown=sum(x$older & is.na(x$stroke)))))
write.table(flow,'outputs/sample_flow.tsv',sep='\t',row.names=FALSE)
counts<-list(); j<-0
for(yr in c(2022,2025)) for(gr in c('all','stroke','no_stroke')) for(ag in c('all','65-74','75-84','85+')) {
  x<-d[d$SRVY_YR==yr & d$older,]
  if(gr!='all') x<-x[!is.na(x$stroke) & x$stroke==as.integer(gr=='stroke'),]
  if(ag!='all') x<-x[!is.na(x$agegroup) & x$agegroup==ag,]
  for(v in c('any','severe','long')) {
    j<-j+1; counts[[j]]<-data.frame(year=yr,group=gr,agegroup=ag,outcome=v,n=nrow(x),valid=sum(!is.na(x[[v]])),yes=sum(x[[v]]==1,na.rm=TRUE),no=sum(x[[v]]==0,na.rm=TRUE),missing=sum(is.na(x[[v]])))
  }
}
write.table(do.call(rbind,counts),'outputs/cell_counts.tsv',sep='\t',row.names=FALSE)
rawcounts<-list();j<-0
for(yr in c(2022,2025)) for(v in c('SEX_A','STREV_A','VSLSWYR_A','VSLSWDIF_A','VSLSWDYS_A','quarter')) {
 x<-d[d$SRVY_YR==yr & d$older,];tb<-table(x[[v]],useNA='always');j<-j+1
 rawcounts[[j]]<-data.frame(year=yr,variable=v,code=names(tb),n=as.numeric(tb))
}
write.table(do.call(rbind,rawcounts),'outputs/raw_codes_65plus.tsv',sep='\t',row.names=FALSE)
capture.output(sessionInfo(),file='outputs/session_prepare.txt')
print(flow)
print(subset(do.call(rbind,counts),group=='stroke' & outcome=='any'))
