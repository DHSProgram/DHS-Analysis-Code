# *******************************************************************************************************************************
# Program: 				HouseholdStucture.R
# Purpose: 				Construct household structure variable
# Author: 				Tom Pullum and translated to R by Shireen Assaf
# Date last modified:		July 25, 2023 by Shireen Assaf
# *******************************************************************************************************************************

library(naniar)   # to use replace_with_na function
library(haven)
library(here)
library(dplyr)
library(labelled) 
library(pollster)

here() # check your path

# open your PR dataset, model dataset used here
PRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZPR62FL.dta"))

# Criteria for household typology
# household head is male (hv101=1, hv104=1)
# household head is female (hv101=1, hv104=2)
# no spouse present (no one in hh with hv101=2)
# at least one unmarried child present (hv101=3,hv105<=17, hv115=0 | is.na(hv115))

PRdata <- PRdata %>%
  mutate(hhhead_male = ifelse(hv101==1 & hv104==1, 1, 0)) %>%   
  mutate(hhhead_female = ifelse(hv101==1 & hv104==2, 1, 0)) %>%   
  mutate(spouse = ifelse(hv101==2, 1, 0)) %>%   
  mutate(child = ifelse(hv101==3 & hv105<=17 & (hv115==0 | is.na(hv115)), 1, 0))   
  

PRdata <- PRdata %>%
  group_by(hv024, hv001, hv002) %>%
  mutate(nhhhead_male = sum(hhhead_male)) %>%
  mutate(nhhhead_female = sum(hhhead_female)) %>%
  mutate(nspouse = sum(spouse)) %>%
  mutate(nchild = sum(child)) 
  

PRdata <- PRdata %>%
  mutate(hhtype =
           case_when(
             nhhhead_male==1   & nspouse>=1 & nchild >0 ~ 1 ,
             nhhhead_male==1   & nspouse>=1 & nchild==0 ~ 2 ,
             nhhhead_male==1   & nspouse==0 & nchild >0 ~ 3 ,
             nhhhead_male==1   & nspouse==0 & nchild==0 ~ 4 ,
             nhhhead_female==1 & nspouse>=1 & nchild >0 ~ 5 ,
             nhhhead_female==1 & nspouse>=1 & nchild==0 ~ 6 ,
             nhhhead_female==1 & nspouse==0 & nchild >0 ~ 7 ,
             nhhhead_female==1 & nspouse==0 & nchild==0 ~ 8 ,
             is.na(hhtype) ~ 9)) %>%
  set_value_labels(hhtype = c("Male head with spouse and children" = 1, "Male head with spouse, no children"=2, 
                              "Male head, no spouse, and children"=3, "Male head, no spouse, no children"=4 ,
                              "Female head with spouse and children"=5, "Female head with spouse, no children"=6, 
                              "Female head, no spouse, and children"=7 , "Female head, no spouse, no children"=8, "Other"=9)) %>%
  set_variable_labels(hhtype = "Household structure")


# to check unweighted percentages
prop.table(table(PRdata$hhtype))*100


