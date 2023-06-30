/******************************************************************************
	Purpose: Illustrating an example of an analysis to answer a research question from start to finish
	Data input: The model dataset women's file (IR file)
	Date Last Modified: June 30, 2023 by Shireen Assaf

Notes/Instructions:

* Please have the model dataset downloaded and ready to use. We will use the IR file.
* You can download the model dataset here: https://www.dhsprogram.com/data/Model-Datasets.cfm
* For the code below to work, you must save the dataset in the same folder as the Stata do file. 
* In this example, we will answer a specific research question and show how to produce the results including descriptive, crosstabs, and regression results. 
* We will use code that was illustrated in the previous sections, i.e. 1-Recoding, 2-SurveyDesign, 3-Exporting_Tabulations, and 5-Regression.
* We will not to use merging or appending for this example so the code from section 4, using multiple files, will not be used. 

* Research question: 
  Does modern contraceptive use among women currently in a union differ by family planning media exposure after controlling for socio-demographic variables

* !!! Please follow the notes throughout the do file
******************************************************************************/

cd "C:\Users\33697\ICF\Analysis - Shared Resources\Code\DHS-Analysis-Code\Intro_DHSdata_Analysis"

* Open the IR file 
clear all
use ZZIR62FL.dta, clear

****************************
*** Recode variables ***
****************************

*** Outcome variable ***
* modern contraceptive use among women currently in a union
recode v313 (3=1 Yes) (else=0 No) if v502==1, gen(modfp)
label variable modfp "modern contraceptive use"

*** Socio-demographic variables ***

* age: use v013

* education: recode v106 to combine secondary and higher categories
recode v106 (0=0 None) (1=1 Primary) (2/3=2 "Sec+"), gen(edu)

* wealth quintile: use v190

* place of residence: use v025

* region: use v024

*** Family planning (FP) messages exposure ***

//Heard a family planning message from radio, TV or paper
gen fpmessage=0
replace fpmessage =1 if (v384a==1 | v384b==1 | v384c==1)
label define yesno 1 Yes 0 No
label values fpmessage yesno 
label var fpmessage "Exposed to FP message from TV, radio, or paper media sources"

*check your variables among women currently in a union
*unweighted
tab1 modfp v013 edu v190 v025 v024 fpmessage if v502==1

*weighted
tab1 modfp v013 edu v190 v025 v024 fpmessage if v502==1 [iw=wt]

*******************************************
*** Set the survey design using svyset ***
*******************************************

gen wt= v005/1000000
svyset [pw=wt], psu(v021) strata(v022) singleunit(centered)

***********************************************
*** Descriptive Statistics and Crosstabulations  
***********************************************

*install tabout if you have not already
* ssc install tabout

* check your variables
tab1  modfp v013 edu v190 v025 v024 fpmessage if v502==1 [iw=wt]

* Descriptive table: this table will include all the variables in your analysis (would be your Table 1 of your results)
* The variables are tabulated among women currently in a union since this is our analytical sample
tabout modfp v013 edu v190 v025 v024 fpmessage if v502==1 using table1.xls, c(cell) oneway svy nwt(wt) per pop replace

* Crosstabulations of each variable with the outcome variables (Table 2 of your results)
* Since the outcome is already coded only among women currently in a union, 
* there is no need to select for these women using v502==1 as we have done in the oneway tabout. 
* the output will also perform the chi-square test and produce the p-value since we added the stats(chi2) option
tabout v013 edu v190 v025 v024 fpmessage modfp using table2.xls, c(row ci) stats(chi2) svy nwt(wt) per pop replace 

* Interpretation:
* The results of the crosstabulation show that all variables were significantly associated with modern contraceptive use

******************************
*** Logistic Regression *** 
******************************

* check for correlations 
pwcorr v013 edu v190 v025 v024 fpmessage if v502==1
* there is a relatively high correlation between v025 and v190 that the researcher may need to be cautious of

*install outreg2 if you have not already
*ssc install outreg2

*** Unadjusted regression ***
* we will fit an unadjusted logistic regression for family planning message exposure

svy: logistic modfp i.fpmessage 
* Interpretation:
* The unadjusted result shows that women currently in a union who have heard a FP message through one of the three media sources 
* have almost twice the odds of using modern a contraceptive method compared to women with no FP message exposure

* we export this result to excel using outreg2 command. This would be Table 3 of your results.
outreg2 using table3.xls, eform stats(coef ci) sideway dec(1) label(insert) alpha(0.001, 0.01, 0.05) replace


*** Adjusted regression ***
* now we will include all the background variables with our main variable of interest
svy: logistic modfp i.fpmessage i.v013 i.edu i.v190 i.v025 i.v024

* we export this result to excel using outreg2 command and append it to the unadjusted results
outreg2 using table3.xls, eform stats(coef ci) sideway dec(1) label(insert) alpha(0.001, 0.01, 0.05) append

* Interpretation:
* After controlling for other variables, exposure to FP messages was found to be significantly associated with modern contraceptive use
* among women currently in a union. Women with FP message exposure had 1.5 times higher odds compared to women with no exposure in using 
* modern contraceptive methods. 

