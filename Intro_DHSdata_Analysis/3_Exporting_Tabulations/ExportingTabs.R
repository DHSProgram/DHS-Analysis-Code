#####################################################################################
#   Purpose: Exporting tabulations to excel
#   Data input: The model dataset women's file (IR file)
#   Author: Shireen Assaf
# 	Date Last Modified: June 30, 2023 by Shireen Assaf
# 
# Notes/Instructions:
# 
# Please have the model dataset downloaded and ready to use. We will use the IR file.
# You can download the model dataset here: https://www.dhsprogram.com/data/Model-Datasets.cfm
# To run this script you should save the dataset in the same folder as your R scripts.
# We use the svy command after setting the survey design. Please check the SvyCommmandDHS.do file for more details. 
# The excel files produced here will be saved in your working directory or you can change your working directory with the "cd" command
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

# creating the sampling weight variable. 
IRdata$wt <- IRdata$v005/1000000

### Setting the survey design using the svydesign command from the survey package ###
# the survey design will be saved in an object named mysurvey, you can change this name to another name
mysurvey<-svydesign(id=IRdata$v021, data=IRdata, strata=IRdata$v022,  weight=IRdata$wt, nest=T)
options(survey.lonely.psu="adjust") 

# Modern contraceptive use indicator. This indicator was also produced in the RecodingDHSVars.R
IRdata <- IRdata %>%
  mutate(modfp =
           case_when(v313 == 3 ~ 1,
                     v313 < 3 ~ 0 )) %>%
  set_value_labels(modfp = c(yes = 1, no = 0)) %>%
  set_variable_labels(modfp ="Currently used any modern method")

# attach your data
attach(IRdata)

# to get frequencies
svytable(~modfp, mysurvey)

# to get proportions
prop.table(svytable(~modfp, mysurvey))


# to export a table of the weighted percentages of for more than one variable, you can use the following code

# create population subgroups of interest 
# only among women currently in a union
IRdata <- IRdata %>% mutate(fp_married = case_when(v502==1  ~ "married"))

# set expss package options to show one decimal place
expss_digits(digits=1)

tab<-  IRdata %>% 
  cross_cpct(
    cell_vars = list(modfp,v025),
    col_vars = list(fp_married),
    weight = wt,
    expss_digits(digits=1)) 

write.xlsx(tab, "tables.xlsx", sheetName = "table1")
# note that this table gives you weighted percentages but does not produce confidence intervals. 


# Crosstabulation of modfp (modern FP use) and place of residence (v025)
svyby(~modfp, by = ~v025, design=mysurvey, FUN=svymean, vartype=c("se", "ci"))

# chi-square results
svychisq(~modfp+v025, mysurvey)


# To do this for several variables at once, you can do the following

# List of variables to crosstabulate with your outcome
variables <- c("v013","v106", "v190","v025","v024") 

results <- list()  # Empty list to store the crosstabulation results

# Loop through the variables
for (var in variables) {
  # Crosstabulation using svyby
  crosstab <- svyby(~ modfp, by = as.formula(paste("~", var)), design = mysurvey, FUN = svymean, vartype = c("se", "ci"))
  
  chi_square <- svychisq(as.formula(paste("~ modfp +", var)), design = mysurvey)
  
  # Store results in list
  results[[var]] <- list(crosstab = crosstab, chi_square = chi_square)
}

# Access the crosstabulation results for each variable
for (var in variables) {
  print(paste("Crosstabulation for", var))
  print(results[[var]])
}

