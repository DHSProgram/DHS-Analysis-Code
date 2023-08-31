
# Readme AS 88: Birth Intervals and Child Mortality Study

This code is used to produce analysis for the [DHS Analytical Study #88: The Effect of Fertility Behavior on Child Survival: Evidence from the Demographic and Health Surveys, 2012–2022](add link when ready). The study examines mortality risks associated with short birth to conception intervals, maternal age at birth, and birth order. 


## Files:

###	SurveyList.xlsx
o	This file contains information on all publicly available DHS datasets- each row is a different survey.  It contains the country name, year(s) of the survey, and names of each recode file. 

###	Surveys_Birth_Spacing_Reports.csv
o	This file contains the same surveys as SurveyList.xlsx with an added column noting if the files were included in older DHS analysis of child mortality or if they are included in the current study.

###	Calendar_Data.csv
o	This file is created by the R file "Calendar_Analysis.R"

o	For each survey in WP41, AS37, and AS88, it reports if there is a calendar in the survey

###	Calendar_Analysis.R
o	This code first opens each IR file and determines if there is a calendar (data is present in both vcal_1 and v017

o	The second section of analysis opens each IR file, reshapes the calendar data, and then determines for each birth the length of gestation, the outcome of the previous pregnancy, and if the birth was the results of a contraceptive failure

o	The results are saved as new files for each survey in a folder for analysis in Infant_Mortality_Tables.R

###	Infant_Mortality_Tables.R
o	This is the main file of analysis for the report.  It loads all three spreadsheets discussed above.  It then recodes variables for all surveys and creates a pooled dataset  and recodes its variables.  It creates summary statistics for all surveys and the pooled dataset, as well as bivariate and multivariable Cox hazard models for the pooled dataset.  It creates and exports results tables.  