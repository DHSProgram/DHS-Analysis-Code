#####################################################################################
# Purpose: Recoding or creating new variables.
# Data input: The model dataset women's file (IR file)
# Author: Shireen Assaf
# Date Last Modified: Jan 26, 2023 by Shireen Assaf
# 

# Notes/instructions:
# Please have the model dataset downloaded and ready to use. We will use the IR file.
# You can download the model dataset here: https://www.dhsprogram.com/data/Model-Datasets.cfm
# For the code below to work, you must save the dataset in the same folder as your R scripts. 
# For this and other examples, you can check your work using the model dataset tables.
# This do file will show simple examples for creating new variables and how you can check them with the final report tables.
# For a more comprehensive code for creating DHS indicators, please visit the DHS Program code share library on Github: https://github.com/DHSProgram/DHS-Indicators-R
# You can download the repository or copy the code for the indicators you are interested in. 

#####################################################################################

# install and load the packages you need. You only need to install packages once.
# After installing a package you can load the package using the library command
install.packages("haven") # used to open dataset with read_dta
install.packages("here") # used for path of your project. Save your datafile in this folder path.
install.packages("dplyr") # used for creating new variables
install.packages("labelled") # used for haven labelled variable creation
install.packages("pollster") # used to produce weighted estimates with topline command
library(naniar)   # to use replace_with_na function
library(haven)
library(here)
library(dplyr)
library(labelled) 
library(naniar)
library(pollster)

here() # check your path

# open your dataset
IRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZIR62FL.dta"))

# Example 1
### recode current modern contraceptive use into a binary variable ###

# check category labels
print_labels(IRdata$v313)

# option 1: creating a new categorical variable using mutate and ifelse commands

IRdata <- IRdata %>%
  mutate(modfp = 
           ifelse(v313 == 3, 1, 0)) %>%   
  set_value_labels(modfp = c(yes = 1, no = 0)) %>%
  set_variable_labels(modfp ="Currently used any modern method")

# option 2: creating a new categorical variable using mutate and case_when commands

IRdata <- IRdata %>%
  mutate(modfp =
           case_when(v313 == 3 ~ 1,
                     v313 < 3 ~ 0 )) %>%
  set_value_labels(modfp = c(yes = 1, no = 0)) %>%
  set_variable_labels(modfp ="Currently used any modern method")

# creating the sampling weight variable. 
IRdata$wt <- IRdata$v005/1000000

# check with final report Table 7.3
topline(IRdata, modfp, wt )

########################################################

# Example 2
### Number of ANC visits in 4 categories that match the table in the final report


# age of child needed for this indicator. 
# If b19_01 is not available in the data use v008 - b3_01
  # IRdata <- IRdata %>%
  #   mutate(age = b19_01)
  IRdata <- IRdata %>%
    mutate(age = v008 - b3_01)


IRdata <- IRdata %>%
  mutate(ancvisits =
           case_when(
             m14_1 == 0 ~ 0 ,
             m14_1 == 1 ~ 1 ,
             m14_1  %in% c(2,3)   ~ 2 ,
             m14_1>=4 & m14_1<=90  ~ 3 ,
             m14_1>90  ~ 9 ,
             age>=60 ~ 99 )) %>%
  replace_with_na(replace = list(ancvisits = c(99))) %>%
  set_value_labels(ancvisits = c(none = 0, "1" = 1, "2-3"=2, "4+"=3, "don't know/missing"=9  )) %>%
  set_variable_labels(ancvisits = "Number of ANC visits")

# check with final report Table 9.2
topline(IRdata, ancvisits, wt )
