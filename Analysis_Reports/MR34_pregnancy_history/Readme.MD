
# Readme MR34: Methodological Report on Pregnancy History Model Analysis

## Description
In DHS-8, the DHS Program has switched from using a birth history to a pregnancy history. 
This resulted in the creation of two new data files: 
1. the GR file which contains information on all pregnancies of interviewed women
2. the NR file which contains information on pregnancies of interviewed women in the last three years.

For both these files the unit of analysis in the pregnancy and new variables related to the pregnancy are included that start with the letter p. 

For more information and details please refer to the [DHS Methodological Report #34: Pregnancy History Model Analysis Plan: Determinants of Stillbirth](https://dhsprogram.com/publications/publication-mr34-methodological-reports.cfm?cssearch=1093723_1).

The two do files below show how to perform a model analysis of the determinants of stillbirth using each of these files using the four DHS-8 surveys available as of August 2023.


## GR_stillbirth
This uses the GR file on all pregnancies of interviewed women. The code is used to calculate the main outcome which is stillbirth and several covariates as well as pregnancy related variables. The code will also show a model analysis of stillbirth using bivariate analysis and multivariate logistic regression. 

## NR_stillbirth
The uses the NR file for pregnancies in the last three years. Most of the code is similar to the GR_stillbirth.do file but in the NR file there are health related variables (such as information on ANC and delivery) that is not found in the GR file. The same analysis used in the GR_stillbirth.do file is used here with bivariate and multivariate logistic models. 
