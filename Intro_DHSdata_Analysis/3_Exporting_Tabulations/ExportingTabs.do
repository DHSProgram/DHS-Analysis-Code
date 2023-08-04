/******************************************************************************
	Purpose: Exporting tabulations to excel
	Data input: The model dataset women's file (IR file)
	Author: Shireen Assaf
	Date Last Modified: Aug 4, 2023 by Shireen Assaf to add dtable option for Stata 18 users

Notes/Instructions:

* Please have the model dataset downloaded and ready to use. We will use the IR file.
* You can download the model dataset here: https://www.dhsprogram.com/data/Model-Datasets.cfm
* For the code below to work, you must save the dataset in the same folder as the Stata do file. 
* We use the svy command after setting the survey design. Please check the SvyCommmandDHS.do file for more details. 
* The excel files produced here will be saved in your working directory or you can change your working directory with the "cd" command
******************************************************************************/

clear all
use ZZIR62FL.dta, clear

numlabel, add

* generate a weight variable
gen wt=v005/1000000

* setting the survey design
svyset [pw=wt], psu(v021) strata(v022) singleunit(centered)

* create modern contraceptive use indicator if not already produced
recode v313 (0/2=0 no) (3=1 yes), gen(modfp)
label var modfp "currently use a modern method"

*** Using tabout command ***

* install tabout program if it is not installed already
ssc install tabout

**** One way tabulation (tabulate one variable at a time) ****

* note the use of "oneway" since this is a one way tabulations
* the svy command and wt are also included
tabout v106 v025 v024 using table1.xls, c(cell) oneway svy nwt(wt) per pop replace

* If you have Stata 18, you can also use the dtable command for one way tabulations.
* See below for exmaple code that would give the same output as the oneway tabout above.
dtable i.v106 i.v025 i.v024, svy nformat(%9.1f mean) nosample column(summary(N / %)) title(Table 1) export(table1b.docx)

* you can also export as an excel file by using export(Table.xlsx) in dtable code above

* In both the tabout and dtable oneway tabulations above, you don't need to use svy and can just apply weights using [iw=wt] since you are not reporting SE or confidence intervals. However, using svy will also be correct. 


**** Two-way tabulation: tabulate one variable with the outcome one at a time ****

* example: tabulate modern contraceptive methhod use by education, residence, and region
* the last variale on the list should be the outcome variable 
* note that we use c(row ci) to indicate we want row percentages and the confidence interval
* there is also the stats(chi2) option to produce the chi-square test results
tabout v106 v025 v024 modfp using table2.xls if v502==1, c(row ci) stats(chi2) svy nwt(wt) per pop replace 

******************************************************************************

*** Using putexcel command ***

* using tabout can require a lot of copy and pasting to produce a table for a report or paper.
* using putexcel can help produce a table that is closer to what would appear as a final table.
* the code below describes how putexcel can be used for creating a crosstabulation of one indicator with several background variables. 
* the code uses a loop command foreach that loops through each variable.
* scalars are then stored and exported to excel 

* to get the total as well as the crosstabulation, create a tot variable
gen tot=1
label var tot "Total"

* begin a temporary results file with putexcel set
putexcel set "results_temp.xlsx", modify sheet("crosstab")

*add the column labels
putexcel A1=("Table: Crosstabulation of modern contraceptive by background variables") A3=("Variable") B3=("% [C.I.]") C3=("p-value") 	

* set the local row where your first estimate will be stored
local row  =5
* this is a seperate local for the p-values that will be produced
local prow =4

*add all the background variables you want to have in your two-way tabulation. We also add tot for the total. 
foreach y in tot v106 v025 v024 {
	levelsof `y', local(`y'lv)
			foreach x of local `y'lv {
			estpost svy: ta modfp if `y'==`x' 
			
			mat mat1=e(b)
			mat mat2=e(lb)
			mat mat3=e(ub)
			mat mat4=e(obs)
			
			*e(count) would give the weighted denominator if needed. 
			*e(obs) gives unweighed which is needed to check for low observations and determine if an estiamte should not be displaced. 
			*mat mat5=e(count)

			scalar `y'`x'p= round(mat1[1,2]*100,0.1)
			scalar `y'`x'p_str = string(`y'`x'p)

			* this would give the total number in your category, i.e. the denominator
			scalar `y'`x'N= round(mat4[1,3],1)

			** to export the C.I. in the format [2.1, 2.5] **
			scalar `y'`x'lb= round(mat2[1,2]*100,0.1)
			scalar `y'`x'ub= round(mat3[1,2]*100,0.1)
			scalar `y'`x'lb_str = string(`y'`x'lb)
			scalar `y'`x'ub_str = string(`y'`x'ub)

				* adding 0 infront of decimal place if less than one
				if `y'`x'lb <1 {
				scalar `y'`x'lb_str="0"+`y'`x'lb_str
				}
				if `y'`x'ub <1 {
				scalar `y'`x'ub_str="0"+`y'`x'ub_str
				}

				* adding .0 after number if it rounded to zero decimal places
				if `y'`x'p == int(`y'`x'p) {
				scalar `y'`x'p_str =`y'`x'p_str + ".0"
				}
				if `y'`x'lb == int(`y'`x'lb) {
				scalar `y'`x'lb_str =`y'`x'lb_str + ".0"
				}
				if `y'`x'ub == int(`y'`x'ub) {
				scalar `y'`x'ub_str =`y'`x'ub_str + ".0"
				}

			* now combining with the % estimate in the format % [lb, ub]
			scalar `y'`x'pCI=`y'`x'p_str + " " + "[" + `y'`x'lb_str + "," + `y'`x'ub_str + "]"

			* ND or not displayed if less than 25 unweighted cases
			if `y'`x'N<25{
			scalar `y'`x'pCI="ND"
			}
			
			* rates in parenthesis based on 25-49 unweighted cases
			if  `y'`x'N>=25 &  `y'`x'N<50 {
			scalar q`x'pCI`i'="("+ `y'`x'p_str + ")" + " " + "[" + `y'`x'lb_str + "," + `y'`x'ub_str + "]"
			}
			
			****
			* to get the chi2 p-value
				svy: ta `y' modfp, row
				scalar `y'pvalue=round(e(p_Pear),0.001)
				
				if `y'pvalue<0.05 {
				scalar `y'pv ="*"
				}
				if `y'pvalue<0.01 {
				scalar `y'pv ="**"
				}
				if `y'pvalue<0.001 {
				scalar `y'pv ="***"
				}
				
				if `y'pvalue>=0.05 {
				scalar `y'pv=""
				}
	
		* to get the variable label
		local l`y': var label `y'
		scalar labs`y'=proper("`l`y''")

		* to get category labels
		local laby = upper("`y'")
		local lablev: label `laby' `x'
		scalar labsx=proper("`lablev'")
		
			*export the scalars for each category
			putexcel A`prow'=(labs`y') A`row'=(labsx) B`row'=(`y'`x'pCI) C`prow'=(`y'pv) 		
			
			local row = `row' + 1  				
			}			
	
	local row = `row' + 2  
	local prow = `row' -1
	}  
  
******************************************************************************
