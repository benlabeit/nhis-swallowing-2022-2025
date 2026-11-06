# Run from project root. All dependencies remain inside work/.
dir.create('work/Rlib',recursive=TRUE,showWarnings=FALSE)
dir.create('work/docs',recursive=TRUE,showWarnings=FALSE)
.libPaths(c('work/Rlib',.libPaths()))
for(pkg in c('survey','pdftools')) if(!requireNamespace(pkg,quietly=TRUE))
  install.packages(pkg,lib='work/Rlib',repos='https://cloud.r-project.org')
for(yr in c(2022,2025)) for(nm in c('adult-codebook.pdf','adult-summary.pdf','srvydesc-508.pdf')) {
  dest<-sprintf('work/docs/%s-%s',yr,nm)
  if(!file.exists(dest)) download.file(sprintf('https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/%s/%s',yr,nm),dest,mode='wb')
  writeLines(pdftools::pdf_text(dest),sub('pdf$','txt',dest))
}
