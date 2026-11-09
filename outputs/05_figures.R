# Reproduce from project root: Rscript outputs/05_figures.R
# Scientific figures from saved estimates. No inferential results are recomputed.
if (.Platform$OS.type=='windows') Sys.setlocale('LC_CTYPE','English_United States.utf8')
library(grid)
.libPaths(c('work/Rlib',.libPaths()))
root <- 'outputs/figures'
dir.create(root,recursive=TRUE,showWarnings=FALSE)
r<-read.delim('outputs/standardized_results.tsv',check.names=FALSE)
counts<-read.delim('outputs/cell_counts.tsv',check.names=FALSE)
stopifnot(!anyDuplicated(r[c('analysis','group','outcome','estimate_type')]))
getrow<-function(gr,v='any',kind='difference_2025_minus_2022',anal='main') {
 z<-r[r$group==gr & r$outcome==v & r$estimate_type==kind & r$analysis==anal,]
 stopifnot(nrow(z)==1,all(is.finite(as.matrix(z[c('estimate','lcl','ucl')]))),z$lcl<=z$estimate,z$estimate<=z$ucl)
 z
}
C<-list(ink='#182F40',muted='#536574',grid='#DEE5E9',blue='#0072B2',orange='#D55E00',grey='#77848C',pale='#F3F6F8')
T<-list(
 en=list(groups=c('All adults aged 65+','With a history of stroke','Without a history of stroke'),
   titles=c('Swallowing difficulties at age 65+','Absolute differences between survey years','Sensitivity of the year comparison'),
   subs=c('12-month prevalence by reported history of stroke',
          'Age-standardized prevalence in 2025 minus 2022',
          'Swallowing difficulties: 2025 minus 2022; two population groups'),
   axis=c('Age-standardized prevalence (%)','Prevalence difference (percentage points)'),
   estimate=c('Prevalence % [95% CI]','Difference [95% CI]'),
   outcomes=c('Swallowing difficulties','Severe difficulties','Difficulties lasting \u2265180 days'),
   scenarios=c('Main analysis: valid responses','Quarters 1-3 only','Missing: 2022 yes / 2025 no','Missing: 2022 no / 2025 yes'),
   left=c('Group / year; events / valid responses','Group / outcome','Group / analysis assumption'),
   source='Source: NCHS, NHIS 2022 and 2025; authors\u2019 calculations.',
   note1='US 2000 age standard; survey weights, strata and clusters accounted for.',
   note2='Open markers: sparse age cells. Secondary outcomes and subgroups are exploratory.',
   note3='CIs are conditional on each assumption; extreme scenarios serve as bounds.')
)
lang<-'en';tr<-T[[lang]]
num<-function(v,sign=FALSE) {
 s<-sprintf(if(sign)'%+.2f' else '%.2f',v)
 gsub('-', '\u2212', s, fixed=TRUE)
}
interval<-function(z,diff=FALSE) paste0(num(100*z$estimate,diff),' [',num(100*z$lcl),'; ',num(100*z$ucl),']')
tx<-function(s,x,y,size=10,col=C$ink,face='plain',just='left')
 grid.text(s,x,y,just=just,gp=gpar(fontsize=size,fontfamily='Arial',col=col,fontface=face))
ln<-function(x0,y0,x1,y1,col=C$grid,lwd=1,lty=1)
 grid.lines(c(x0,x1),c(y0,y1),gp=gpar(col=col,lwd=lwd,lty=lty))
basepage<-function(index) {
 grid.newpage();grid.rect(gp=gpar(fill='white',col=NA))
 tx(paste0('NHIS 2022 / 2025  |  ','FIGURE ',index),.04,.972,8,C$muted)
 tx(tr$titles[index],.04,.919,17,face='bold')
 tx(tr$subs[index],.04,.873,10,C$muted)
}
axisplot<-function(limits,ticks,y0,y1,x0=.405,x1=.718,zero=FALSE,axis_y=y0) {
 X<-function(v) x0+(v-limits[1])/diff(limits)*(x1-x0)
 for(v in ticks) {
   ln(X(v),y0,X(v),y1,if(v==0 && zero)'#8796A0' else C$grid,if(v==0 && zero)1.3 else .6,if(v==0 && zero)2 else 1)
   tx(gsub('-', '\u2212',as.character(v),fixed=TRUE),X(v),axis_y-.024,9,C$muted,just='centre')
 }
 ln(x0,axis_y,x1,axis_y,C$muted,.7)
 X
}
point<-function(z,y,X,col=C$ink,pch=16,open=FALSE,size=2.2) {
 stopifnot(all(100*c(z$lcl,z$ucl)>=attr(X,'limits')[1]-1e-8),all(100*c(z$lcl,z$ucl)<=attr(X,'limits')[2]+1e-8))
 ln(X(100*z$lcl),y,X(100*z$ucl),y,col,1.6)
 for(v in c(z$lcl,z$ucl)) ln(X(100*v),y-.005,X(100*v),y+.005,col,1)
 grid.points(unit(X(100*z$estimate),'npc'),unit(y,'npc'),pch=if(open)21 else pch,size=unit(size,'mm'),gp=gpar(col=col,fill=if(open)'white' else col,lwd=1.4))
}
figure1<-function() {
 basepage(1)
 tx(tr$left[1],.04,.804,9,C$muted);tx(tr$estimate[1],.965,.804,9,C$muted,just='right')
 X<-axisplot(c(0,30),seq(0,30,5),.195,.775,x0=.405,x1=.718);attr(X,'limits')<-c(0,30)
 grs<-c('all','stroke','no_stroke')
 for(i in 1:3) {
   h<-c(.755,.555,.355)[i];tx(tr$groups[i],.04,h,11,face='bold')
   for(j in 1:2) {
     yr<-c(2022,2025)[j];y<-h-c(.047,.11)[j];z<-getrow(grs[i],kind=paste0('standardized_',yr))
     ct<-counts[counts$year==yr & counts$group==grs[i] & counts$agegroup=='all' & counts$outcome=='any',]
     stopifnot(z$n==ct$valid,z$events==ct$yes)
     tx(paste0(yr,'   ',z$events,' / ',format(z$n,big.mark=',',decimal.mark='.',scientific=FALSE,trim=TRUE)),.065,y,10,if(j==1)C$blue else C$orange)
     point(z,y,X,if(j==1)C$blue else C$orange,pch=if(j==1)16 else 15,size=2.4)
     tx(interval(z),.965,y,10,just='right')
   }
 }
 tx(tr$axis[1],.5615,.132,10,just='centre')
 tx(tr$note1,.04,.070,8.2,C$muted)
 tx(tr$source,.04,.036,8,C$muted)
}
figure2<-function() {
 basepage(2)
 tx(tr$left[2],.04,.815,9,C$muted);tx(tr$estimate[2],.965,.815,9,C$muted,just='right')
 X<-axisplot(c(-4,12),seq(-4,12,4),.135,.795,zero=TRUE);attr(X,'limits')<-c(-4,12)
 for(i in 1:3) {
   h<-c(.77,.55,.33)[i];tx(tr$groups[i],.04,h,11,face='bold')
   for(j in 1:3) {
     y<-h-c(.043,.097,.151)[j];z<-getrow(c('all','stroke','no_stroke')[i],c('any','severe','long')[j])
     tx(tr$outcomes[j],.055,y,9.8,face=if(j==1)'bold' else 'plain')
     point(z,y,X,col=if(j==1)C$blue else C$grey,open=z$fragile,size=2.3)
     tx(interval(z,TRUE),.965,y,10,just='right')
   }
 }
 tx(tr$axis[2],.5615,.085,10,just='centre')
 tx(tr$note2,.04,.042,8.2,C$muted)
 tx(tr$source,.04,.018,8,C$muted)
}
figure3<-function() {
 basepage(3)
 tx(tr$left[3],.04,.814,9,C$muted);tx(tr$estimate[2],.965,.814,9,C$muted,just='right')
 X<-axisplot(c(-5,16),c(-5,0,5,10,15),.157,.791,zero=TRUE);attr(X,'limits')<-c(-5,16)
 for(i in 1:2) {
   h<-c(.768,.451)[i];tx(tr$groups[i],.04,h,11,face='bold')
   for(j in 1:4) {
     y<-h-c(.047,.107,.167,.227)[j]
     z<-getrow(c('all','stroke')[i],c('any','any','opposite_low','opposite_high')[j],anal=c('main','Q1_Q3','missing_bounds','missing_bounds')[j])
     tx(tr$scenarios[j],.055,y,9.5,face=if(j==1)'bold' else 'plain')
     point(z,y,X,col=if(j<=2)C$blue else C$grey,pch=if(j<=2)16 else 18,size=2.3)
     tx(interval(z,TRUE),.965,y,10,just='right')
   }
 }
 tx(tr$axis[2],.5615,.103,10,just='centre')
 tx(tr$note3,.04,.059,8,C$muted)
 tx(tr$source,.04,.028,8,C$muted)
}
figs<-list(figure1,figure2,figure3)
filenames<-c('Figure_1_Prevalence','Figure_2_Prevalence_differences','Figure_3_Sensitivity')
heights<-c(6.2,8.2,7.3)
for(lang in 'en') {
 tr<-T[[lang]]
 for(i in 1:3) {
   fn<-file.path(root,filenames[i])
   png(paste0(fn,'.png'),width=9,height=heights[i],units='in',res=300,type='cairo',bg='white')
   figs[[i]]();dev.off()
   svg(paste0(fn,'.svg'),width=9,height=heights[i],family='Arial',bg='white')
   figs[[i]]();dev.off()
 }
}
# English-only PDF, three pages. A common page size preserves type size.
cairo_pdf(file.path(root,'NHIS_Figures_EN.pdf'),width=9,height=8.2,onefile=TRUE,family='Arial',bg='white')
lang<-'en';tr<-T[[lang]];for(i in 1:3) figs[[i]]()
dev.off()
capture.output(sessionInfo(),file=file.path(root,'software_figures.txt'))
writeLines(c('All plotted records uniquely matched by analysis/group/outcome/estimate_type.',
 'All plotted CIs finite, ordered and fully inside the x axis.',
 'Figure 1 events and denominators agree with unweighted cell counts.',
 'Only saved estimates plotted; no new statistical testing.',
 paste('Input MD5:',unname(tools::md5sum('outputs/standardized_results.tsv')))),file.path(root,'figure_validation.txt'))
