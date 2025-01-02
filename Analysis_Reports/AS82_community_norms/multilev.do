
/*****************************************************************************************************
Program: 			multilev.do
Purpose: 			define multilevel weights for each survey using code from MR27
Data inputs:		coded IR/MR files for Nigeria, Nepal, and Zambia. Must run codevars.do first.
Author:				Shireen Assaf 	
Date last modified: Nov 17, 2021 by Shireen Assaf 
Note:				Used the multilevel.xlsx file to copy numbers from final reports (Apdx A) and produce code 				
*****************************************************************************************************/

*Nigeria survey
foreach c in IR MR {
	
use	"$Codedfilepath/NG`c'coded.dta", clear

* to make code work for MR file
cap gen v022=mv022
cap gen v021=mv021
cap gen v005=mv005

**********************************************************************
* Stage A *** Compile parameters/inputs for Level-weights calculations
**********************************************************************
* a_c_h completed clusters by strata
gen a_c_h=.
quietly levelsof v022, local(lstrata)
quietly foreach ls of local lstrata {
tab v021 if v022==`ls', matrow(T)
scalar stemp=rowsof(T)
replace a_c_h=stemp if v022==`ls'
}
* A_h total number of census clusters by strata
gen A_h = 0
*Urban
replace A_h = 2452  if v022 == 3
replace A_h = 2006  if v022 == 1
replace A_h = 5492  if v022 == 5
replace A_h = 11715  if v022 == 7
replace A_h = 2008  if v022 == 9
replace A_h = 5126  if v022 == 11
replace A_h = 3949  if v022 == 13
replace A_h = 2820  if v022 == 15
replace A_h = 2761  if v022 == 17
replace A_h = 7798  if v022 == 19
replace A_h = 1955  if v022 == 21
replace A_h = 1657  if v022 == 23
replace A_h = 3053  if v022 == 25
replace A_h = 2293  if v022 == 27
replace A_h = 9529  if v022 == 29
replace A_h = 16957  if v022 == 31
replace A_h = 6874  if v022 == 33
replace A_h = 2621  if v022 == 35
replace A_h = 2548  if v022 == 37
replace A_h = 3090  if v022 == 39
replace A_h = 2106  if v022 == 41
replace A_h = 18409  if v022 == 43
replace A_h = 11911  if v022 == 45
replace A_h = 9774  if v022 == 47
replace A_h = 10006  if v022 == 49
replace A_h = 908  if v022 == 51
replace A_h = 2628  if v022 == 53
replace A_h = 1410  if v022 == 55
replace A_h = 9008  if v022 == 57
replace A_h = 7964  if v022 == 59
replace A_h = 12480  if v022 == 61
replace A_h = 9438  if v022 == 63
replace A_h = 23922  if v022 == 65
replace A_h = 7085  if v022 == 67
replace A_h = 8588  if v022 == 69
replace A_h = 19810  if v022 == 71
replace A_h = 22405  if v022 == 73
*Rural
replace A_h = 1138  if v022 == 4
replace A_h = 20850  if v022 == 2
replace A_h = 10354  if v022 == 6
replace A_h = 4556  if v022 == 8
replace A_h = 7211  if v022 == 10
replace A_h = 18319  if v022 == 12
replace A_h = 11930  if v022 == 14
replace A_h = 9988  if v022 == 16
replace A_h = 17124  if v022 == 18
replace A_h = 16288  if v022 == 20
replace A_h = 7539  if v022 == 22
replace A_h = 8943  if v022 == 24
replace A_h = 11870  if v022 == 26
replace A_h = 18900  if v022 == 28
replace A_h = 12263  if v022 == 30
replace A_h = 19402  if v022 == 32
replace A_h = 26442  if v022 == 34
replace A_h = 14020  if v022 == 36
replace A_h = 10231  if v022 == 38
replace A_h = 13942  if v022 == 40
replace A_h = 9463  if v022 == 42
replace A_h = 3498  if v022 == 44
replace A_h = 1977  if v022 == 46
replace A_h = 4223  if v022 == 48
replace A_h = 9567  if v022 == 50
replace A_h = 16205  if v022 == 52
replace A_h = 6379  if v022 == 54
replace A_h = 14912  if v022 == 56
replace A_h = 9201  if v022 == 58
replace A_h = 4829  if v022 == 60
replace A_h = 12381  if v022 == 62
replace A_h = 2123  if v022 == 64
replace A_h = 1502  if v022 == 66
replace A_h = 7408  if v022 == 68
replace A_h = 10667  if v022 == 70
replace A_h = 6097  if v022 == 72
replace A_h = 8701  if v022 == 74


* M_h average number of households per cluster by strata
gen M_h = 0
*Urban
replace M_h = 367  if v022 == 3
replace M_h = 231  if v022 == 1
replace M_h = 202  if v022 == 5
replace M_h = 138  if v022 == 7
replace M_h = 205  if v022 == 9
replace M_h = 182  if v022 == 11
replace M_h = 221  if v022 == 13
replace M_h = 278  if v022 == 15
replace M_h = 222  if v022 == 17
replace M_h = 178  if v022 == 19
replace M_h = 276  if v022 == 21
replace M_h = 214  if v022 == 23
replace M_h = 161  if v022 == 25
replace M_h = 197  if v022 == 27
replace M_h = 294  if v022 == 29
replace M_h = 231  if v022 == 31
replace M_h = 159  if v022 == 33
replace M_h = 190  if v022 == 35
replace M_h = 288  if v022 == 37
replace M_h = 186  if v022 == 39
replace M_h = 262  if v022 == 41
replace M_h = 184  if v022 == 43
replace M_h = 153  if v022 == 45
replace M_h = 234  if v022 == 47
replace M_h = 181  if v022 == 49
replace M_h = 132  if v022 == 51
replace M_h = 156  if v022 == 53
replace M_h = 283  if v022 == 55
replace M_h = 213  if v022 == 57
replace M_h = 229  if v022 == 59
replace M_h = 193  if v022 == 61
replace M_h = 189  if v022 == 63
replace M_h = 358  if v022 == 65
replace M_h = 264  if v022 == 67
replace M_h = 187  if v022 == 69
replace M_h = 132  if v022 == 71
replace M_h = 177  if v022 == 73
*Rural
replace M_h = 445  if v022 == 4
replace M_h = 182  if v022 == 2
replace M_h = 213  if v022 == 6
replace M_h = 164  if v022 == 8
replace M_h = 202  if v022 == 10
replace M_h = 165  if v022 == 12
replace M_h = 196  if v022 == 14
replace M_h = 240  if v022 == 16
replace M_h = 236  if v022 == 18
replace M_h = 171  if v022 == 20
replace M_h = 242  if v022 == 22
replace M_h = 217  if v022 == 24
replace M_h = 154  if v022 == 26
replace M_h = 207  if v022 == 28
replace M_h = 270  if v022 == 30
replace M_h = 282  if v022 == 32
replace M_h = 178  if v022 == 34
replace M_h = 197  if v022 == 36
replace M_h = 290  if v022 == 38
replace M_h = 194  if v022 == 40
replace M_h = 242  if v022 == 42
replace M_h = 226  if v022 == 44
replace M_h = 176  if v022 == 46
replace M_h = 234  if v022 == 48
replace M_h = 221  if v022 == 50
replace M_h = 233  if v022 == 52
replace M_h = 203  if v022 == 54
replace M_h = 167  if v022 == 56
replace M_h = 239  if v022 == 58
replace M_h = 292  if v022 == 60
replace M_h = 225  if v022 == 62
replace M_h = 290  if v022 == 64
replace M_h = 358  if v022 == 66
replace M_h = 254  if v022 == 68
replace M_h = 174  if v022 == 70
replace M_h = 133  if v022 == 72
replace M_h = 185  if v022 == 74


* m_c total number of completed households (added from the HR dataset)
* For Nigeria we use instead: number of de-jure population (hv012) from HR file
gen m_c= 186450
* M total number of households in country
* For Nigeria we use instead: number of population in frame
gen M = 140444528
* S_h households selected per stratum
*For Nigeria we use instead: population selected per stratum
gen S_h = 138

*gen DHS weight
gen DHSwt = v005 / 1000000
**********************************************************************
* Stage B *** Approximate Level-weights ***
**********************************************************************
* Steps to approximate Level-1 and Level-2 weights from Household or Individual Weights
*Step 1. De-normalize the final weight, using approximated normalization factor
gen d_HH = DHSwt * (M/m_c)
*Step 2. Approximate the Level-2 weight
* f the variation factor
gen f = d_HH / ((A_h/a_c_h) * (M_h/S_h))
* Calculating the level-weights based on different values of alpha
* SA: Will only use alpha of 0.5
local alphas 0.5 // 0 0.1 .25 .50 .75 0.90 1
*local i = 1

gen wt2 = (A_h/a_c_h)*(f^0.5)
gen wt1 = d_HH/wt2

/*
foreach dom of local alphas{
gen wt2_`i' = (A_h/a_c_h)*(f^`dom')
gen wt1_`i' = d_HH/wt2_`i'
local ++i
}
*/

save "$Codedfilepath/NG`c'coded.dta", replace
}



*Nepal survey
foreach c in IR MR {
	
use	"$Codedfilepath/NP`c'coded.dta", clear

* to make code work for MR file
cap gen v022=mv022
cap gen v021=mv021
cap gen v005=mv005

**********************************************************************
* Stage A *** Compile parameters/inputs for Level-weights calculations
**********************************************************************
* a_c_h completed clusters by strata
gen a_c_h=.
quietly levelsof v022, local(lstrata)
quietly foreach ls of local lstrata {
tab v021 if v022==`ls', matrow(T)
scalar stemp=rowsof(T)
replace a_c_h=stemp if v022==`ls'
}
* A_h total number of census clusters by strata
gen A_h = 0
*Urban
replace A_h = 537  if v022 == 1
replace A_h = 487  if v022 == 3
replace A_h = 756  if v022 == 5
replace A_h = 356  if v022 == 7
replace A_h = 470  if v022 == 9
replace A_h = 150  if v022 == 11
replace A_h = 324  if v022 == 13
*Rural
replace A_h = 5139  if v022 == 2
replace A_h = 5337  if v022 == 4
replace A_h = 4257  if v022 == 6
replace A_h = 3699  if v022 == 8
replace A_h = 4383  if v022 == 10
replace A_h = 2772  if v022 == 12
replace A_h = 2826  if v022 == 14

* M_h average number of households per cluster by strata
gen M_h = 0
*Urban
replace M_h = 724  if v022 == 1
replace M_h = 673  if v022 == 3
replace M_h = 1135  if v022 == 5
replace M_h = 730  if v022 == 7
replace M_h = 739  if v022 == 9
replace M_h = 508  if v022 == 11
replace M_h = 624  if v022 == 13
*Rural
replace M_h = 117  if v022 == 2
replace M_h = 113  if v022 == 4
replace M_h = 97  if v022 == 6
replace M_h = 86  if v022 == 8
replace M_h = 122  if v022 == 10
replace M_h = 81  if v022 == 12
replace M_h = 95  if v022 == 14

* m_c total number of completed households (added from the HR dataset)
gen m_c= 11040
* M total number of households in country
gen M = 5427901
* S_h households selected per stratum
gen S_h = 30

*gen DHS weight
gen DHSwt = v005 / 1000000
**********************************************************************
* Stage B *** Approximate Level-weights ***
**********************************************************************
* Steps to approximate Level-1 and Level-2 weights from Household or Individual Weights
*Step 1. De-normalize the final weight, using approximated normalization factor
gen d_HH = DHSwt * (M/m_c)
*Step 2. Approximate the Level-2 weight
* f the variation factor
gen f = d_HH / ((A_h/a_c_h) * (M_h/S_h))
* Calculating the level-weights based on different values of alpha
* SA: Will only use alpha of 0.5
local alphas 0.5 // 0 0.1 .25 .50 .75 0.90 1
*local i = 1

gen wt2 = (A_h/a_c_h)*(f^0.5)
gen wt1 = d_HH/wt2

/*
foreach dom of local alphas{
gen wt2_`i' = (A_h/a_c_h)*(f^`dom')
gen wt1_`i' = d_HH/wt2_`i'
local ++i
}
*/

save "$Codedfilepath/NP`c'coded.dta", replace

}


*Zambia survey
foreach c in IR MR {
	
use	"$Codedfilepath/ZM`c'coded.dta", clear

* to make code work for MR file
cap gen v022=mv022
cap gen v021=mv021
cap gen v005=mv005

**********************************************************************
* Stage A *** Compile parameters/inputs for Level-weights calculations
**********************************************************************
* a_c_h completed clusters by strata
gen a_c_h=.
quietly levelsof v022, local(lstrata)
quietly foreach ls of local lstrata {
tab v021 if v022==`ls', matrow(T)
scalar stemp=rowsof(T)
replace a_c_h=stemp if v022==`ls'
}
* A_h total number of census clusters by strata
gen A_h = 0
*Urban
replace A_h = 593  if v022 == 1
replace A_h = 2351  if v022 == 3
replace A_h = 245  if v022 == 5
replace A_h = 334  if v022 == 7
replace A_h = 2767  if v022 == 9
replace A_h = 188  if v022 == 11
replace A_h = 297  if v022 == 15
replace A_h = 198  if v022 == 13
replace A_h = 541  if v022 == 16
replace A_h = 214  if v022 == 19
*Rural
replace A_h = 2234  if v022 == 2
replace A_h = 924  if v022 == 4
replace A_h = 3279  if v022 == 6
replace A_h = 1890  if v022 == 8
replace A_h = 833  if v022 == 10
replace A_h = 1470  if v022 == 12
replace A_h = 2207  if v022 == 16
replace A_h = 984  if v022 == 14
replace A_h = 2307  if v022 == 17
replace A_h = 1775  if v022 == 20

* M_h average number of households per cluster by strata
gen M_h = 0
*Urban
replace M_h = 128  if v022 == 1
replace M_h = 143  if v022 == 3
replace M_h = 193  if v022 == 5
replace M_h = 132  if v022 == 7
replace M_h = 153  if v022 == 9
replace M_h = 141  if v022 == 11
replace M_h = 149  if v022 == 15
replace M_h = 159  if v022 == 13
replace M_h = 147  if v022 == 16
replace M_h = 127  if v022 == 19
*Rural
replace M_h = 89  if v022 == 2
replace M_h = 98  if v022 == 4
replace M_h = 90  if v022 == 6
replace M_h = 106  if v022 == 8
replace M_h = 111  if v022 == 10
replace M_h = 87  if v022 == 12
replace M_h = 89  if v022 == 16
replace M_h = 112  if v022 == 14
replace M_h = 90  if v022 == 17
replace M_h = 92  if v022 == 20

* m_c total number of completed households (added from the HR dataset)
gen m_c= 12831

* M total number of households in country
gen M = 2815897

* S_h households selected per stratum
gen S_h = 25

*gen DHS weight
gen DHSwt = v005 / 1000000
**********************************************************************
* Stage B *** Approximate Level-weights ***
**********************************************************************
* Steps to approximate Level-1 and Level-2 weights from Household or Individual Weights
*Step 1. De-normalize the final weight, using approximated normalization factor
gen d_HH = DHSwt * (M/m_c)
*Step 2. Approximate the Level-2 weight
* f the variation factor
gen f = d_HH / ((A_h/a_c_h) * (M_h/S_h))
* Calculating the level-weights based on different values of alpha
* SA: Will only use alpha of 0.5
local alphas 0.5 // 0 0.1 .25 .50 .75 0.90 1
*local i = 1

gen wt2 = (A_h/a_c_h)*(f^0.5)
gen wt1 = d_HH/wt2

/*
foreach dom of local alphas{
gen wt2_`i' = (A_h/a_c_h)*(f^`dom')
gen wt1_`i' = d_HH/wt2_`i'
local ++i
}
*/

save "$Codedfilepath/ZM`c'coded.dta", replace

}


/**********************************************************************
* Stage D *** Fit Random intercept models ***
**********************************************************************

svyset v001, weight(wt2) strata(v022) , singleunit(centered) || _n, weight(wt1)
svy: melogit cumodern age secondary urban i.children || v001:
estimates store model1

*/
	



********************************************************************************************
********************************************************************************************



	

