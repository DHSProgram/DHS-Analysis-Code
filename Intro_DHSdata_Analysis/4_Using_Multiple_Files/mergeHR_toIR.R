# *****************************************************************************************************
# Program: 			mergeHR_toIR.R
# Purpose: 			merge HR to IR file. 
# Author:				Shireen Assaf
# Date last modified: July 27, 2023 by Shireen Assaf 
# Note:				This is an example of a many to one merge, since there are many women in one household
# *****************************************************************************************************

# open HR dataset 
HRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZHR62FL.dta"))

# Rename merging variables(identifiers)
HRdata <- HRdata %>%
  mutate(v001=hv001) %>%
  mutate(v002=hv002)

# optional, keep relevant vars. For instance, lets say you only need information on source of drinking water (hv201)
# HRdata <- subset(HRdata, select=c(v001, v002, hv201))

# Open master dataset
IRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZIR62FL.dta"))

# Merge two datasets
IRHRdata <- merge(IRdata,HRdata,by=c("v001", "v002"))

#optional: remove original datasets and only keep the merged dataset
rm(HRdata)
rm(IRdata)
