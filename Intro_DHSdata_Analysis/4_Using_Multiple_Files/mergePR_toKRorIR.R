# *****************************************************************************************************
# Program: 			mergePR_toKRorIR.R
# Purpose: 			merge PR to a KR or IR file. Each example is shown separately. 
# Author:				Shireen Assaf
# Date last modified: July 27, 2023 by Shireen Assaf 
# Note:			The master file is the KR or the IR file (each example shown separately)
# 					The using file is the PR file.
# 					The same steps used to merge IR and PR can be used for MR and PR but with mv variables. 
# *****************************************************************************************************
library(haven)
library(dplyr)
library(here)
here() # check your path, this is where you should have your saved datafiles

# Merging KR and PR file
 
# Step 1. Open your using data file
PRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZPR62FL.dta"))
		
# Step 2. Rename IDs (uniquely identify a case)
PRdata <- PRdata %>%
  mutate(v001=hv001) %>%
  mutate(v002=hv002) %>%
  mutate(b16=hvidx) 

# *Step 3. Open master dataset
KRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZKR62FL.dta"))

# Step 5. Merge two datasets

# drop children who died or are not listed in the household 
KRdata <- KRdata %>%
  subset(b16 > 0 & b5==1) 
  
# merge
KRPRdata <- merge(KRdata,PRdata,by=c("v001", "v002", "b16"))

#optional: remove original datasets and only keep the merged dataset
rm(PRdata)
rm(KRdata)

# *****************************************************************************************************
# *****************************************************************************************************
# Merging IR and PR file

 
# Step 1. Open your using data file
PRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZPR62FL.dta"))
		
# Step 2. Rename IDs (uniquely identify a case)
PRdata <- PRdata %>%
  mutate(v001=hv001) %>%
  mutate(v002=hv002) %>%
  mutate(v003=hvidx) 

# Step 3. Open master dataset
IRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZIR62FL.dta"))
	
# Step 4. Merge two datasets
IRPRdata <- merge(IRdata,PRdata,by=c("v001", "v002", "v003"))

#optional: remove original datasets and only keep the merged dataset
rm(PRdata)
rm(IRdata)

