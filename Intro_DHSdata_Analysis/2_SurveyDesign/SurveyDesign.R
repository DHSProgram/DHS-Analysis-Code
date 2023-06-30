#####################################################################################
# Purpose: Seeting the survey design for DHS data
# Data input: The model dataset women's file (IR file)
# Date Last Modified: Feb 1, 2023 by Shireen Assaf
# 
# Notes/Instructions:
#   
# Please have the model dataset downloaded and ready to use. We will use the IR file.
# You can download the model dataset here: https://www.dhsprogram.com/data/Model-Datasets.cfm
# To run this script you should save the dataset in the same folder as your R scripts.
# For any analysis of DHS data that involves calculating the standard error, the survey design should be set. 
# This allows for using the survey package commands that can be used for tabulations, regressions, etc. 
#####################################################################################

# install and load the packages you need. You only need to install packages once.
# If the packages were installed already from the RecodingDHSVars.R file then no need to install again.
# After installing a package you can load the package using the library command.
install.packages("haven") # used to open dataset with read_dta
install.packages("here") # used for path of your project. Save your datafile in this folder path.
install.packages("dplyr") # used for creating new variables
install.packages("labelled") # used for haven labelled variable creation
install.packages("survey") # used to set survey design
library(haven)
library(here)
library(dplyr)
library(labelled) 
library(survey)

here() # check your path

# open your dataset
IRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZIR62FL.dta"))

# To set the survey design you need three components: the sampling weight, the primary sampling unit, and the strata
# the primary sampling unit is v021
# the strata is v022 for most surveys but for older surveys you may need to compute the strata. Check the Stata strata do file or the final report for this. 
# the sampling weight is v005 for the this file and must be dividing by 1000,000

# creating the sampling weight variable. 
IRdata$wt <- IRdata$v005/1000000

### Setting the survey design using the svydesign command from the survey package ###
# the survey design will be saved in an object named mysurvey, you can change this name to another name
mysurvey<-svydesign(id=IRdata$v021, data=IRdata, strata=IRdata$v022,  weight=IRdata$wt, nest=T)
options(survey.lonely.psu="adjust") 

# the option (survey.lonely.psu="adjust") is used to adjust for the case if there is single PSU within a stratum 

# now that we have set the survey design, we can use the survey package commands. See below for some examples.

# attach your data
attach(IRdata)

# Modern contraceptive use indicator. This indicator was also produced in the RecodingDHSVars.R
IRdata <- IRdata %>%
  mutate(modfp = 
           ifelse(v313 == 3, 1, 0)) %>%   
  set_value_labels(modfp = c(yes = 1, no = 0)) %>%
  set_variable_labels(modfp ="Currently used any modern method")

# to get frequencies
svytable(~modfp, mysurvey)

# to get proportions
prop.table(svytable(~modfp, mysurvey))

#you can save the result in an object
table1 <- prop.table(svytable(~v106, mysurvey))

#then you can refer to this object later on
table1

#if you want sampling error (SE) and confidence intervals (CI), you can use svyby with by=1 for total
svyby(~modfp,by=1,  design=mysurvey, FUN=svymean, vartype=c("se", "ci"))

#if you want to do this for a categorical variable, then you should add as.factor
#below we did not need as.factor since we had a binary variable
#for instance education level, v106, has four categories. You can estimate the SE and cI for each category.
svyby(~as.factor(v106),by=1,  design=mysurvey, FUN=svymean, vartype=c("se", "ci"))

#to check the labels for v106
print_labels(v106)

# Crosstabulation of modfp (modern FP use) and place of education (v106)
table2 <- svyby(~modfp, by = ~v106, design=mysurvey, FUN=svymean, vartype=c("se", "ci"))

table2

# chi-square results 
svychisq(~modfp+v106, mysurvey)

# to see how the survey commands are used for regressions, please check the regression R script. 
