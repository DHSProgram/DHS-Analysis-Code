#####################################################################################
# Purpose: Fitting a logistic regression using a binary outcome from DHS data
# Data input: The model dataset women's file (IR file)
# Author: Shireen Assaf
# Date Last Modified: May 23, 2023 by Shireen Assaf
# 
# Notes/Instructions:
# 
# Please have the model dataset downloaded and ready to use. We will use the IR file.
# You can download the model dataset here: https://www.dhsprogram.com/data/Model-Datasets.cfm
# To run this script you should save the dataset in the same folder as your R scripts.
# In this example, we will use the indicator of modern contraceptive use.
# This indicator was also coded in the previous R scripts in this repository. 
# We will also apply the svyset and svy commands we have seen in the previous section. 
# This example only shows a simple logistic model for a binary outcome. 
# the svyglm command used also supports other types of regressions that are part of the generalized linear models
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

here()

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

### logistic regression ###

# Generalized linear models 
? svyglm

# unadjusted with place of residence 
reg1 <- svyglm(modfp~ 1+ v025 , design=mysurvey, family=binomial(link="logit"))

# to see the results
summary(reg1)

# to get ORs
ORreg1 <- exp(reg1$coefficients )
ORreg1

# multivariate models with place of residence (v025), education (v106), and current age (v013)
reg2 <- svyglm(modfp~ 1+ v025 + as.factor(v106) + as.factor(v013), design=mysurvey, family=binomial(link="logit"))

summary(reg2)

# checking for correlations

# create a subset of data with variables you want to check

cordata <- subset(IRdata, select=c(v025, v106, v013 ,v190))

mycordata <- cor(cordata)
# we see that v025 and v190 may be highly correlated

# to produce a correlation plot
install.packages("corrplot")
library(corrplot)

corrplot(mycordata)

