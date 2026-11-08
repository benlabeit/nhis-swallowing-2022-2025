# Run from the project root: Rscript work/all_adults/build_figures.R
# Revised primary adult analysis. Plot saved, validated estimates only.
if (.Platform$OS.type == 'windows') Sys.setlocale('LC_CTYPE', 'English_United States.utf8')
.libPaths(c('work/Rlib', .libPaths()))
library(grid)
out <- 'outputs/all_adults/figures'
dir.create(out, recursive=TRUE, showWarnings=FALSE)
main <- read.delim('outputs/all_adults/all_results.tsv', check.names=FALSE)
main <- main[main$agegroup=='all',]
counts <- read.delim('outputs/all_adults/cell_counts.tsv', check.names=FALSE)
counts <- counts[counts$proxy_status=='all',]
comparisons <- read.delim('outputs/all_adults/primary_comparison_all_methods.tsv', check.names=FALSE)
ages <- read.delim('outputs/all_adults/age_specific_results.tsv', check.names=FALSE)
stopifnot(!anyDuplicated(main[c('analysis','group','outcome','estimate_type')]))

row <- function(group, outcome='any', kind='difference_2025_minus_2022', analysis='main') {
  z <- main[main$group==group & main$outcome==outcome & main$estimate_type==kind & main$analysis==analysis,]
  stopifnot(nrow(z)==1, all(is.finite(as.matrix(z[c('estimate','lcl','ucl')]))),
            z$lcl<=z$estimate, z$estimate<=z$ucl)
  z
}
methods <- c('crude','main','age_sex_adjusted','self_direct_age_standardized','self_age_sex_adjusted')
methodrow <- function(group, method) {
 z <- comparisons[comparisons$group==group & comparisons$outcome=='any' & comparisons$estimate_type=='difference_2025_minus_2022' & comparisons$analysis==method,]
 stopifnot(nrow(z)==1,all(is.finite(as.matrix(z[c('estimate','lcl','ucl')]))),z$lcl<=z$estimate,z$estimate<=z$ucl)
 z
}
agerow <- function(group, age) {
 z <- ages[ages$group==group & ages$outcome=='any' & ages$agegroup==age & ages$estimate_type=='difference_2025_minus_2022',]
 stopifnot(nrow(z)==1,all(is.finite(as.matrix(z[c('estimate','lcl','ucl')]))),z$lcl<=z$estimate,z$estimate<=z$ucl)
 z
}

palette <- list(ink='#182F40', muted='#4D5B64', grid='#DCE2E6', blue='#0072B2',
                orange='#D55E00', grey='#6E7C85', zero='#6A7882')
width_mm <- 165
heights_mm <- c(100, 110, 110, 110, 100)
left <- .025; indent <- .045; forest_left <- .405; forest_right <- .720; values_right <- .985
fmt <- function(x, sign=FALSE) gsub('-', '\u2212', sprintf(if(sign) '%+.2f' else '%.2f', x), fixed=TRUE)
interval <- function(z, difference=TRUE) paste0(fmt(100*z$estimate,difference), ' [', fmt(100*z$lcl), ', ', fmt(100*z$ucl), ']')

text <- function(label, x, y, size=9, col=palette$ink, bold=FALSE, just='left', xmax=NULL, xmin=NULL) {
  gp <- gpar(fontsize=size, fontfamily='Arial', col=col, fontface=if(bold)'bold' else 'plain', lineheight=1.05)
  g <- textGrob(label, x=x, y=y, just=just, gp=gp)
  # Check actual rendered string width against the assigned column, on every device.
  w <- convertWidth(grobWidth(g), 'npc', valueOnly=TRUE)
  lo <- x - if(just=='right') w else if(just=='centre') w/2 else 0
  hi <- x + if(just=='left') w else if(just=='centre') w/2 else 0
  stopifnot(lo >= -.001, hi <= 1.001)
  if(!is.null(xmax)) stopifnot(hi <= xmax)
  if(!is.null(xmin)) stopifnot(lo >= xmin)
  grid.draw(g)
}
line <- function(x0,y0,x1,y1,col=palette$grid,width=.65,type=1) {
  grid.lines(c(x0,x1),c(y0,y1),gp=gpar(col=col,lwd=width,lty=type))
}
page <- function(left_header, value_header) {
  grid.newpage()
  grid.rect(gp=gpar(fill='white',col=NA))
  text(left_header,left,.955,8.5,col=palette$muted,xmax=forest_left-.01)
  text(value_header,values_right,.955,8.5,col=palette$muted,just='right',xmin=forest_right+.015)
  line(left,.920,values_right,.920,width=.7)
}
axis <- function(limits,ticks,bottom,top,zero=FALSE) {
  X <- function(value) forest_left + (value-limits[1])/diff(limits)*(forest_right-forest_left)
  attr(X,'limits') <- limits
  for(value in ticks) {
    line(X(value),bottom,X(value),top,
         if(value==0 && zero)palette$zero else palette$grid,
         if(value==0 && zero)1 else .55,
         if(value==0 && zero)2 else 1)
    text(gsub('-','\u2212',as.character(value),fixed=TRUE), X(value), bottom-.032,8.5,
         col=palette$muted,just='centre')
  }
  line(forest_left,bottom,forest_right,bottom,palette$muted,.65)
  X
}
point <- function(z,y,X,col=palette$blue,pch=16,open=FALSE) {
  limits <- attr(X,'limits')
  stopifnot(all(100*c(z$lcl,z$ucl)>=limits[1]),all(100*c(z$lcl,z$ucl)<=limits[2]))
  line(X(100*z$lcl),y,X(100*z$ucl),y,col,1.35)
  for(value in c(z$lcl,z$ucl)) line(X(100*value),y-.006,X(100*value),y+.006,col,.9)
  grid.points(unit(X(100*z$estimate),'npc'),unit(y,'npc'),pch=if(open)if(pch==15)22 else 21 else pch,size=unit(2.0,'mm'),
              gp=gpar(col=col,fill=if(open)'white' else col,lwd=1.05))
}
group_names <- c('All adults aged 18+','With a history of stroke','Without a history of stroke')
group_ids <- c('all','stroke','no_stroke')
selected <- list()
age_ids <- c('18-44','45-64','65-74','75-84','85+')
age_labels <- gsub('-', '\u2013', age_ids, fixed=TRUE)
fig1_rows <- do.call(rbind,lapply(group_ids,function(g)do.call(rbind,lapply(c(2022,2025),function(y)row(g,kind=paste0('standardized_',y))))))
fig2_rows <- do.call(rbind,lapply(group_ids,function(g)do.call(rbind,lapply(c('any','severe','long'),function(o)row(g,o)))))
fig3_rows <- do.call(rbind,lapply(group_ids[1:2],function(g)do.call(rbind,lapply(methods,function(m)methodrow(g,m)))))
fig4_rows <- do.call(rbind,lapply(group_ids[1:2],function(g)do.call(rbind,lapply(age_ids,function(a)agerow(g,a)))))
figS1_rows <- do.call(rbind,lapply(group_ids[1:2],function(g)do.call(rbind,lapply(1:4,function(j)row(g,c('any','any','opposite_low','opposite_high')[j],analysis=c('main','Q1_Q3','missing_bounds','missing_bounds')[j])))))
for(g in group_ids[1:2]) stopifnot(max(abs(as.numeric(methodrow(g,'main')[1,c('estimate','lcl','ucl')])-as.numeric(row(g)[1,c('estimate','lcl','ucl')])))<1e-12)
limitsfor <- function(z, prevalence=FALSE) {
 rr <- range(c(0,100*z$lcl,100*z$ucl)); ticks <- pretty(rr,n=4)
 if(prevalence)ticks<-ticks[ticks>=0]
 list(limits=range(ticks),ticks=ticks)
}
flag <- function(z) 'fragile' %in% names(z) && isTRUE(z$fragile)

fig1 <- function() {
  page('Year; events / valid responses','Prevalence, % [95% CI]')
  sc<-limitsfor(fig1_rows,TRUE); X <- axis(sc$limits, sc$ticks, .120,.875)
  for(i in 1:3) {
    h <- c(.860,.590,.320)[i]
    text(group_names[i],left,h,9.5,bold=TRUE,xmax=forest_left-.01)
    for(j in 1:2) {
      yr <- c(2022,2025)[j]; y <- h-c(.065,.145)[j]
      z <- row(group_ids[i],kind=paste0('standardized_',yr))
      ct <- counts[counts$year==yr & counts$group==group_ids[i] & counts$agegroup=='all' & counts$outcome=='any',]
      stopifnot(nrow(ct)==1,z$n==ct$valid,z$events==ct$yes)
      color <- if(j==1)palette$blue else palette$orange
      text(paste0(yr,'   ',z$events,' / ',format(z$n,big.mark=',',scientific=FALSE,trim=TRUE)),
           indent,y,9,col=color,xmax=forest_left-.01)
      point(z,y,X,color,if(j==1)16 else 15,open=flag(z))
      text(interval(z,FALSE),values_right,y,9,just='right',xmin=forest_right+.015)
    }
  }
  text('Age-standardized prevalence (%)',.635,.035,9,just='centre')
}
fig2 <- function() {
  page('Population / outcome','Difference [95% CI]')
  sc<-limitsfor(fig2_rows); X <- axis(sc$limits,sc$ticks,.100,.875,zero=TRUE)
  labels <- c('Swallowing difficulties','Substantial difficulty','Symptoms for \u2265180 days')
  for(i in 1:3) {
    h <- c(.860,.605,.350)[i]
    text(group_names[i],left,h,9.5,bold=TRUE,xmax=forest_left-.01)
    for(j in 1:3) {
      y <- h-c(.055,.120,.185)[j]
      z <- row(group_ids[i],c('any','severe','long')[j])
      text(labels[j],indent,y,8.8,bold=j==1,xmax=forest_left-.01)
      point(z,y,X,if(j==1)palette$blue else palette$grey,open=flag(z))
      text(interval(z),values_right,y,9,just='right',xmin=forest_right+.015)
    }
  }
  text('Prevalence difference (percentage points)',.635,.026,9,just='centre')
}
fig3 <- function() {
  page('Population / analysis method','Difference [95% CI]')
  sc<-limitsfor(fig3_rows); X <- axis(sc$limits,sc$ticks,.100,.875,zero=TRUE)
  labels <- c('Crude prevalence','Direct age standardization','Age and sex adjustment',
              'Self-responses only:\ndirect age standardization',
              'Self-responses only:\nage and sex adjustment')
  for(i in 1:2) {
    h <- c(.860,.465)[i]
    text(group_names[i],left,h,9.5,bold=TRUE,xmax=forest_left-.01)
    for(j in 1:5) {
      y <- h-c(.055,.120,.185,.250,.315)[j]
      z <- methodrow(group_ids[i],methods[j])
      text(labels[j],indent,y,8.5,bold=j==2,xmax=forest_left-.01)
      point(z,y,X,if(j<=3)palette$blue else palette$grey,if(j==2)15 else 16)
      text(interval(z),values_right,y,9,just='right',xmin=forest_right+.015)
    }
  }
  text('Prevalence difference (percentage points)',.635,.028,9,just='centre')
}
fig4 <- function() {
  page('Age; events / valid responses','Difference [95% CI]')
  sc<-limitsfor(fig4_rows); X <- axis(sc$limits,sc$ticks,.100,.875,zero=TRUE)
  for(i in 1:2) {
    h<-c(.860,.465)[i]
    text(group_names[i],left,h,9.5,bold=TRUE,xmax=forest_left-.01)
    for(j in 1:5) {
      y<-h-c(.055,.120,.185,.250,.315)[j]; z<-agerow(group_ids[i],age_ids[j])
      ct<-counts[counts$group==group_ids[i]&counts$agegroup==age_ids[j]&counts$outcome=='any',]
      ct<-ct[match(c(2022,2025),ct$year),]
      stopifnot(nrow(ct)==2,!anyNA(ct$year),identical(as.integer(ct$year),c(2022L,2025L)))
      text(paste0(age_labels[j],' years'),indent,y+.014,8.8,xmax=forest_left-.01)
      labs<-paste0(ct$yes,'/',format(ct$valid,big.mark=',',scientific=FALSE,trim=TRUE))
      text(paste0('2022: ',labs[1],'   2025: ',labs[2]),indent,y-.020,8.0,col=palette$muted,xmax=forest_left-.01)
      point(z,y,X,if(i==1)palette$blue else palette$orange,open=flag(z))
      text(interval(z),values_right,y,9,just='right',xmin=forest_right+.015)
    }
  }
  text('Prevalence difference (percentage points)',.635,.028,9,just='centre')
}
figS1 <- function() {
  page('Population / analysis assumption','Difference [95% CI]')
  sc<-limitsfor(figS1_rows); X <- axis(sc$limits,sc$ticks,.115,.875,zero=TRUE)
  labels <- c('Main analysis: valid responses','Quarters 1\u20133 only',
              'Missing responses:\n2022 yes / 2025 no',
              'Missing responses:\n2022 no / 2025 yes')
  for(i in 1:2) {
    h <- c(.860,.480)[i]
    text(group_names[i],left,h,9.5,bold=TRUE,xmax=forest_left-.01)
    for(j in 1:4) {
      y <- h-c(.065,.140,.215,.290)[j]
      z <- row(group_ids[i],c('any','any','opposite_low','opposite_high')[j],
               analysis=c('main','Q1_Q3','missing_bounds','missing_bounds')[j])
      text(labels[j],indent,y,8.5,bold=j==1,xmax=forest_left-.01)
      point(z,y,X,if(j<=2)palette$blue else palette$grey,if(j<=2)16 else 18)
      text(interval(z),values_right,y,9,just='right',xmin=forest_right+.015)
    }
  }
  text('Prevalence difference (percentage points)',.635,.028,9,just='centre')
}
figures <- list(fig1,fig2,fig3,fig4,figS1)
figure_ids <- c('1','2','3','4','S1')
for(i in seq_along(figures)) {
  file <- file.path(out,paste0('Fig',figure_ids[i]))
  w <- width_mm/25.4; h <- heights_mm[i]/25.4
  png(paste0(file,'.png'),width=w,height=h,units='in',res=600,type='cairo',bg='white')
  figures[[i]]();dev.off()
  svg(paste0(file,'.svg'),width=w,height=h,family='Arial',bg='white')
  figures[[i]]();dev.off()
  cairo_pdf(paste0(file,'.pdf'),width=w,height=h,family='Arial',bg='white')
  figures[[i]]();dev.off()
  cairo_ps(paste0(file,'.eps'),width=w,height=h,family='Arial',bg='white',onefile=FALSE)
  figures[[i]]();dev.off()
}

# Export the exact plotted source rows; there is no re-estimation or rounding here.
plotted <- list(fig1_rows,fig2_rows,fig3_rows,fig4_rows,figS1_rows)
for(i in seq_along(figures))write.table(plotted[[i]],file.path(out,paste0('Fig',figure_ids[i],'_values.tsv')),sep='\t',row.names=FALSE)
writeLines(c('Journal figure redraw validation',
             'Four main figures and supplementary FigS1, 165 mm wide; heights 100, 110, 110, 110 and 100 mm.',
             'PNG: 600 dpi. PDF/SVG/EPS: vector. Arial; labels 8-9.5 pt.',
             'No embedded figure number, title, subtitle, caption or methods/source footnote.',
             'Column headings, axis labels, group labels and estimates remain inside the artwork.',
             'All plotted records are copied from saved results, not re-estimated.',
             'Every point/interval is finite and contained in the axis range.',
             'Actual text widths checked for page and column containment on all four devices.',
             'Figures 1 and 4 event/denominator counts match the adult count table.',
             'Central analysis uses all adults aged 18+ and a separate stroke-history group.',
             paste('Input MD5:',paste(names(tools::md5sum(c('outputs/all_adults/all_results.tsv','outputs/all_adults/cell_counts.tsv','outputs/all_adults/primary_comparison_all_methods.tsv','outputs/all_adults/age_specific_results.tsv'))),
               unname(tools::md5sum(c('outputs/all_adults/all_results.tsv','outputs/all_adults/cell_counts.tsv','outputs/all_adults/primary_comparison_all_methods.tsv','outputs/all_adults/age_specific_results.tsv'))),collapse='; '))),
           file.path(out,'validation.txt'))
capture.output(sessionInfo(),file=file.path(out,'software.txt'))
writeLines(c('Journal artwork - four English main figures and supplementary FigS1',
             'Use Fig1.png through Fig4.png in Word at a width of 165 mm.',
             'Use Fig1.pdf through Fig4.pdf, or the corresponding EPS files, for vector submission.',
             'PNG images are 600 dpi; SVG copies are also provided.',
             'Do not add titles or figure captions to the artwork; supply them separately in the manuscript.',
             'Captions must explain the symbols, confidence intervals, exploratory analyses and source limitations.',
             'Fig2 labels the severe outcome Substantial difficulty; it is the response a lot.',
             'Reproduce from project root: Rscript work/all_adults/build_figures.R',
             'Historical older-adult figures remain unchanged in their original directories.'),file.path(out,'README.txt'))
