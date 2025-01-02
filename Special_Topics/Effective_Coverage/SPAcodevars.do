/*****************************************************************************************************
Program: 			SPAcodevars.do
Purpose: 			Code SPA variables for ANC and Sick Child SPA files for proces quality composite
						measure for the MR31 report on Effective Coverage. All key process items were 
						coded, but inclusion in process quality composite measures was determined as 
						described in the report.
Author:				Shireen Assaf and Sara Riese			
Date last modified: May 27, 2021
*****************************************************************************************************/

* SPA surveys used in the analysis

*SPA Files - ANC patient observation
global spaacdata "HTAN7AFLSP MWAN6KFLSP NPAN71FLSP SNAN81FLSP TZAN71FLSP"

*SPA Files - Sick child observation
global spascdata "HTSC7AFLSP MWSC6KFLSP NPSC71FLSP SNSC81FLSP TZSC71FLSP"

****************************************************************************************************

* ANC
foreach c in $spaacdata {
scalar country = "`c'"
local country = substr(country,1,2)

use "`c'.dta", clear

label define yesno 0"No" 1"Yes"

gen fwt = facwt/1000000
gen pwt	= provwt/1000000
gen clwt = clientwt /1000000

*These Nepal facilities were droped from analysis. 
	if "`c'"=="NPAN71FLSP"{
	drop if factype==11 | facil==10369 | facil==10370
	}

********************************************************
*A2 ANC process quality
********************************************************

*daily oral iron and folic acid supplementation (counseled or prescribed)
gen cnsliron = !regexm(oa111,"Y")
label var cnsliron "gave any treatment or counseling on iron/folate suppl."

*counseled on breastfeeding
*combine counseling on early initiation and eclusive bf
gen cnslbfeed =  regexm(oa116, "B") | regexm(oa116, "C")
label var cnslbfeed "counseled on breastfeeding"

*checked blood pressure
gen chbp = regexm(oa107, "A") 
*| q1420_2==1 include this to match FR but we will not include in our analysis
label var chbp "took blood pressure"

********************************************************
*A3 ANC process quality 
********************************************************

*Hemoglobin test
gen tsthemo = regexm(oa108_1, "B") | regexm(oa108_1, "C") 
*| q1420_5==1 include this to match FR but we will not include in our analysis
label var tsthemo "hemoglobin test"

*Blood grouping. This was not included in the analysis as it was not available for all surveys. 
*gen tstblgp = regexm(oa108_2, "B") | regexm(oa108_2, "C")
*label var tstblgp "blood group test"

*Urine test
gen tsturine = regexm(oa108_3, "B") | regexm(oa108_3, "C")  
*| q1420_4==1 include this to match FR but we will not include in our analysis
label var tsturine "urine test"

*Syphilis test
gen tstsyph = regexm(oa108_4, "B") | regexm(oa108_4, "C") 
label var tstsyph "syphilis test"

*In Nepal option D is different from other surveys and should be included.  
if "`c'"=="NPAN71FLSP"{
replace tsthemo =1 if regexm(oa108_1, "D") 
replace tsturine=1 if regexm(oa108_3, "D") 
replace tstsyph =1 if regexm(oa108_4, "D") 
}

*checked blood pressure
*Coded in A2 (chbp)

*tetanus toxid vaccination
gen tetvac = regexm(oa112,"A")
label var tetvac "perscribed or gave a tetanus toxid injection"

*client history
gen clhist = !regexm(oa104,"Y")
label var clhist "provider asked about or client mentioned any client history info"

*this variable is to match the FR but we will not use it
*gen clhistall=regexm(oa104,"A") & regexm(oa104,"B") & regexm(oa104,"C") & (regexm(oa104,"D") | !regexm(oa105,"Y"))
*label var clhistall "provider asked about or client mentioned all client history info"

*measured weight
gen chwgt = regexm(oa107, "B") 
*| q1420_1==1 include this to match FR but we will not include in our analysis
label var chwgt "weighted the client"

*physical examination/ vaginal exam
gen chvag = regexm(oa107, "K")
label var chvag "conducted vaginal exam"

*checked oedema
gen chedema = regexm(oa107, "D")
label var chedema "checked for edema"

*checked fundal height
gen chfundht = regexm(oa107, "G") | regexm(oa107, "I") | regexm(oa107, "L")
label var chfundht "measured fundal height"

*checked client card
recode oa119 (2/3 .=0), gen(chcard) 
label var chcard "checked client's card"

*examined palms for anemia/ check pallor for anemia
gen chanem = regexm(oa107, "B")
label var chanem "checked for anemia"

*wrote on client card
recode oa120 (2 8 .=0), gen(wrtcard)
replace wrtcard=0 if chcard==0
if "`c'"=="HTAN7AFLSP"{
replace wrtcard=0 if oa120==3
}
label var wrtcard "wrote on card"

*Counseling/interpersonal
**************************
*danger signs of current pregnancy
gen cnsldsany = !(regexm(oa106b, "Y") & regexm(oa106a, "Y"))
label var cnsldsany "counseled on any of the danger signs"

/*this variable is to match the FR but we will not use it.
gen cnsldsany2= 0
replace cnsldsany2=1 if (regexm(oa106b, "A") | regexm(oa106a, "A"))
replace cnsldsany2=1 if (regexm(oa106b, "B") | regexm(oa106a, "B"))
replace cnsldsany2=1 if (regexm(oa106b, "C") | regexm(oa106a, "C"))
replace cnsldsany2=1 if (regexm(oa106b, "D") | regexm(oa106a, "D"))
replace cnsldsany2=1 if (regexm(oa106b, "E") | regexm(oa106a, "E"))
replace cnsldsany2=1 if (regexm(oa106b, "F") | regexm(oa106a, "F"))
replace cnsldsany2=1 if (regexm(oa106b, "G") | regexm(oa106a, "G"))
*/

*daily oral iron and folic acid supplementation (counseled or prescribed)
*coded in A2 (cnsliron)

*counseling on healthy eating and keeping physically active
*this is only healthy eating and not physically active
gen cnslnut = regexm(oa110, "A")
label var cnslnut "counseled on healthy eating"

*encouraged questions
recode oa117 (2=0), gen(enques)
label var enques "encourged questions"

*informed the client about the progress of the pregnancy
gen cnslprog = regexm(oa110, "B")
label var cnslprog "informed client on the progress of the pregnancy"

********************************************************

*first pregnancy
recode xa106 (2=0), gen(firstpreg)
label var firstpreg "Client's first pregnancy"

*first visit
recode oa123 (1=1) (else=0) , gen(firstvisit)
label var firstvisit "Client's first visit"

*****************************************
*COMPOSITE MEASURES

**Approach 2 composite quality measure
gen anc_q_2 =((cnsliron+cnslbfeed+chbp)/3) *100
label var anc_q_2 "Approach 2 SPA ANC quality index"

**Approach 3 composite quality measure
gen anc_q_3 =((tsthemo+tsturine+tstsyph+chbp+tetvac+clhist+chwgt+chedema+chfundht+chcard+chanem+wrtcard+cnsldsany+cnsliron+cnslnut+enques+cnslprog+cnslbfeed)/18)*100
label var anc_q_3 "Approach 3 SPA ANC quality index"
*****************************************
*save file
save "`c'coded.dta", replace

}

****************************************************************************************************
*Sick child
foreach c in $spascdata {
scalar country = "`c'"
local country = substr(country,1,2)

use "`c'.dta", clear

label define yesno 0"No" 1"Yes"

gen fwt = facwt/1000000
gen pwt	= provwt/1000000
gen clwt = clientwt /1000000

*These Nepal facilities were droped from analysis. 
	if "`c'"=="NPSC71FLSP"{
	drop if factype==11 | facil==10369 | facil==10370
	}

	
*******************************************************
*A2 and A3 sick child intervention coverage
*******************************************************
*Child had pneumonia and was given any antibiotic
gen int_pneu_diag = 0 
replace int_pneu_diag =1 if (regexm(oc202,"A")) 
gen int_pneu_trt =.
replace int_pneu_trt=0 if int_pneu_diag ==1 
replace int_pneu_trt =1 if int_pneu_diag ==1 & (regexm(oc210,"A") | (regexm(oc210,"B")) | (regexm(oc210,"D")) | (regexm(oc210,"E")) | (regexm(oc210,"F"))| (regexm(oc210,"G")) | (regexm(oc210,"H")) )

*Child had diarrhea and was given ORS or zinc or at home treatment
gen int_diarr_diag =0
replace int_diarr_diag =1 if ((regexm(oc203,"A")) |  (regexm(oc203,"B")) | (regexm(oc203,"C")) | (regexm(oc203,"X")) )

gen int_diarr_trt =.
replace int_diarr_trt =0 if int_diarr_diag==1

if "`c'"=="MWSC6KFLSP" | "`c'"=="TZSC71FLSP" | "`c'"=="HTSC7AFLSP"   {
	replace int_diarr_trt =1 if int_diarr_diag==1 & ( (regexm(oc213,"A")) | (regexm(oc213,"B")) | (regexm(oc213,"D")) ) | (regexm(oc210,"K"))
}
if "`c'"=="NPSC71FLSP" | "`c'"=="SNSC81FLSP" {
	replace int_diarr_trt =1 if int_diarr_diag==1 & ( (regexm(oc213,"A")) | (regexm(oc213,"B")))  | (regexm(oc210,"K"))
}

//Need to create a var for received intervention for any disease
gen int_cov=.
replace int_cov=0 if int_pneu_diag==1 
replace int_cov=0 if int_diarr_diag==1
replace int_cov=1 if int_pneu_trt==1 
replace int_cov=1 if int_diarr_trt==1

*****************************************
*COMPOSITE MEASURES

*Approach 2 and 3 sick child intervention coverage measure

g sc_i_23=int_cov
label var sc_i_23 "Approach 2 and 3 SPA sick child intervention coverage"
*****************************************

********************************************************
*A2 Sick child process quality
********************************************************
*Process quality vars start as follows:
	* ch_ 		for clinical actions provider carries out
	* ask_		for things the provider asks about
	* advise_ 	for things the provider advises only
	* cnsl_		for things the provider counsels only
	
*Provider counted respiration for 60 seconds
gen ch_pneumonia = 0 if (regexm(oc105,"B")) & xc107==1	//B = provider assessed cough, xc107 = caretaker mentioned cough for visit
replace ch_pneumonia = 1 if (regexm(oc108, "C"))
label var ch_pneumonia "Child with ARI symptoms assessed for pneumonia"
ta ch_pneumonia
label values ch_pneumonia yesno
	
*Provider weighed client
gen ch_nut3 = 0 
replace ch_nut3 = 1 if  (regexm(oc108, "N"))	//weighed child
label var ch_nut3 "Provider weighed client"
label values ch_nut3 yesno

*Provider plotted weight on growth chart
gen ch_nut4 = 0 
replace ch_nut4= 1 if  (regexm(oc108, "O"))		//plotted wt. on growth chart
label var ch_nut4 "Provider plotted weight on growth chart"
label values ch_nut4 yesno

*Provider checked palms / conjunctiva for pallor
gen ch_nut1 = 0 
replace ch_nut1 = 1 if  (regexm(oc108, "F")) | 	 (regexm(oc108, "G"))	
label var ch_nut1 "Provider checked palms / conjunctiva for pallor"
label values ch_nut1 yesno

*Checked skin turgor for dehydration (e.g., pinch abdominal skin)
gen ch_dehy = 0 if (regexm(oc105,"C")) & xc110==1
replace ch_dehy = 1 if (regexm(oc108, "E"))
label var ch_dehy "Child with diarrhea symptoms assessed for dehydration"
ta ch_dehy
label values ch_dehy yesno

*Provider discussed weight/growth/growth chart
gen ch_nut5 = 0 
replace ch_nut5= 1 if  (regexm(oc109, "E"))		//discussed growth chart
label var ch_nut5 "Provider discussed weight/growth/growth chart"
label values ch_nut5 yesno


********************************************************
*A3 Sick child process quality 
********************************************************
*Clinical
**********
*Provider asked / caretaker mentioned if child unable to drink or breastfeed
gen ask_drink =0
replace ask_drink = 1 if  (regexm(oc106, "A"))
label var ask_drink "Provider asked / caretaker mentioned if child unable to drink or breastfeed"
label values ask_drink yesno

*Provider asked / caretaker mentioned cough or difficult breathing
gen ask_cough =0
replace ask_cough = 1 if  (regexm(oc105, "B"))
label var ask_cough "Provider asked / caretaker mentioned cough or difficult breathing"
label values ask_cough yesno

*Provider asked / caretaker mentioned diarrhea
gen ask_diarr =0
replace ask_diarr = 1 if  (regexm(oc105, "C"))
label var ask_diarr "Provider asked / caretaker mentioned diarrhea"
label values ask_diarr yesno

*Provider asked / caretaker mentioned fever
gen ask_fever =0
replace ask_fever = 1 if  (regexm(oc105, "A"))
label var ask_fever "Provider asked / caretaker mentioned fever"
label values ask_fever yesno

*Provider asked / caretaker mentioned convulsions
gen ask_conv =0
replace ask_conv = 1 if  (regexm(oc106, "C"))
label var ask_conv "Provider asked / caretaker mentioned convulsions"
label values ask_conv yesno

*Provider checked palms / conjunctiva for pallor
*Coded in A2

*Provider asked caretaker about vomiting
gen ask_vomit =0
replace ask_vomit = 1 if  (regexm(oc106, "B"))
label var ask_vomit "Provider asked / caretaker mentioned vomiting"
label values ask_vomit yesno

*Provider weighed client
*Coded in A2

*Provider plotted weight on growth chart
*Coded in A2

*Provider took temperature
gen ch_temp=0
replace ch_temp = 1 if  (regexm(oc108, "A"))
label var ch_temp "Provider took temperature"
label values ch_temp yesno

*Provider checked for edema
gen ch_edema=0
replace ch_edema = 1 if  (regexm(oc108, "M"))
label var ch_edema "Provider checked for edema"
label values ch_edema yesno

*Provider asked / caretaker mentioned ear pain
gen ask_ear=0
replace ask_ear = 1 if  (regexm(oc105, "D"))
label var ask_ear "Provider asked / caretaker mentioned ear pain"
label values ask_ear yesno

*Provider counted respiration for 60 seconds
*Coded in A2

*Provide general information about feeding/breastfeeding
gen advise_genfeed=0
replace advise_genfeed =1 if (regexm(oc110, "A"))
label var advise_genfeed "Provider provides general information about feeding/breastfeeding"
label values advise_genfeed yesno

/*Provider asked about mother's HIV status
*removed due to Nepal's low HIV prevalence making this not-applicable to Nepal.
gen ask_hiv=0
replace ask_hiv =1 if (regexm(oc107, "A"))
label var ask_hiv "Provider asked about mother's HIV status"
label values ask_hiv yesno
*/

*Checked skin turgor for dehydration (e.g., pinch abdominal skin)
*Coded in A2

*Felt the child for fever or body hotness
gen ch_hot=0
replace ch_hot = 1 if  (regexm(oc108, "B"))
label var ch_hot "Provider Felt the child for fever or body hotness"
label values ch_hot yesno

*Checked for neck stiffness
gen ch_neck=0
replace ch_neck = 1 if  (regexm(oc108, "I"))
label var ch_neck "Provider Checked for neck stiffness"
label values ch_neck yesno

*Looked in child’s ear
gen ch_inear=0
replace ch_inear = 1 if  (regexm(oc108, "J"))
label var ch_inear "Provider Looked in child’s ear"
label values ch_inear yesno

*Felt behind child’s ear
gen ch_behear=0
replace ch_behear = 1 if  (regexm(oc108, "K"))
label var ch_behear "Provider Felt behind child’s ear"
label values ch_behear yesno

*checked vaccination status
gen ch_vacc=0
*Nepal has different coding for this var
	if "`c'"=="NPSC71FLSP"  {
	replace ch_vacc = 1 if  (regexm(oc109, "K"))
	}
	if "`c'"!="NPSC71FLSP"  {
	replace ch_vacc = 1 if  (regexm(oc109, "F"))
	}
label var ch_vacc "Provider checked vaccination status"
label values ch_vacc yesno

*check mouth and throat
gen ch_mouth=0
replace ch_mouth = 1 if  (regexm(oc108, "H"))
label var ch_mouth "Provider checked mouth and throat"
label values ch_mouth yesno

*provider asked about normal feeding/breastfeeding when not ill
gen ask_feed=0
replace ask_feed =1 if ((regexm(oc109, "B")) | (regexm(oc109, "C")))
label var ask_feed "Provider asked about normal feeding/breastfeeding when not ill"
label values ask_feed yesno

*provider asked about feeding or breastfeeding during this illness
gen ask_feedill=0
replace ask_feedill =1 if (regexm(oc109, "D")) 
label var ask_feedill "Provider asked about feeding or breastfeeding during this illness"
label values ask_feedill yesno

*Provider discussed weight/growth/growth chart
*generated in Approach 2

*advise extra fluids during this sickness
gen advise_fluid=0
replace advise_fluid = 1 if  (regexm(oc110, "B"))
label var advise_fluid "Provider advise extra fluids during this sickness"
label values advise_fluid yesno

*advise continued feeding during sickness
gen advise_contfeed=0
replace advise_contfeed = 1 if  (regexm(oc110, "C"))
label var advise_contfeed "Provider advise continued feeding during sickness"
label values advise_contfeed yesno

*Counseling/interpersonal
**************************
*Provider described more than 1 danger sign requiring return to facility
gen cnsl_dang=0
replace cnsl_dang = 1 if  (regexm(oc110, "E"))
label var cnsl_dang "Provider described more than 1 danger sign requiring return to facility"
label values cnsl_dang yesno

*Provider stated diagnosis to caretaker
gen cnsl_diag=0
replace cnsl_diag = 1 if  (regexm(oc110, "D"))
label var cnsl_diag "Provider stated diagnosis to caretaker"
label values cnsl_diag yesno

*Provider explained dosing if medication prescribed
gen cnsl_expmeds=0 if (regexm(oc111, "A"))
replace cnsl_expmeds = 1 if cnsl_expmeds==0 & (regexm(oc111, "B"))
label var cnsl_expmeds "Provider explained dosing if medication prescribed"
label values cnsl_expmeds yesno

*Provider asked caretaker to repeat the instructions for giving medicines at home (if medication prescribed)
gen cnsl_repmeds=0 if (regexm(oc111, "A"))
replace cnsl_repmeds = 1 if cnsl_repmeds==0 & (regexm(oc111, "C"))
label var cnsl_repmeds "Provider asked caretaker to repeat the instructions for giving medicines at home"
label values cnsl_repmeds yesno

*Provider discussed follow-up visit
gen cnsl_fuvisit=0
replace cnsl_fuvisit = 1 if  (regexm(oc111, "E"))
label var cnsl_fuvisit "Provider discussed follow-up visit"
label values cnsl_fuvisit yesno

*Provider used visual aids
gen cnsl_visaid=0
replace cnsl_visaid = 1 if  (regexm(oc110, "F"))
label var cnsl_visaid "Provider used visual aids"
label values cnsl_visaid yesno

*provider recorded on child's health card/booklet
gen cnsl_record=0
replace cnsl_record =1 if (regexm(oc109, "I"))
label var cnsl_record "provider recorded on child's health card/booklet"
label values cnsl_record yesno

*****************************************
*COMPOSITE MEASURES

**Approach 2 composite quality measure
gen sc_q_2 = ((ch_pneumonia + ch_nut3 + ch_nut4 + ch_nut1 + ch_dehy + ch_nut5)/6 )*100
label var sc_q_2 "Approach 2 SPA sick child quality index"

**Approach 3 composite quality measure
gen sc_q_3 = ((ch_pneumonia + ch_nut3 + ch_nut4 + ch_nut1 + ch_dehy + ch_nut5 + ask_drink + ask_cough + ask_diarr + ask_fever + ask_conv + ask_vomit + ch_temp + ch_edema + ask_ear + advise_genfeed + ch_hot + ch_neck + ch_inear + ch_behear + ch_vacc + ch_mouth + ask_feed + ask_feedill + advise_fluid + advise_contfeed + cnsl_dang + cnsl_diag + cnsl_expmeds + cnsl_repmeds + cnsl_fuvisit + cnsl_visaid + cnsl_record)/32) *100
label var sc_q_3 "Approach 3 SPA sick child quality index"
*****************************************

*save file
save "`c'coded.dta", replace

}
