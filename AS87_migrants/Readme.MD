
# Readme AS87: Internal Migrants Study

## Coding variables
The migrants_codevars.do file can be used to construct the migration measure used in the [DHS Analytical Study #87: Internal Adult Women Migrants’ Use and Access to 
Health Services in 15 DHS Countries](https://dhsprogram.com/publications/publication-as87-analytical-studies.cfm?csSearch=1076561_1). It also includes the outcomes and all the other vairables used in the analysis.

The resulting IR coded file for each survey was used to examine levels, trends, characteristics of migrants and the association of migrants with the four outcomes. 

### The migrant status measure has the following categories:
  1. Urban non-migrants (includes urban residents, urban-to-urban migrants, and rural-to-urban migrants that have stayed in the urban area for 10 or more years)
  2. Rural-to-urban migrants who have lived in the urban area for 3 to 9 years
  3. Rural-to-urban migrants who have lived in the urban area for <3 years (recent urban migrants)
  4. Rural non-migrants (includes rural residents, rural-to-rural migrants, and urban-to-rural migrants who have stayed in the rural area for 10 or more years)
  5. Urban-to-rural migrants who have lived in the rural area for 3 to 9 years
  6. Urban-to-rural migrants who have lived in the rural area for <3 years (recent rural migrants)

### The four outcomes examined among women age 18–49 are:
  1. Having at least four ANC visits among women with a recent birth in the three years before the survey;
  2. Currently using modern contraceptives. This excludes women who have never had sex.
  3. Reporting finding money needed for treatment as a major problem in obtaining medical care for herself.
  4. Reporting distance to health facility as a major problem in terms of accessing medical care for herself. 
 
The code for these outcomes and many others can also be found in the [DHS Program Code Share Library Stata Repository](https://github.com/DHSProgram/DHS-Indicators-Stata).


## Regression analysis
In the regression analysis, one model was fit with urban non-migrants as the reference category (label value=1) and another with rural non-migrants as the reference category (label value=4).
Due to highly correlated variables, only migration status, current age, education, work status, and marital status were included in the models. 

### Example code for ANC outcome:

For the code below, you can get the strata variable from the [Survey_strata.do file](https://github.com/DHSProgram/DHS-Analysis-Code/tree/main/Intro_DHSdata_Analysis/2_SurveyDesign) found in the [Introduction to DHS Data Analysis - Survey Design](https://github.com/DHSProgram/DHS-Analysis-Code/tree/main/Intro_DHSdata_Analysis) section of the DHS Analysis repository.


```stata

gen wt=v005/1000000
svyset [pw=wt], psu(v001) strata(strata) singleunit(centered)

# with urban non-migrants as the reference

svy: logistic anc i.migrants i.v013 i.edu i.work ib1.v502

# with rural non-migrants as the reference

svy: logistic anc ib4.migrants i.v013 i.edu i.work ib1.v502


```