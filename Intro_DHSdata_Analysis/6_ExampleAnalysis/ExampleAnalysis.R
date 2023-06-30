#####################################################################################
#   Purpose: Illustrating an example of an analysis to answer a research question from start to finish
#   Data input: The model dataset women's file (IR file)
#   Author: Shireen Assaf
# 	Date Last Modified: June 30, 2023 by Shireen Assaf
# 
# Notes/Instructions:
# 
# * Please have the model dataset downloaded and ready to use. We will use the IR file.
# * You can download the model dataset here: https://www.dhsprogram.com/data/Model-Datasets.cfm
# * For the code below to work, you must save the dataset in the same folder as the Stata do file. 
# * In this example, we will answer a specific research question and show how to produce the results including descriptive, crosstabs, and regression results. 
# * We will use code that was illustrated in the previous sections, i.e. 1-Recoding, 2-SurveyDesign, 3-Exporting_Tabulations, and 5-Regression.
# * We will not to use merging or appending for this example so the code from section 4, using multiple files, will not be used. 
# 
# * Research question: 
#   Does modern contraceptive use among women currently in a union differ by family planning media exposure after controlling for socio-demographic variables
# 
# !!!! Please follow the notes throughout the do file
#####################################################################################

# install and load the packages you need. You only need to install packages once.
# If the packages were installed already from the RecodingDHSVars.R file then no need to install again.
# After installing a package you can load the package using the library command.
install.packages("haven") # used to open dataset with read_dta
install.packages("here") # used for path of your project. Save your datafile in this folder path.
install.packages("dplyr") # used for creating new variables
install.packages("labelled") # used for haven labelled variable creation
install.packages("survey") # used to set survey design
install.packages("expss") # for creating tables with Haven labelled data
install.packages("xlsx") # used to export tables to excel

library(haven)
library(here)
library(dplyr)
library(labelled) 
library(survey)
library(expss)    
library(xlsx)

here()

##################################################################################

# Preparing your data. Need to code variables and select for currently married women.
# will produce a subset of the data called mydata.

# open your original dataset
IRdata <-  read_dta(here("Intro_DHSdata_Analysis","ZZIR62FL.dta"))

##############################
### Recode variables ###
##############################
  
### Outcome variable ### 
  
  # Modern contraceptive use
  IRdata <- IRdata %>%
  mutate(modfp =
           case_when(v313 == 3 & v502==1 ~ 1,
                     v313 < 3  & v502==1 ~ 0 ,
                     v502 !=1 ~ NA_integer_)) %>%
  set_value_labels(modfp = c(yes = 1, no = 0)) %>%
  set_variable_labels(modfp ="Currently used any modern method")
# in the above code we use NA_integer_ to replace as missing any values where women are not currently in a union

### Socio-demographic variables ###

# age: use v013

# education: recode v106 to combine secondary and higher categories
  IRdata <- IRdata %>%
    mutate(edu =
             case_when(v106 ==0 ~ 0,
                       v106 ==1 ~ 1,
                       v106 >=2 ~ 2)) %>%
    set_value_labels(edu = c(none = 0, primary = 1, "sec+" = 2)) %>%
    set_variable_labels(edu ="education level")
  
# wealth quintile: use v190

# place of residence: use v025

# region: use v024

### Family planning (FP) messages exposure ###

# Heard a family planning message from radio, TV or paper
  
  # Did not hear a family planning message from radio, TV or paper
  IRdata <- IRdata %>%
    mutate(fpmessage =
             ifelse(v384a==1 | v384b==1 | v384c==1, 1, 0)) %>%
    set_value_labels(fpmessage = c(yes = 1, no = 0)) %>%
    set_variable_labels(fpmessage = "Exposed to TV, radio, or paper media sources")  
  
# !! For all variables, replace as missing if woman is not currently in a union, and reduce your dataset to mydata
  
vars <- c("modfp","v013","edu","fpmessage","v502", "v190","v025","v024","v005", "v007", "wt","v021","v022","v001","v002","v003")

mydata <- IRdata %>%
  filter(v502 == 1) %>%
  select(all_of(vars))


##############################################
### Set the survey design using svydesign ###
##############################################

# attaching data 
attach(mydata)

# creating the sampling weight variable. 
IRdata$wt <- IRdata$v005/1000000

### Setting the survey design using the svydesign command from the survey package ###
# the survey design will be saved in an object named mysurvey, you can change this name to another name
mysurvey<-svydesign(id=mydata$v021, data=mydata, strata=mydata$v022,  weight=mydata$wt, nest=T)
options(survey.lonely.psu="adjust") 
  
####################################################
### Descriptive Statistics and Crosstabulations ### 
###################################################

#### Descriptive table ####
# this table will include all the variables in your analysis (would be your Table 1 of your results)
# The variables are tabulated among women currently in a union since this is our analytical sample

# you can use the following code for checking the proportions of a variable
prop.table(svytable(~modfp, mysurvey))

# to export a table of the weighted percentages of all your variables you can use the following code

# dummy var for all women currently in a union
mydata <- mydata %>% mutate(fp_all = case_when(v007>0  ~ "all"))

# set expss package options to show one decimal place
expss_digits(digits=1)

tab<-  mydata %>% 
  cross_cpct(
    cell_vars = list(modfp,v013,edu,fpmessage,v190,v025,v024),
    col_vars = list(fp_all),
    weight = wt,
    expss_digits(digits=1)) 

write.xlsx(tab, "Intro_DHSdata_Analysis/6_ExampleAnalysis/tables.xlsx", sheetName = "table1")
# note that this table gives you weighted percentages but does not produce confidence intervals. 

##### Crosstabulations of each variable with the outcome variables (Table 2 of your results) #####

# Crosstabulation of modfp (modern FP use) and place of residence (v025)
svyby(~modfp, by = ~v025 , design=mysurvey, FUN=svymean, vartype=c("se", "ci"))

# chi-square results
svychisq(~modfp+v025, mysurvey)


# To do this for several variables at once, you can do the following

# List of variables to crosstabulate with the outcome
variables <- c("v013","edu","fpmessage", "v190","v025","v024") 

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


# Interpretation:
# The results of the crosstabulation show that all variables were significantly associated with modern contraceptive use

# To produce a table of just the percentages by modfp (i.e. no C.I.s)
tab<-  mydata %>% 
  cross_rpct(
    cell_vars = list( v013,edu,fpmessage,v190,v025,v024,total()),
    col_vars = list(modfp),
    weight = wt,
    expss_digits(digits=1)) 
write.xlsx(tab, "Intro_DHSdata_Analysis/6_ExampleAnalysis/tables.xlsx", sheetName = "table2", append=TRUE)

############################################################################################

# ******************************
# *** Logistic Regressions *** 
# ******************************
# We will use the svyglm function from the survey package to fit regression models.
# This fits generalized linear models
? svyglm

# first check for correlations 
cordata <- mydata[, variables]
# Calculate the correlation matrix
cor_matrix <- cor(cordata)
print(cor_matrix)

# to produce a correlation plot
install.packages("corrplot")
library(corrplot)

corrplot(cor_matrix)
# there is a relatively high correlation between v025 and v190 that the researcher may need to be cautious of


#### Unadjusted regression ####
# first we will fit an unadjusted logistic regression for family planning message exposure
# 

# unadjusted with exposure to family planning messages. Ignore the warning message!
reg1 <- svyglm(modfp~ 1 + fpmessage , design=mysurvey, family=binomial(link="logit"))

# to see the results
summary(reg1)

# to get ORs
ORreg1 <- exp(reg1$coefficients )
ORreg1

# Interpretation:
# The unadjusted result shows that women currently in a union who have heard a FP message through one of the three media sources 
# have almost twice the odds of using modern a contraceptive method compared to women with no FP message exposure


####  Adjusted regression #### 

# now we will include all the background variables with our main variable of interest
# note that for binary variables, you do not need to use as.factor but for categorial variables, 
# you should add as.factor(var) to indicate that the variable is categorical and not continuous. 
reg2 <- svyglm(modfp~ 1 + fpmessage + as.factor(edu) + as.factor(v013) 
               + as.factor(v190) + as.factor(v024) + as.factor(v024), 
               design=mysurvey, family=binomial(link="logit"))


# to see the results
summary(reg2)

# to get ORs
ORreg2 <- exp(reg2$coefficients )
ORreg2

# Interpretation:
# After controlling for other variables, exposure to FP messages was found to be significantly associated with modern contraceptive use
# among women currently in a union. Women with FP message exposure had 1.5 times higher odds compared to women with no exposure in using 
# modern contraceptive methods. 

