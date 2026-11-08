# Standalone preparation from the two unmodified CSV source tables.
# Run from the extracted project/package root before 01_analyse_all_adults.R.
# Uses base R only. Existing prepared data are retained and verified.
vars <- c('SRVY_YR','HHX','HHSTAT_A','AGEP_A','SEX_A','STREV_A','VSLSWYR_A',
          'VSLSWDIF_A','VSLSWDYS_A','WTFA_A','PSTRAT','PPSU')
dat <- list(); audit <- character()
for (yr in c(2022,2025)) {
  f <- sprintf('outputs/data_original/adult%s.csv',substr(yr,3,4))
  stopifnot(file.exists(f))
  header <- names(read.csv(f,nrows=0,check.names=FALSE))
  qname <- if(yr==2022)'INTV_QRT' else 'INTV_QRT2'
  keep <- c(vars,qname); stopifnot(all(keep %in% header))
  classes <- setNames(rep('NULL',length(header)),header); classes[keep] <- NA_character_
  classes['HHX'] <- 'character'
  x <- read.csv(f,colClasses=classes,na.strings=c('','NA'),check.names=FALSE)
  stopifnot(all(x$SRVY_YR==yr),!anyDuplicated(x$HHX),all(x$WTFA_A>0),
            !anyNA(x[c('PSTRAT','PPSU','WTFA_A')]),nrow(x)==if(yr==2022)27651 else 24215)
  x$quarter <- x[[qname]]; x <- x[c(vars,'quarter')]
  x$older <- !is.na(x$AGEP_A) & x$AGEP_A>=65 & x$AGEP_A<=85
  x$agegroup <- factor(ifelse(x$older,ifelse(x$AGEP_A<75,'65-74',ifelse(x$AGEP_A<85,'75-84','85+')),NA),
                       levels=c('65-74','75-84','85+'))
  x$stroke <- ifelse(x$STREV_A %in% 1:2,as.numeric(x$STREV_A==1),NA)
  x$any <- ifelse(x$VSLSWYR_A %in% 1:2,as.numeric(x$VSLSWYR_A==1),NA)
  x$severe <- ifelse(x$VSLSWYR_A==2,0,ifelse(x$VSLSWYR_A==1 & x$VSLSWDIF_A %in% 1:3,as.numeric(x$VSLSWDIF_A==2),NA))
  x$long <- ifelse(x$VSLSWYR_A==2,0,ifelse(x$VSLSWYR_A==1 & x$VSLSWDYS_A %in% 1:6,as.numeric(x$VSLSWDYS_A==6),NA))
  stopifnot(all(is.na(x$VSLSWDIF_A[x$VSLSWYR_A==2])),all(is.na(x$VSLSWDYS_A[x$VSLSWYR_A==2])))
  dat[[as.character(yr)]] <- x
  audit <- c(audit,paste(yr,'source CSV MD5',unname(tools::md5sum(f))))
}
d <- do.call(rbind,dat); rownames(d) <- NULL
dir.create('work',showWarnings=FALSE)
if(file.exists('work/prepared.rds')) {
  existing <- readRDS('work/prepared.rds')
  stopifnot(identical(existing,d))
  audit <- c(audit,'Fresh CSV parsing is identical to existing work/prepared.rds; existing file unchanged.')
} else {
  saveRDS(d,'work/prepared.rds')
  audit <- c(audit,'Created work/prepared.rds from unmodified CSV sources.')
}
dir.create('outputs/all_adults',recursive=TRUE,showWarnings=FALSE)
writeLines(c(audit,'The age>=65 preparation fields are retained for compatibility only.',
  'The adult analysis script replaces the agegroup field with the revised five adult age groups.'),
  'outputs/all_adults/Preparation_Validation.txt')
cat(paste(audit,collapse='\n'),'\n')
