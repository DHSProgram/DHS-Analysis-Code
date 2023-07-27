## Introduction to DHS Data Analysis

This project provides the basic steps to begin your DHS data analysis using Stata and when available in R. This repository will not contain code in SPSS.

Contributions to this repository are welcome.

The program files cover the following main topics: 
1) Recoding, 
2) Survey design, 
3) Exporting tabulations, 
4) Using multiple files, 
5) Regressions, 
6) Example Analysis
7) Special or advanced topics.

The code will use the [DHS Model Datasets](https://www.dhsprogram.com/data/Model-Datasets.cfm) when possible.  
DHS data for your survey of interest can be downloaded from the [available datasets](https://www.dhsprogram.com/data/available-datasets.cfm) on the DHS website.

It is also recommended to take the DHS Dataset Users course on the [DHS Learning hub](https://learning.dhsprogram.com/) which is an open course. 
This course will provide more instruction, background on the DHS Program and DHS design, visual aids, and step by step instructions of the Stata do files do files similar to what you will see here. 

You may also check the DHS Program website page for [Using Datasets for Analysis](https://www.dhsprogram.com/data/Using-Datasets-for-Analysis.cfm).
This page will describe the basic steps to begin your data analysis using DHS data. 

## Recoding 
The recoding program will show the simple steps for the recoding or creating new variables.

For a much more comprehensive library of code for DHS indicators, visit our [Code Share library](https://github.com/DHSProgram) indicator repositories to copy code for all DHS indicators listed in the [Guide to DHS Statistics](https://www.dhsprogram.com/Data/Guide-to-DHS-Statistics/index.cfm).
This covers indicators related to family planning, maternal and child health, nutrition, malaria, and more. Code is available in Stata, SPSS, and R. 

[DHS-Indicators-Stata](https://github.com/DHSProgram/DHS-Indicators-Stata) repository
[DHS-Indicators-R](https://github.com/DHSProgram/DHS-Indicators-R) repository
[DHS-Indicators-SPSS](https://github.com/DHSProgram/DHS-Indicators-SPSS) repository.

Please check the indicator list found in each respository to find the DHS indicator of interest

## Survey design
The svycommands program will show how to set the survey design for your analysis. This is required for any analysis of DHS data where the standard error is produced (i.e. for confidence intervals, hypothesis testing, etc.).
For this do file you will need a strata variable. 
In recent DHS surveys, the strata variable is v022, hv022, mv002.  If you are not using a recent DHS survey, please check the Survey_strata.do file which will compute the strata variable for any DHS survey.  
The Survey_strata.do file does not check the strata for MIS, AIS, and interim surveys. For these surveys please refer to the final report to check what stratification was used. 

## Exporting tabulations
This program will show how to tabulate and export your results. 

For Stata, the program will demonstrate examples using the tabout command and the putexcel commands. 
For R, the openxlsx package will be used. 

## Using multiple files

If you are interested in combining several files from the same survey then you would use the merge code provided in this section. Not all possible merge combinations are available but the most common types of merge. 
You may also need to append two or more surveys from the country for a trend analysis, or pool data from different countries for a multi-country analysis. 

Check the readme file of this section for more details.

## Regression
The regression program demonstrates how to perform a logistic regression with DHS data and applying the survey design. 

## Example Analysis
This program will show an example of an analysis to answer a research question from start to finish. This uses code from the previous sections: Recoding, Survey design, Exporting tabulations to excel, and Regression. 

## Special or advanced topics
This folder contains several useful programs for advanced analysis of DHS data. This includes: multilevel weights, survival analysis, coding of special indicators, and more to come.  



##### author: Shireen Assaf
##### last updated: July 26, 2023 by Shireen Assaf