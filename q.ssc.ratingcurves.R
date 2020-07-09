#Tijuana River at Dairy Mart Road N. branch
#create rating curve with SSC Q monitoring data 

library(ggplot2)
library(tidyverse)
library(lubridate)

#SSC sample dir
ssc.dir <- "C:/Users/KristineT.SCCWRP2K/OneDrive - SCCWRP/OPC_sedflux/TJR_data/from_Ben_SDSU/SCCWRP/processed.samples/"
files <- list.files(ssc.dir, full.names = TRUE)
#read in SSC data
tjr1 <- read.csv(files[3])
tjr1 <- tjr1[1:24,] #remove excess rows
tjr2 <- read.csv(files[4])
tjr3 <- read.csv(files[5])
#create new df with combined dataset
sample.set <- c(as.character(tjr1$Sample.Set), as.character(tjr2$Sample.Set), as.character(tjr3$Sample.Set))
sample <- c(tjr1$Sample..Number, tjr2$Sample..Number, tjr3$Sample..Number)
ssc.g.mL <- c(tjr1$NFR, tjr2$NFR, tjr3$NFR)
ssc.df <- data.frame(cbind(sample.set, sample, ssc.g.mL))
#remove NA rows
ssc.df <- ssc.df[-which(is.na(ssc.g.mL)),]
ssc.df$sample.set <- gsub("-","_", ssc.df$sample.set)

#read in data Q and sample date.time data
Q.data <- read.csv("C:/Users/KristineT.SCCWRP2K/OneDrive - SCCWRP/OPC_sedflux/TJR_data/from_Ben_SDSU/SCCWRP/CalcFlowTJR.NB.DMR.csv", skip=5)
names(Q.data) <- c("date.time", "q.cms")
#sample date time data
sample.date.time <- read.csv("C:/Users/KristineT.SCCWRP2K/OneDrive - SCCWRP/OPC_sedflux/TJR_data/from_Ben_SDSU/SCCWRP/all.samples.csv", skip=6)
sample.date.time$sample <- as.character(sample.date.time$sample)
#IBWC gage Q data
ibwc <- read.csv("C:/Users/KristineT.SCCWRP2K/OneDrive - SCCWRP/OPC_sedflux/TJR_data/from_Ben_SDSU/SCCWRP/IBWC_flow_timeseries.csv", skip=1)


#################
#find date.time associated with each sample collected
ssc.merge <- left_join(ssc.df,  sample.date.time, by = c("sample", "sample.set"))
#format date.time
date.time2 <- strptime(ssc.merge$date.time,"%m/%d/%Y %H:%M")
date.time.ssc <- as.POSIXct(date.time2, "%m/%d/%Y %H:%M", tz="UTC")


#format Q date.time to be consistent with sample date.time
Q.data$date.time <- strptime(Q.data$date.time,"%m/%d/%Y %I:%M:%S %p")
q.date.time <- as.POSIXct(Q.data$date.time, "%m/%d/%Y %H:%M", tz="UTC")

#interpolate the Q value at the sample date.time
Q.cms <- approx(q.date.time, Q.data$q.cms, xout = date.time.ssc)
names(Q.cms) <- c("date.time", "q.ssc")

#plot timeseries with pts of when sample was collected
plot(q.date.time, Q.data$q.cms, type="l")
points(Q.cms$date.time, Q.cms$q.ssc, col="red")

#also plot IBWC flow data to see how different
#format date.time
ibwc.date.time <- strptime(ibwc$Timestamp..UTC.08.00.,"%Y-%m-%d %H:%M:%S") 
ibwc.date.time2 <- format(ibwc.date.time, "%m/%d/%Y %H:%M")
ibwc.date.time3 <- as.POSIXct(ibwc.date.time2, "%m/%d/%Y %H:%M", tz="UTC")
#plot ibwc flow data
#lines(ibwc.date.time3, ibwc$Value..Cubic.Meters.Per.Second., col="blue")

#########
#create rating curve SSC and Q
data <- data.frame(cbind(ssc.merge, Q.cms$q.ssc))
names(data) <- gsub("Q.cms.q.ssc", "q.cms", names(data))
data$ssc.g.L <- as.numeric(as.character(data$ssc.g.mL))/1000
#get date so we can group color by date
data$date <- format(date.time2, "%m/%d/%Y")
data$date.time <- as.POSIXct(data$date.time, "%m/%d/%Y %H:%M", tz="UTC")

#plot color pt by date
date.plot.ssc <- ggplot(data = data) +
  geom_point(aes(x= q.cms, y=ssc.g.L, color = factor(date, levels = unique(date)))) + 
  scale_y_log10() + scale_x_log10() +
  scale_colour_manual(name = "Date", labels = unique(data$date), values = c("#9e9ac8","#756bb1","#bae4b3","#31a354","#d95f0e")) 
#plot color by event
event.plot.ssc <- ggplot(data = data) +
  geom_point(aes(x= q.cms, y=ssc.g.L, color = sample.set)) + 
  scale_y_log10() + scale_x_log10() 
  

#######Create rating curve Load and Q
#use load (g/s) vs Q (m3/s)
#convert Q (m3/s) to L/s
data$q.L.s <- data$q.cms*1000 
#multiply Q (L/s) by SSC (g/L)
data$load.g.s <- data$q.L.s * data$ssc.g.L


load <- ggplot(data = data) +
  geom_point(aes(x= q.cms, y=load.g.s)) + 
  scale_y_log10() + scale_x_log10()

#plot color pt by date
date.plot.load <- ggplot(data = data) +
  geom_point(aes(x= q.cms, y=load.g.s, color = factor(date, levels = unique(date)))) + 
  scale_y_log10() + scale_x_log10() +
  scale_colour_manual(name = "Date", labels = unique(data$date), values = c("#9e9ac8","#756bb1","#74c476","#31a354","#d95f0e")) 
date.plot.load
#plot color by event
event.plot.load <- ggplot(data = data) +
  geom_point(aes(x= q.cms, y=load.g.s, color = sample.set)) + 
  scale_y_log10() + scale_x_log10() +
  scale_colour_manual(name = "Event", labels = unique(data$sample.set), values = c("#9e9ac8","#74c476","#d95f0e")) 




#plot flow timeseries

#bubbler data
Q.data$date.time2 <- q.date.time
#ibwc flow data
q.ibwc <- data.frame(cbind(ibwc.date.time3, ibwc$Value..Cubic.Meters.Per.Second.))
names(q.ibwc) <- c("date.time", "Q.cms")


plot <- ggplot(data = Q.data) +
  geom_line(aes(x= date.time2, y=q.cms))  +
  #geom_line(data = q.ibwc, aes(x= date.time, y=Q.cms), color="red") +
  geom_point(data = data, aes(x= date.time, y=q.cms, color= factor(date, levels = unique(date)))) +
  scale_colour_manual(name = "Date", labels = unique(data$date), values = c("#9e9ac8","#756bb1","#bae4b3","#31a354","#d95f0e")) 

#add in TJR3 10-24 points to prioritize which ones to process
tjr3.sample.date.time <- sample.date.time[sample.date.time$sample.set == "TJR_3",]
tjr3.sub <- tjr3.sample.date.time[10:24,]
#get the Q for those times
#interpolate the Q value at the sample date.time
tjr3.sub$date.time2 <- as.POSIXct(tjr3.sub$date.time, "%m/%d/%Y %H:%M", tz="UTC")

Q.cms2 <- approx(q.date.time, Q.data$q.cms, xout = tjr3.sub$date.time2)
names(Q.cms2) <- c("date.time", "q.ssc")
tjr3.sub$q.cms <- Q.cms2$q.ssc

#add in points not processed yet
plot +
  geom_point(data = tjr3.sub, aes(x= date.time2, y=q.cms), color= "yellow") 
  










#check with water level to see if relationship similar (not sure how Q was calc from bubbler)
depth.data <- read.csv("C:/Users/KristineT.SCCWRP2K/OneDrive - SCCWRP/OPC_sedflux/TJR_data/from_Ben_SDSU/SCCWRP/level.TJR.NB.DMR.csv", skip=6)
#format depth date.time to be consistent with sample date.time
depth.data$date.time <- strptime(depth.data$date.time,"%m/%d/%Y %H:%M")
depth.data.date.time <- as.POSIXct(depth.data$date.time, "%m/%d/%Y %H:%M", tz="UTC")
#find depth associated with ssc measurements
depth.m <- approx(depth.data.date.time, depth.data$level, xout = date.time.ssc)
names(depth.m) <- c("date.time", "depth.m")

#use depth data instead of q
data.depth <- data.frame(cbind(as.numeric(as.character(ssc.merge$ssc.g.mL)), depth.m$depth.m))
names(data.depth) <- c("ssc.g.mL", "depth.m")
ggplot(data.depth) +
  geom_point(aes(x= depth.m, y=ssc.g.mL)) + 
  scale_y_log10() + scale_x_log10()

