/****************************************************************************
File name: !Norms_main.do									
Purpose: Set up files and paths for Norms study				
Author: Shireen Assaf											
Created: 10/20/2021												
Modified: 10/20/2021														
****************************************************************************/

* IR Files
global irdata "NGIR7BFL NPIR7HFL ZMIR71FL"

* MR Files
global mrdata "NGMR7AFL NPMR7HFL ZMMR71FL"

***************************************************************************
*CHANGE user ID to run
*global user 33697
global user 53348

*File path for Do files
global Dofilepath "C:\Users\\$user\ICF\Analysis - Norms and FP documents\Analysis"

*File path for Data files 
global Datafilepath "C:/Users/$user/ICF/Analysis - Shared Resources/Data/DHSdata"

*File path for Coded data files
global Codedfilepath "C:\Users\\$user\ICF\Analysis - Norms and FP documents\Data"

*File path for Results files
global Resultsfilepath "C:\Users\\$user\ICF\Analysis - Norms and FP documents\Results"

*File path for Figure files
global Figuresfilepath "C:\Users\\$user\ICF\Analysis - Norms and FP documents\Results\Figures"
*****************************************************************************
set more off


*******************************************************************************
/*NOTE: Need hotdeck and labvalch3 commands installed to run this do file.
cd "$Dofilepath"
*Purpose: Code variables
do "codevars.do" 
*/
********************************************************************************
/*
cd "$Dofilepath"
*Purpose: Tables
do "NormsDescTables.do"
*/
********************************************************************************
/*
cd "$Dofilepath"
*Purpose: Test multicollinearity, single level models, MLMs with only sampling weights.
do "PrelimRegs.do"
*/
********************************************************************************
/*
cd "$Dofilepath"
*Purpose: Code for multilevel models
do "MLM.do"  
*/

********************************************************************************
/*
cd "$Dofilepath"
*Purpose: Code for multilevel models
do "RegionalMLM.do"  
*/