/****************************************************************************
*****																	*****
*****					YOUTH EMPOWERMENT SCALE							*****
*****																	*****
*****	PURPOSE: Create Youth Empowerment Scale as defined in WP179		*****
*****			and applied in the study published in AS77				*****
*****																	*****
*****	AUTHOR: Kerry L.D. MacQuarrie									*****
*****																	*****
*****	CREATED: 3/1/2021	Version 1.0									*****
*****																	*****
*****	INPUTS: DHS-7 IR files 									 		*****
*****																	*****
*****	SUGGESTED CITATION:												*****
*****	MacQuarrie, Kerry L.D. 2021. "YE_Scale.do: A Stata Program to 	*****
*****		Produce the Youth Empowerment Scale Using DHS Data"	 		*****
*****		Version 1.0. Rockville, MD: ICF								*****
*****																	*****
****************************************************************************/


use "[DATAFILE]", clear	
	/*Where [DATAFILE] = a DHS-7 women's recode (IR) datafile, e.g.: ETIR71FL.dta. IR. Datafiles are available from https://www.dhsprogram.com/data/ */

***SAMPLE RESTRICTION
**Youth age 15-29
keep if v013<4

***********************************************
*****
*****	VARIABLE RECODING
*****
************************************************

lab def yesno 0 "No" 1 "Yes"
lab def tercile 1 "Low" 2 "Medium" 3 "High"

gen wt=v005/1000000
gen psu=v001
	
**YE Scale Variables
	
**YE Factor 1: DV attitudes
	
*Wife-beating attitudes: Move DK to yes
recode v744a(8=1),g(dva)
	lab val dva yesno
recode v744b(8=1),g(dvb)
	lab val dvb yesno
recode v744c(8=1),g(dvc)
	lab val dvc yesno
recode v744d(8=1),g(dvd)
	lab val dvd yesno
recode v744e(8=1),g(dve)
	lab val dve yesno
	
**YE Factor 2: Banking & internet
	
*Keep v169a (has mobile phone) as is

*Phone banking: Put missings with not using phone for banking
recode v169b(.=0),g(mobank)
	lab var mobank "Uses mobile phone for financial transactions"
	lab val mobank yesno

*keep v170 (has bank account) as is

*keep v171a (ever used internet) as is

*keep v171b (frequency of using internet) as is
	
**YE Factor 3: Work & Earning
	
*keep v714 (currently working) as is

*Worked in last 12 months: dichotomize	
recode v731(0=0)(1/3 =1),g(work12)		
	lab var work12 "Worked in last 12 months"
	lab val work12 yesno

*Cash earnings: collapse categories
recode v741(. 0 =0 "No earnings")(3=1 "In-kind earnings")(1/2=2 "Cash"),g(earn)
	lab var earn "Has earnings"
		
**YE Factor 4: Health facility access
	
*keep v467b v467c v467d v467f (big problem seeking medical care) as is
	
**YE Factor 5: Home/land Ownership

*Dichotomize v745a (owns house) and v745b (owns land)
recode v745a(0=0 "No")(1/max=1 "Yes"),g(house)
	lab var house "Owns house alone or jointly"

recode v745b(0=0 "No")(1/max=1 "Yes"),g(land)
	lab var land "Owns land alone or jointly"	
		
**YE Factor 6: RH knowledge

*Fertility knowledge:	dichotomize v217 (ovulatory cycle) & v244 (post-partum fecundability) into correct Y/N
recode v217(3=1 "Yes")(0/2 =0 "No")(4/max =0),g(fertile)
	lab var fertile "Knows ovulatory cycle"

recode v244(0 8 =0 "No")(1=1 "Yes"),g(ppfertile)
	lab var ppfertile "Knows post-partum fecundability"

*Contraceptive knowledge: Collapse folkloric and traditional categories
recode v301(0=0 "None")(1/2=1 "Only traditional/folkloric method")(3=2 "Modern method"),g(FPknow)
	lab var FPknow "Knowledge of contraceptive methods"


***********************************************
*****
*****	FACTOR ANALYSIS (to create YE Scale and compute scores)
*****
************************************************

/*Conduct factor analysis with promax (oblique) rotation. This produces the 6-factor scale.*/
factor dva dvb dvc dvd dve v169a mobank v170 v171a v171b v714 work12 earn ///
	v467b v467c v467d v467f house land fertile ppfertile FPknow, pcf factors(6)
rotate, promax

***Produce scores 
predict YE1score YE2score YE3score YE4score YE5score YE6score
	lab var YE1score "YE: Violence attitudes factor score"
	lab var YE2score "YE: Banking & internet factor score"
	lab var YE3score "YE: Work & earnings factor score"
	lab var YE4score "YE: Health facility access factor score"
	lab var YE5score "YE: Ownership factor score"
	lab var YE6score "YE: RH knowledge factor score"

***Produce Crohnbach alphas for YE subscales
alpha dva dvb dvc dvd dve
alpha v169a mobank v170 v171a v171b
alpha v714 work12 earn
alpha v467b v467c v467d v467f
alpha house land
alpha fertile ppfertile FPknow

***Produce overall scale score & alpha
factor dva dvb dvc dvd dve v169a mobank v170 v171a v171b v714 work12 earn ///
	v467b v467c v467d v467f house land fertile ppfertile FPknow, pcf factors(1) 
rotate, promax

predict YEscore
	lab var YEscore "YE score"

***Produce overall YE scale Crohnbach alpha
alpha dva dvb dvc dvd dve v169a mobank v170 v171a v171b v714 work12 earn ///
	v467b v467c v467d v467f house land fertile ppfertile FPknow
	
***Create terciles based on YE factor scores
xtile YE_tercile=YEscore, nq(3)
	lab var YE_tercile "Youth empowerment tercile"
	lab val YE_tercile tercile

***Create terciles based on YE factor scores for each subscale
xtile YE1_tercile=YE1score, nq(3)
	lab var YE1_tercile "Youth empowerment tercile: violence attitudes"
	lab val YE1_tercile tercile
	
xtile YE2_tercile=YE2score, nq(3)
	lab var YE2_tercile "Youth empowerment tercile: Banking & internet"
	lab val YE2_tercile tercile
	
xtile YE3_tercile=YE3score, nq(3)
	lab var YE3_tercile "Youth empowerment tercile: Work"
	lab val YE3_tercile tercile
	
xtile YE4_tercile=YE4score, nq(3)
	lab var YE4_tercile "Youth empowerment tercile: Health access"
	lab val YE4_tercile tercile
	
xtile YE5_tercile=YE5score, nq(3)
	lab var YE5_tercile "Youth empowerment tercile: Major asset ownership"
	lab val YE5_tercile tercile
	
xtile YE6_tercile=YE6score, nq(3)
	lab var YE6_tercile "Youth empowerment tercile: RH knowledge"
	lab val YE6_tercile tercile
	
************************************************
*****
*****	END
*****
************************************************	
