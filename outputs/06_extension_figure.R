# Reproduce from project root: Rscript outputs/06_extension_figure.R
# Figure 4 plots saved results only; no estimation or new inference.
if(.Platform$OS.type=='windows')Sys.setlocale('LC_CTYPE','English_United States.utf8')
library(grid)
root<-'outputs/figures';dir.create(root,recursive=TRUE,showWarnings=FALSE)
r<-read.delim('outputs/extensions/primary_comparison_all_methods.tsv')
methods<-c('main','age_sex_adjusted','self_direct_age_standardized','self_age_sex_adjusted')
z<-r[r$group=='stroke' & r$outcome=='any' & r$estimate_type=='difference_2025_minus_2022',]
z<-z[match(methods,z$analysis),]
stopifnot(identical(z$analysis,methods),nrow(z)==4,
          all(is.finite(as.matrix(z[c('estimate','lcl','ucl')]))),
          all(z$lcl<=z$estimate & z$estimate<=z$ucl),all(z$lcl*100>= -2 & z$ucl*100<=12))
# Verify that Figure 4's first row is identical to the original result table.
orig<-read.delim('outputs/standardized_results.tsv')
orig<-orig[orig$analysis=='main' & orig$group=='stroke' & orig$outcome=='any' & orig$estimate_type=='difference_2025_minus_2022',]
stopifnot(max(abs(as.numeric(z[1,c('estimate','lcl','ucl')])-as.numeric(orig[1,c('estimate','lcl','ucl')])))<1e-12)
C<-list(ink='#182F40',muted='#536574',grid='#DEE5E9',blue='#0072B2',grey='#77848C')
tx<-function(s,x,y,size=10,col=C$ink,face='plain',just='left')
 grid.text(s,x,y,just=just,gp=gpar(fontsize=size,fontfamily='Arial',col=col,fontface=face))
ln<-function(x0,y0,x1,y1,col=C$grid,lwd=1,lty=1)
 grid.lines(c(x0,x1),c(y0,y1),gp=gpar(col=col,lwd=lwd,lty=lty))
num<-function(x,sign=FALSE)gsub('-','\u2212',sprintf(if(sign)'%+.2f' else '%.2f',x),fixed=TRUE)
draw<-function(){
 grid.newpage();grid.rect(gp=gpar(fill='white',col=NA))
 tx('NHIS 2022 / 2025  |  FIGURE 4',.04,.972,8,C$muted)
 tx('Stroke-group comparison across analysis methods',.04,.918,16.5,face='bold')
 tx('Swallowing difficulties at age 65+: prevalence in 2025 minus 2022',.04,.871,10,C$muted)
 tx('Analysis / included responses',.04,.807,9,C$muted)
 tx('Difference [95% CI]',.965,.807,9,C$muted,just='right')
 X<-function(v).425+(v+2)/14*(.718-.425)
 for(v in seq(-2,12,2)){
  ln(X(v),.217,X(v),.775,if(v==0)'#8796A0' else C$grid,if(v==0)1.2 else .6,if(v==0)2 else 1)
  tx(num(v),X(v),.193,8.8,C$muted,just='centre')
 }
 ln(.425,.217,.718,.217,C$muted,.7)
 labels<-c('Primary: direct age standardization','Model-based age and sex adjustment',
           'Direct age standardization','Model-based age and sex adjustment')
 sublabels<-c('All valid responses','All valid responses','Confirmed self-reports only','Confirmed self-reports only')
 yy<-c(.725,.582,.439,.296)
 for(i in 1:4){
  y<-yy[i];col<-if(i<=2)C$blue else C$grey
  tx(labels[i],.04,y+.016,10,face=if(i==1)'bold' else 'plain')
  tx(sublabels[i],.04,y-.022,8.8,C$muted)
  ln(X(z$lcl[i]*100),y,X(z$ucl[i]*100),y,col,1.7)
  for(v in c(z$lcl[i],z$ucl[i]))ln(X(v*100),y-.006,X(v*100),y+.006,col,1)
  grid.points(unit(X(z$estimate[i]*100),'npc'),unit(y,'npc'),pch=if(i==1)15 else 16,size=unit(2.4,'mm'),gp=gpar(col=col,fill=col))
  tx(paste0(num(z$estimate[i]*100,TRUE),' [',num(z$lcl[i]*100),'; ',num(z$ucl[i]*100),']'),.965,y,10,just='right')
 }
 tx('Prevalence difference (percentage points)',.5715,.147,10,just='centre')
 tx('Age: US 2000 standard. Adjusted margins: fixed 50:50 sex distribution within age groups.',.04,.094,8,C$muted)
 tx('Extensions are post-hoc; confirmed self-report restriction changes the target population.',.04,.064,8,C$muted)
 tx('Source: NCHS, NHIS 2022 and 2025; authors\u2019 calculations. Survey design accounted for.',.04,.034,8,C$muted)
}
fn<-file.path(root,'Figure_4_Stroke_robustness')
png(paste0(fn,'.png'),width=9,height=6.4,units='in',res=300,type='cairo',bg='white');draw();dev.off()
svg(paste0(fn,'.svg'),width=9,height=6.4,family='Arial',bg='white');draw();dev.off()
cairo_pdf(paste0(fn,'.pdf'),width=9,height=6.4,family='Arial',bg='white');draw();dev.off()
write.table(z,paste0(fn,'_values.tsv'),sep='\t',row.names=FALSE)
writeLines(c('Figure 4: four unique source rows matched to saved analysis results.',
             'CIs finite, ordered, fully inside the axis range; original main row matches exactly.',
             'No statistical estimates recomputed.',
             paste('Input MD5:',unname(tools::md5sum('outputs/extensions/primary_comparison_all_methods.tsv')))),paste0(fn,'_validation.txt'))
