# ****************************************************************************************************
# Program: 			mergeHW.do
# Purpose: 			example shown to merge HW to PR file. Notes given on how to merge with other files.  
# Author:				Shireen Assaf
# Date last modified: July 31, 2021 by Shireen Assaf 
# 
# Notes:		Older datasets may not contain the anthropometry variables according to the WHO reference. 
# 					HW files are created with the WHO reference nutrition indicators that can be merged to datasets.
# 					Will use two Bangladesh surveys as examples since model datasets do not have an HW file.
# *****************************************************************************************************

library(haven)
library(dplyr)
library(here)
here() # check your path, this is where you should have your saved datafiles

# For HW files that have hwhhid
 
# Open HW file
HWdata <-  read_dta(here("Intro_DHSdata_Analysis","BDHW4JFL.dta"))

# Rename ID variables
HWdata <- HWdata %>%
  mutate(hhid=hwhhid) %>%
  mutate(hvidx=hwline) 

# Open PR file
PRdata <-  read_dta(here("Intro_DHSdata_Analysis","BDPR4JFL.dta"))

# Perform the merge
PRdata <- merge(HWdata,PRdata,by=c("hhid", "hvidx"))

#optional: remove HW dataset after merge
rm(HWdata)

# ******************************************************************************

# Some HW files have hwcaseid instead of hwhhid. The following code can be used in this case. 

# Open HW file
HWdata <-  read_dta(here("Intro_DHSdata_Analysis","BDHW41FL.dta"))

#creating unique identifier variables from hwcaseid

HWdata <- HWdata %>%
  mutate(hhid=substr(hwcaseid,1,12)) %>%
  mutate(hvidx=as.numeric(substr(hwcaseid,13,15))) %>%
  mutate(cluster_id=substr(hhid,6,8)) %>%
  mutate(household_id=substr(hhid,9,12))
  
# Open PR file
PRdata <-  read_dta(here("Intro_DHSdata_Analysis","BDPR41FL.dta"))

# create matching indentifiers
PRdata <- PRdata %>%
  mutate(cluster_id=substr(hhid,6,8)) %>%
  mutate(household_id=substr(hhid,9,12))

# Perform the merge
PRdata <- merge(HWdata,PRdata,by=c("cluster_id", "household_id", "hvidx"))

#optional: remove HW dataset after merge
rm(HWdata)
