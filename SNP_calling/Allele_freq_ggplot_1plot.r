#If the library has not been previously installed, run : install.packages("ggplot2")
library(ggplot2)

#First setwd("Wheregetget the file is")
#Get all the files in the current directory
LIBS <-list.files();

name<-c();
Table<-c();
AF<-c();
for(i in 1:length(LIBS)){
  name<-substr(LIBS[i],1,8);
  Table<-read.csv(LIBS[i], header=T, sep="\t");
  AF<-c();
  AF<-ggplot(Table, aes(freq))+xlim(0,1);
  AF<-AF+geom_histogram(binwidth=0.015) #+facet_grid(rank ~ .)
  pdf(paste(name,"allele_fre.pdf", sep = ""))
  print(AF)
  dev.off()
}