# *****************************************************************************************************
# Program: 			mergeAR_toIRorMR.R
# Purpose: 			merge AR data containing HIV test results to a IR or MR file. 
# 					    Each example is shown separately. 
# Author:				Shireen Assaf
# Date last modified: July 27, 2023 by Shireen Assaf 
# Note:				  The master file is the IR or the MR file (each example shown separately)
# 					    The using file is the AR file.
# 					    There is an option at the end of the do file to append the IR and MR merged files if needed for the analysis. 
# *****************************************************************************************************

library(haven)
library(dplyr)
library(here)
here() # check your path, this is where you should have your saved datafiles

# Open your using data file
ARdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZAR61FL.dta"))
		
# Rename IDs (uniquely identify a case)
ARdata <- ARdata %>%
  mutate(v001=hivclust) %>%
  mutate(v002=hivnumb) %>%
  mutate(v003=hivline) 
	
# Open master dataset
IRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZIR62FL.dta"))

# Merge two datasets
IRARdata <- merge(IRdata,ARdata,by=c("v001", "v002", "v003"))

#generate a sex variable that may be used later for a pooled dataset
IRARdata <- IRARdata %>%
  mutate(sex=2)

#optional: remove original datasets and only keep the merged dataset
rm(ARdata)
rm(IRdata)

# *****************************************************************************************************
# *****************************************************************************************************
# Merging AR and MR file

# Open your using data file
ARdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZAR61FL.dta"))

# Rename IDs (uniquely identify a case)
ARdata <- ARdata %>%
  mutate(mv001=hivclust) %>%
  mutate(mv002=hivnumb) %>%
  mutate(mv003=hivline) 

# Open master dataset
MRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZMR61FL.dta"))

# Merge two datasets
MRARdata <- merge(MRdata,ARdata,by=c("mv001", "mv002", "mv003"))

#generate a sex variable that may be used later for a pooled dataset
MRARdata <- MRARdata %>%
  mutate(sex=1)

#optional: save as a Stata data file if needed (may need this later for appending files)
library(foreign) 
write.dta(MRARdata, here("Intro_DHSdata_Analysis","ZZMRAR.dta"))

#optional: remove original datasets and only keep the merged dataset
rm(ARdata)
rm(MRdata)

# *****************************************************************************************************
# *****************************************************************************************************
# Optional if you want to append MR and IR files that contain the HIV results

# use ZZMRAR.dta, clear
MRARdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZMRAR.dta"))

# rename mv variables to match the v variables, this is needed before appending files
colnames(MRARdata) <- gsub("mv", "v", colnames(MRARdata))

# append the IR and MR files using bind_rows from the dplyr package. 
# r(bind) does not work as there are different number of columns in the two datasets

library(dplyr)
IRMRAR <- bind_rows(MRARdata, IRARdata)

library(labelled) 

# label the sex variable
IRMRAR <- IRMRAR %>%
  set_value_labels(sex = c(man = 1, woman = 2)) 


#optional: remove unused datasets
rm(ARdata)
rm(MRARdata)
rm(IRdata)
rm(IRARdata)


