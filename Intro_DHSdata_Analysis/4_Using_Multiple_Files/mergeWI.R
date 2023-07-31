# *****************************************************************************************************
# Program: 			mergeWI.do
# Purpose: 			example shown to merge WR to IR file. Notes given on how to merge with other files.  
# Author:				Shireen Assaf
# Date last modified: July 31, 2023 by Shireen Assaf 
# 
# Notes:		Older datasets sometimes do not contain the wealth index. 
#           To include the wealth index, a WI file was created for these surveys. 
#           This code will use the Bangladesh 1999-2000 survey as an example since model datasets do not have an WI file.
# 					
# 					Notes are given at the end of the file on how to perform other merges of WI file with other file types. 
# *****************************************************************************************************

library(haven)
library(dplyr)
library(here)
here() # check your path, this is where you should have your saved datafiles

# open IR file
IRdata <-  read_dta(here("Intro_DHSdata_Analysis","BDIR41FL.dta"))

# generate the ID variable with the same name as in the WI file
IRdata <- IRdata %>%
  mutate(whhid=substr(caseid,1,12))

# open WI file
WIdata <-  read_dta(here("Intro_DHSdata_Analysis","BDWI41FL.dta"))

# perform the merge
IRdata <- merge(WIdata,IRdata,by=c("whhid"))

# gen the wealth variable name v190 as in other surveys
IRdata <- IRdata %>%
  mutate(v190=wlthind5)

#optional: remove WI dataset after merge
rm(WIdata)

# ******************************************************************************

# Merging WI file to other file types

# Same code above can be used to merge to KR file
 
# To merge to MR file you only need to change how the whhid and the v190 variables are generated as follows:
# mutate(whhid=substr(mcaseid,1,12))
# mutate(mv190=wlthind5)

# To merge to PR or HR files you only need to change how the whhid and the v190 variables are generated as follows:
# mutate(whhid=substr(hhid,1,12))
# mutate(hv270=wlthind5)
