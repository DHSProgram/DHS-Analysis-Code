
# DHS Report: The Effect of Fertility Behavior on Child Survival: Evidence from the Demographic and Health Surveys, 2012-2022
# Kristin Bietsch, PhD and Rebecca Rosenberg, PhD
# August 2023

library(survey)
library(tibble)
library(dplyr)
library(tidyr)
library(haven)
library(stringr)
library(questionr)
library(sjlabelled)
library(xlsx)
library(matrixStats)
library(scales)
library(survival)
library(forcats)
library(ggplot2)
options(scipen=999)
memory.limit(size = 2e6) 


# Load the master list of DHS surveys (will need to update this file as new DHS become available)
surveys <- read.xlsx2("C:/Users/KristinBietsch/files/Desktop/Master DHS Survey List.xlsx",sheetName="Sheet1",startRow=1,header=TRUE,
                      colClasses = c("character", "character", "character", "numeric",
                                     "character", "character", "character", "character", "numeric",
                                     "character", "numeric", "character", "character", "character", "character"));


spacing <- read.xlsx2("C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/DHS Surveys for Birth Spacing Reports 070623.xlsx",sheetName="Sheet1",startRow=1,header=TRUE,
                      colClasses = c( "character", "character", "character", "character", "numeric",
                                      "character", "character"));

cal_results <- read.csv( "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Surveys with Calendar Contraception Data.csv")


surveys_clean <- surveys %>% select(API_ID, BR) %>% mutate(BR=paste(BR, ".DTA", sep="")) %>% full_join(spacing, by="API_ID") %>%
  filter(BirthSpacingStudy=="New")  %>%
  left_join(cal_results, by="API_ID") %>%
  mutate(CalStatus=case_when(is.na(CalStatus) ~ "Missing",
                             !is.na(CalStatus) ~ CalStatus)) 

# 2014 Study Results
spacing_2014 <- read.csv("C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Report2014 Tables/Birth Spacing 2014 Report.csv")
matage_2014 <- read.csv("C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Report2014 Tables/Maternal Age 2014 Report.csv")
parity_2014 <- read.csv("C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Report2014 Tables/Parity 2014 Report.csv")


############################################################################################################################################
# List of Surveys
survey_list <- surveys_clean %>% arrange(Country, StartYear) %>% select(Country, FullYear) %>%
  group_by(Country) %>% mutate(id = row_number()) %>% mutate(max=max(id)) %>%
  mutate(comma=case_when(id==max ~ "",
                         id<max ~ ",")) %>%
  mutate(FullYear=paste(FullYear, comma, sep="")) %>%
  select(-max, -comma) %>% mutate(id=paste("Survey", id, sep=""))  %>% 
  spread(id, FullYear) %>%
  mutate(Survey2=case_when(is.na(Survey2) ~ "", !is.na(Survey2) ~ Survey2),
         Survey3=case_when(is.na(Survey3) ~ "", !is.na(Survey3) ~ Survey3),
         Survey4=case_when(is.na(Survey4) ~ "", !is.na(Survey4) ~ Survey4),
         Survey5=case_when(is.na(Survey5) ~ "", !is.na(Survey5) ~ Survey5),
         Survey6=case_when(is.na(Survey6) ~ "", !is.na(Survey6) ~ Survey6),
         Survey7=case_when(is.na(Survey7) ~ "", !is.na(Survey7) ~ Survey7)) %>%
  mutate(Surveys=paste(Country, Survey1, Survey2, Survey3, Survey4, Survey5, Survey6, Survey7, sep=" " )) %>% ungroup() %>%
  select(Surveys)
  
header1 <- c("Table 1. List of surveys, by country", "Countries and Survey Years")
header1 <- data.frame(header1)

#write.table(header1, file = "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Survey List DHS Report.csv" ,sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(survey_list, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Survey List DHS Report.csv" ,sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)

############################################################################################################################################
# Empty Data Frames


birth_intervals_df <- setNames(data.frame(matrix(ncol = 15,  nrow = 0)),  c("Survey" ,       "FirstBorn",    "M12to17", "M18to23", "M24to29", "M30to35", "M36to47", "M48to59", "M60to95", "M6to11",  "M96P",  "Under6",   "bc_mean",       "bc_median" ,   "N")) %>% 
  mutate(Survey=as.character(Survey),FirstBorn =as.numeric(FirstBorn),
         M12to17=as.numeric(M12to17),
         M18to23=as.numeric(M18to23),
         M24to29=as.numeric(M24to29),
         M30to35=as.numeric(M30to35),
         M36to47=as.numeric(M36to47),
         M48to59=as.numeric(M48to59),
         M60to95=as.numeric(M60to95),
         M6to11=as.numeric(M6to11),
         M96P=as.numeric(M96P),
         Under6=as.numeric(Under6),
         bc_mean=as.numeric(bc_mean),
         bc_median=as.numeric(bc_median),
         N=as.numeric(N) ) 


birth_age_df <- setNames(data.frame(matrix(ncol = 9,  nrow = 0)),  c("Age1824",    "Age2534" ,   "Age3539"  ,  "Age40P"   ,  "AgeU18"   ,  "Survey"   ,  "age_mean"  , "age_median" , "N"  )) %>% 
  mutate(Survey=as.character(Survey),
         Age1824=as.numeric(Age1824),
         Age2534=as.numeric(Age2534),
         Age3539=as.numeric(Age3539),
         Age40P=as.numeric(Age40P),
         AgeU18=as.numeric(AgeU18),
         age_mean=as.numeric(age_mean),
         age_median=as.numeric(age_median),
         N=as.numeric(N) ) 


birth_bord_df <- setNames(data.frame(matrix(ncol = 9,  nrow = 0)),  c("BO1",    "BO2" ,   "BO34"  ,  "BO56"   ,  "BO7P"   ,  "Survey"   ,  "bord_mean"  , "bord_median" , "N"  )) %>% 
  mutate(Survey=as.character(Survey),
         BO1=as.numeric(BO1),
         BO2=as.numeric(BO2),
         BO34=as.numeric(BO34),
         BO56=as.numeric(BO56),
         BO7P=as.numeric(BO7P),
         bord_mean=as.numeric(bord_mean),
         bord_median=as.numeric(bord_median),
         N=as.numeric(N) ) 


birth_riskfull_df <- setNames(data.frame(matrix(ncol = 28,  nrow = 0)),  c( "Double4PMA40P"    ,             "Double4PMAU18"  ,               "Double4PSP2435"   ,             "Double4PSPU24"  ,               "DoubleSP2435MA40P"  ,          
                                                                            "DoubleSP2435MAU18"  ,           "DoubleSPU24MA40P" ,             "DoubleSPU24MAU18" ,             "DoubleUnavoidFirstMA40P" ,      "DoubleUnavoidFirstMAU18",      
                                                                            "DoubleUnavoidFirstSP2435" ,     "DoubleUnavoidFirstSPU24"  ,     "NoExtraRisk"    ,               "Single4P"  ,                    "SingleMA40P" ,                 
                                                                            "SingleMAU18" ,                  "SingleSP2435",                  "SingleSPU24"    ,               "SingleUnavoidFirst"   ,         "Triple4PSP2435MA40P"  ,        
                                                                            "Triple4PSP2435MAU18" ,          "Triple4PSPU24MA40P"  ,          "Triple4PSPU24MAU18"   ,         "TripleUnavoidFirstSP2435MA40P", "TripleUnavoidFirstSP2435MAU18",
                                                                            "TripleUnavoidFirstSPU24MA40P" , "TripleUnavoidFirstSPU24MAU18" , "Survey"    )) %>% 
  mutate(Survey=as.character(Survey),
         Double4PMA40P=as.numeric(Double4PMA40P),
         Double4PMAU18=as.numeric(Double4PMAU18),
         Double4PSP2435=as.numeric(Double4PSP2435),
         Double4PSPU24=as.numeric(Double4PSPU24),
         DoubleSP2435MA40P=as.numeric(DoubleSP2435MA40P),
         DoubleSP2435MAU18=as.numeric(DoubleSP2435MAU18),
         DoubleSPU24MA40P=as.numeric(DoubleSPU24MA40P),
         DoubleSPU24MAU18=as.numeric(DoubleSPU24MAU18),
         DoubleUnavoidFirstMA40P=as.numeric(DoubleUnavoidFirstMA40P),
         DoubleUnavoidFirstMAU18=as.numeric(DoubleUnavoidFirstMAU18),
         DoubleUnavoidFirstSP2435=as.numeric(DoubleUnavoidFirstSP2435),
         DoubleUnavoidFirstSPU24=as.numeric(DoubleUnavoidFirstSPU24),
         NoExtraRisk=as.numeric(NoExtraRisk),
         Single4P=as.numeric(Single4P),
         SingleMA40P=as.numeric(SingleMA40P),
         SingleMAU18=as.numeric(SingleMAU18),
         SingleSP2435=as.numeric(SingleSP2435),
         SingleSPU24=as.numeric(SingleSPU24),
         SingleUnavoidFirst=as.numeric(SingleUnavoidFirst),
         Triple4PSP2435MA40P=as.numeric(Triple4PSP2435MA40P),
         Triple4PSP2435MAU18=as.numeric(Triple4PSP2435MAU18),
         Triple4PSPU24MA40P=as.numeric(Triple4PSPU24MA40P),
         Triple4PSPU24MAU18=as.numeric(Triple4PSPU24MAU18),
         TripleUnavoidFirstSP2435MA40P=as.numeric(TripleUnavoidFirstSP2435MA40P),
         TripleUnavoidFirstSP2435MAU18=as.numeric(TripleUnavoidFirstSP2435MAU18),
         TripleUnavoidFirstSPU24MA40P=as.numeric(TripleUnavoidFirstSPU24MA40P),
         TripleUnavoidFirstSPU24MAU18=as.numeric(TripleUnavoidFirstSPU24MAU18)) 

birth_risksimp_df <- setNames(data.frame(matrix(ncol = 7,  nrow = 0)),  c( "Double"  ,     "NoExtraRisk",  "Single"  ,     "Triple" ,      "UnavoidFirst" , "Survey"   ,    "N"    )) %>% 
  mutate(Survey=as.character(Survey),
         Double=as.numeric(Double),
         NoExtraRisk=as.numeric(NoExtraRisk),
         Single=as.numeric(Single),
         Triple=as.numeric(Triple),
         UnavoidFirst=as.numeric(UnavoidFirst),
         N=as.numeric(N)) 


############################################################################################################################################
# Loop Through Each Survey
for (row in 1:nrow(surveys_clean)) {
  birth_data <- surveys_clean[row, "BR"]
  countryname <- surveys_clean[row, "API_ID"]
  calendarinfo <- surveys_clean[row, "CalStatus"]
  
  cal_results_file <- paste("C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/WomenBirth/", countryname, "_BirthsinCalendar.dta", sep="")
  
  # You will need to reset the directory to where you DHS surveys are stored
  setwd("C:/Users/KristinBietsch/Files/DHSLoop")
  
  # Loading surveys, only the variables we need
  allbirths <- read_dta(birth_data, col_select = any_of(c("caseid",  "v005",  "v008" , "v011", "b3" ,  "b11" , "bord" , "b0", "b10")))  %>% mutate(Survey=countryname)
  
  
  
  if (calendarinfo=="Calendar") {
    women_birth <- read_dta(cal_results_file)
    allbirths <- left_join(allbirths, women_birth, by=c("caseid", "b3"))  
  }
  
  if (calendarinfo=="Missing") {
    allbirths <- allbirths %>% mutate(Gestation=9, Failure=99, PrecedingPreg="Missing") 
  }
  
  
  births <- allbirths
  
  
  births$sampleweights <- births$v005/100000
  
  births <- births %>% mutate(timesince = v008-b3) %>% 
    mutate(Gestation=case_when(Gestation >10 ~ 10,
                               Gestation <7 ~ 7,
                               !is.na(Gestation) ~ Gestation,
                               is.na(Gestation) ~ 9)) %>%
    mutate(birth_conce = b11-Gestation) %>% 
    mutate(interval=case_when(bord==1 ~ "FirstBorn",
                              bord==2 & b0==2 ~ "FirstBorn",
                              bord==3 & b0==3 ~ "FirstBorn",
                              !is.na(b11) & birth_conce<6 ~ "Under6",
                              !is.na(b11) & birth_conce>=6 & birth_conce<=11 ~ "M6to11",
                              !is.na(b11) & birth_conce>=12 & birth_conce<=17 ~ "M12to17",
                              !is.na(b11) & birth_conce>=18 & birth_conce<=23 ~ "M18to23",
                              !is.na(b11) & birth_conce>=24 & birth_conce<=29 ~  "M24to29",
                              !is.na(b11) & birth_conce>=30 & birth_conce<=35 ~ "M30to35",
                              !is.na(b11) & birth_conce>=36 & birth_conce<=47 ~ "M36to47",
                              !is.na(b11) & birth_conce>=48 & birth_conce<=59 ~ "M48to59",
                              !is.na(b11) & birth_conce>=60 & birth_conce<=95 ~ "M60to95",
                              !is.na(b11) & birth_conce>=96 ~ "M96P" )) %>%
    mutate(Mothers_age = (b3- v011)/12) %>%
    mutate(Mothers_age_gr = case_when(Mothers_age<18 ~ "AgeU18",
                                      Mothers_age>=18 & Mothers_age<25 ~ "Age1824",
                                      Mothers_age>=25 & Mothers_age<35 ~ "Age2534",
                                      Mothers_age>=35 & Mothers_age<40 ~ "Age3539",
                                      Mothers_age>=40 ~ "Age40P"))  %>%
    mutate(bord_gr = case_when(bord==1 ~ "BO1",
                               bord==2 ~ "BO2",
                               bord==3 |  bord==4 ~ "BO34",
                               bord==5 |  bord==6 ~ "BO56",
                               bord>=7 ~ "BO7P")) %>%
    mutate(birthorder = case_when(bord==1 ~ "BO1",
                                  bord==2 | bord==3 ~ "BO24",
                                  bord>=4 ~ "BO4P"),
           spacing = case_when(b11 <24 ~ "SPU24",
                               b11>=24 & b11<=35 ~ "SP2435",
                               b11>=36 ~ "SP36P",
                               is.na(b11) ~ "SPFB"),
           matage = case_when(Mothers_age <18 ~ "MAU18",
                              Mothers_age >=18 & Mothers_age<40 ~ "MA1839",
                              Mothers_age >=40 ~ "MA40P")) %>%
    mutate(birthorder_risk=case_when(birthorder=="BO1" ~ "UnavoidFirst",
                                     birthorder=="BO4P" ~ "4P",
                                     TRUE ~ ""),
           space_risk = case_when(spacing=="SPU24" ~ "SPU24",
                                  spacing=="SP2435" ~ "SP2435",
                                  TRUE ~ ""),
           matage_risk = case_when(matage=="MAU18" ~ "MAU18",
                                   matage=="MA40P" ~ "MA40P",
                                   TRUE ~ "")) %>%
    mutate(birthorder_num = case_when(birthorder=="BO1" | birthorder=="BO4P" ~ 1, TRUE ~ 0),
           space_num = case_when(spacing=="SPU24" | spacing=="SP2435" ~ 1, TRUE ~ 0),
           matage_num =case_when(matage=="MAU18" |  matage=="MA40P" ~ 1, TRUE ~ 0 ),
           num_total = birthorder_num + space_num + matage_num,
           RiskNum= case_when(num_total==0 ~ "NoExtraRisk",
                              num_total==1 ~ "Single",
                              num_total==2 ~ "Double",
                              num_total==3 ~ "Triple")) %>%
    mutate(RiskGr=paste(RiskNum, birthorder_risk, space_risk, matage_risk, sep="")) %>%
    mutate(RiskGR_Simple=case_when(RiskNum=="NoExtraRisk" ~ "NoExtraRisk",
                                   RiskNum== "Single" & birthorder_risk =="UnavoidFirst" ~ "UnavoidFirst",
                                   RiskNum== "Single" ~ "Single" ,
                                   RiskNum== "Double" ~ "Double" ,
                                   RiskNum== "Triple" ~ "Triple" ))
  
  births179 <- births %>% filter(timesince <= 179)   %>% filter(b0==0)
  # Only including singletons
  
  non_first <- births179 %>% filter(interval!="FirstBorn")
  
  # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  birth_intervals <-    as.data.frame(prop.table(wtd.table( births179$interval,  weights=births179$sampleweights ))) %>%
     mutate(Survey=countryname) %>% spread(Var1, Freq)
  
  bc_mean <- as.data.frame(weighted.mean(non_first$birth_conce, weights=non_first$sampleweights)) %>% rename(bc_mean=1)  %>% mutate(Survey=countryname) 
  bc_median <- as.data.frame(weightedMedian(non_first$birth_conce, non_first$sampleweights, na.rm = TRUE))  %>% rename(bc_median=1)  %>% mutate(Survey=countryname) 

  birth_n <-    as.data.frame(table( births179$interval)) %>% summarise(N=sum(Freq)) %>% mutate(Survey=countryname) 
  
  births_df <- full_join(birth_intervals,  bc_mean,  by="Survey") %>% full_join(bc_median, by="Survey")  %>% full_join(birth_n, by="Survey") 
  
  birth_intervals_df <- bind_rows(birth_intervals_df , births_df)
  
  # # # # # # # # # # # # # # # # # # # # # # # # # # # 

  birth_agegr <-    as.data.frame(prop.table(wtd.table( births179$Mothers_age_gr,  weights=births179$sampleweights )))  %>% 
  spread(Var1, Freq) %>% mutate(Survey=countryname) 
  
  age_mean <- as.data.frame(weighted.mean(births179$Mothers_age, weights=births179$sampleweights)) %>% rename(age_mean=1)  %>% mutate(Survey=countryname) 
  age_median <- as.data.frame(weightedMedian(births179$Mothers_age, births179$sampleweights, na.rm = TRUE))  %>% rename(age_median=1)  %>% mutate(Survey=countryname) 
  
  age_n <-    as.data.frame(table( births179$Mothers_age_gr)) %>% summarise(N=sum(Freq)) %>% mutate(Survey=countryname) 
  
  age_df <- full_join(birth_agegr,  age_mean,  by="Survey") %>% full_join(age_median, by="Survey") %>% full_join(age_n, by="Survey") 
  
  birth_age_df <- bind_rows(birth_age_df , age_df)

  # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  birth_bord_gr <-    as.data.frame(prop.table(wtd.table( births179$bord_gr,  weights=births179$sampleweights )))  %>% 
    spread(Var1, Freq) %>% mutate(Survey=countryname) 
  
  bord_mean <- as.data.frame(weighted.mean(births179$bord, weights=births179$sampleweights)) %>% rename(bord_mean=1)  %>% mutate(Survey=countryname) 
  bord_median <- as.data.frame(weightedMedian(births179$bord, births179$sampleweights, na.rm = TRUE))  %>% rename(bord_median=1)  %>% mutate(Survey=countryname) 
  
  bord_n <-    as.data.frame(table( births179$bord)) %>% summarise(N=sum(Freq)) %>% mutate(Survey=countryname) 
  
  bord_df <- full_join(birth_bord_gr,  bord_mean,  by="Survey") %>% full_join(bord_median, by="Survey") %>% full_join(bord_n, by="Survey") 
  
  birth_bord_df <- bind_rows(birth_bord_df , bord_df)
  
  # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  birth_riskfull_gr <-    as.data.frame(prop.table(wtd.table( births179$RiskGr,  weights=births179$sampleweights )))  %>% 
    spread(Var1, Freq) %>% mutate(Survey=countryname) 
  
  birth_riskfull_n <-    as.data.frame(table( births179$RiskGr)) %>% summarise(N=sum(Freq)) %>% mutate(Survey=countryname) 
  
  riskfull_df <- full_join(birth_riskfull_gr,  birth_riskfull_n,  by="Survey") 
  
  birth_riskfull_df <- bind_rows(birth_riskfull_df, riskfull_df)
  
  # # # # # # # # # # # # # # # # # # # # # # # # # # # 
  
  birth_risksimp_gr <-    as.data.frame(prop.table(wtd.table( births179$RiskGR_Simple,  weights=births179$sampleweights )))  %>% 
    spread(Var1, Freq) %>% mutate(Survey=countryname) 
  
  birth_risksimp_n <-    as.data.frame(table( births179$RiskGR_Simple)) %>% summarise(N=sum(Freq)) %>% mutate(Survey=countryname) 
  
  risksimp_df <- full_join(birth_risksimp_gr,  birth_risksimp_n,  by="Survey") 

  birth_risksimp_df <- bind_rows(birth_risksimp_df, risksimp_df)
  
  
}
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Cleaning the loop results
birth_intervals_clean <- birth_intervals_df  %>% rename(API_ID=Survey) %>% 
  full_join(surveys_clean, by="API_ID") %>%  
  select(Country, FullYear, Under6, M6to11, M12to17, M18to23, M24to29, M30to35, M36to47, M48to59, M60to95, M96P, FirstBorn, bc_mean, bc_median,  N )

birth_age_clean <- birth_age_df  %>% rename(API_ID=Survey) %>% 
  full_join(surveys_clean, by="API_ID") %>% 
  select(Country, FullYear, AgeU18, Age1824, Age2534, Age3539, Age40P, age_mean, age_median,  N )


birth_order_clean <- birth_bord_df  %>% rename(API_ID=Survey) %>% 
  full_join(surveys_clean, by="API_ID") %>% 
  select(Country, FullYear, BO1, BO2, BO34, BO56, BO7P, bord_mean, bord_median,  N )

birth_riskfull_clean <- birth_riskfull_df  %>% rename(API_ID=Survey) %>% 
  full_join(surveys_clean, by="API_ID") %>% 
  select(Country , FullYear,  NoExtraRisk , SingleUnavoidFirst ,
         SingleSPU24,      SingleSP2435,    SingleMAU18 ,   SingleMA40P,  Single4P  ,
         Double4PSPU24,   Double4PSP2435 , DoubleUnavoidFirstMAU18 , DoubleUnavoidFirstMA40P ,    Double4PMAU18 , Double4PMA40P,    DoubleSPU24MAU18, DoubleSP2435MAU18, DoubleSPU24MA40P , DoubleSP2435MA40P ,     
         Triple4PSPU24MAU18 ,  Triple4PSPU24MA40P, Triple4PSP2435MAU18 , Triple4PSP2435MA40P , N )

birth_risksimp_clean <- birth_risksimp_df  %>% rename(API_ID=Survey) %>% 
  full_join(surveys_clean, by="API_ID") %>%
  select(Country, FullYear, NoExtraRisk, UnavoidFirst, Single, Double, Triple, N) %>%
  mutate(Triple=case_when(!is.na(Triple) ~ Triple, is.na(Triple) ~ 0))
###########################################################################################################
# Creating Giant Dataset
new_births <-  setNames(data.frame(matrix(ncol = 64,  nrow = 0)),  c("caseid", "v000", "v007", "v005",  "v008" , "v011",  "v025",  "v106", "v190", "v113", "v116", 
                                                                 "v122", "b3" , "b4", "b6",  "b7", "b11" , "bord" , "b0", "b10", "b20", "s220ab", "s225", "s222",
                                                                 "m10", 
                                                                 "m2a", "m2b", "m2c", "m2d", "m2e", "m2f", "m2g", "m2h", "m2i", "m2j", "m2k", "m2l", "m2m", "m2n",
                                                                 "m3a", "m3b", "m3c", "m3d", "m3e", "m3f", "m3g", "m3h", "m3i", "m3j", "m3k", "m3l", "m3m", "m3n",
                                                                 "m1", "m13", "m14", "v017", "v228", "v231", "v239",
                                                                 "Gestation", "Failure", "PrecedingPreg", "Survey"))  %>%
  mutate(v000=as.character(v000),
         v007=as.numeric(v007),
         v025=as.numeric(v025),
         v106=as.numeric(v106),
         v113=as.numeric(v113),
         v116=as.numeric(v116),
         v122=as.numeric(v122),
         v190=as.numeric(v190),
         b0=as.numeric(b0),
         b4=as.numeric(b4),
         b6=as.numeric(b6),
         b10=as.numeric(b10),
         m10=as.numeric(m10),
         Gestation=as.numeric(Gestation),
         Failure=as.numeric(Failure),
         PrecedingPreg=as.character(PrecedingPreg),
         caseid=as.character(caseid),
         Survey=as.character(Survey),
         m2a=as.numeric(m2a),  m2b=as.numeric(m2b),  m2c=as.numeric(m2c),  m2d=as.numeric(m2d), m2e=as.numeric(m2e),  m2f=as.numeric(m2f), 
         m2g=as.numeric(m2g),  m2h=as.numeric(m2h), m2i=as.numeric(m2i), m2j=as.numeric(m2j),  m2k=as.numeric(m2k),  m2l=as.numeric(m2l),  m2m=as.numeric(m2m),  m2n=as.numeric(m2n),  
         m3a=as.numeric(m3a),  m3b=as.numeric(m3b),  m3c=as.numeric(m3c),  m3d=as.numeric(m3d), m3e=as.numeric(m3e),  m3f=as.numeric(m3f), 
         m3g=as.numeric(m3g),  m3h=as.numeric(m3h), m3i=as.numeric(m3i), m3j=as.numeric(m3j),  m3k=as.numeric(m3k),  m3l=as.numeric(m3l),  m3m=as.numeric(m3m),  m3n=as.numeric(m3n),  
         m1=as.numeric(m1),  m13=as.numeric(m13) ,  m14=as.numeric(m14) ,  v017=as.numeric(v017) ,  v228=as.numeric(v228) ,  v231=as.numeric(v231) ,  v239=as.numeric(v239))


for (row in 1:nrow(surveys_clean)) {
  birth_data <- surveys_clean[row, "BR"]
  countryname <- surveys_clean[row, "API_ID"]
  calendarinfo <- surveys_clean[row, "CalStatus"]
  
  cal_results_file <- paste("C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/WomenBirth/", countryname, "_BirthsinCalendar.dta", sep="")
  
  
  # You will need to reset the directory to where you DHS surveys are stored
  setwd("C:/Users/KristinBietsch/Files/DHSLoop")
  
  # Loading surveys, only the variables we need
  # Loading surveys, only the variables we need
  allbirths <- read_dta(birth_data, col_select = any_of(c("caseid", "v000", "v007", "v005",  "v008" , "v011",  "v025",  "v106", "v190", "v113", "v116", 
                                                          "v122", "b3" , "b4", "b6",  "b7", "b11" , "bord" , "b0", "b10", "b20", "s220ab", "s225", "s222",
                                                          "m10", 
                                                          "m2a", "m2b", "m2c", "m2d", "m2e", "m2f", "m2g", "m2h", "m2i", "m2j", "m2k", "m2l", "m2m", "m2n",
                                                          "m3a", "m3b", "m3c", "m3d", "m3e", "m3f", "m3g", "m3h", "m3i", "m3j", "m3k", "m3l", "m3m", "m3n",
                                                          "m1", "m13" , "m14", "v017", "v228", "v231", "v239"))) %>% mutate(Survey=countryname)
  
  
  if (calendarinfo=="Calendar") {
    women_birth <- read_dta(cal_results_file)
    allbirths <- left_join(allbirths, women_birth, by=c("caseid", "b3"))  
  }
  
  if (calendarinfo=="Missing") {
    allbirths <- allbirths %>% mutate(Gestation=9, Failure=99, PrecedingPreg="Missing") 
  }
  
  
  
  
  
  new_births <- bind_rows(new_births , allbirths)
  
  
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


# older child died before conception of next child
new_olderchild <- new_births %>%
  rename(bord_older=bord) %>% mutate(bord= bord_older + 1) %>%
  mutate(sub_cmc_death = b7 + b3) %>%
  select(caseid, v000, v005, v007, v008,  bord, sub_cmc_death)



new_births_clean <- new_births %>% mutate(timesince = v008-b3) %>% 
  mutate(Gestation=case_when(Gestation >10 ~ 10,
                             Gestation <7 ~ 7,
                             !is.na(Gestation) ~ Gestation,
                             is.na(Gestation) ~ 9)) %>%
  mutate(birth_conce = b11-Gestation) %>% 
  mutate(cmc_conception= b3-Gestation) %>% 
  mutate(interval=case_when(bord==1 ~ "FirstBorn",
                            bord==2 & b0==2 ~ "FirstBorn",
                            bord==3 & b0==3 ~ "FirstBorn",
                            !is.na(b11) & birth_conce<6 ~ "Under6",
                            !is.na(b11) & birth_conce>=6 & birth_conce<=11 ~ "M6to11",
                            !is.na(b11) & birth_conce>=12 & birth_conce<=17 ~ "M12to17",
                            !is.na(b11) & birth_conce>=18 & birth_conce<=23 ~ "M18to23",
                            !is.na(b11) & birth_conce>=24 & birth_conce<=29 ~  "M24to29",
                            !is.na(b11) & birth_conce>=30 & birth_conce<=35 ~ "M30to35",
                            !is.na(b11) & birth_conce>=36 & birth_conce<=47 ~ "M36to47",
                            !is.na(b11) & birth_conce>=48 & birth_conce<=59 ~ "M48to59",
                            !is.na(b11) & birth_conce>=60 & birth_conce<=95 ~ "M60to95",
                            !is.na(b11) & birth_conce>=96 ~ "M96P" )) %>%
  mutate(interval=factor(interval, levels = c("FirstBorn", "Under6", "M6to11", "M12to17", "M18to23", "M24to29", 
                                              "M30to35", "M36to47", "M48to59", "M60to95", "M96P"))) %>%
  mutate(interval=relevel(interval, ref ="M36to47")) %>%
  mutate(Mothers_age = (b3- v011)/12) %>%
  mutate(Mothers_age_gr = case_when(Mothers_age<18 ~ "AgeU18",
                                      Mothers_age>=18 & Mothers_age<25 ~ "Age1824",
                                      Mothers_age>=25 & Mothers_age<35 ~ "Age2534",
                                      Mothers_age>=35 & Mothers_age<40 ~ "Age3539",
                                      Mothers_age>=40 ~ "Age40P"))  %>%
  mutate(Mothers_age_gr=factor(Mothers_age_gr, levels = c("AgeU18", "Age1824", "Age2534", "Age3539", "Age40P"))) %>%
  mutate(Mothers_age_gr=relevel(Mothers_age_gr, ref ="Age1824")) %>%
  mutate(bord_gr = case_when(bord==1 ~ "BO1",
                             bord==2 ~ "BO2",
                             bord==3 |  bord==4 ~ "BO34",
                             bord==5 |  bord==6 ~ "BO56",
                             bord>=7 ~ "BO7P")) %>%
  mutate(bord_gr=factor(bord_gr, levels = c("BO1", "BO2", "BO34", "BO56", "BO7P"))) %>%
  mutate(bord_gr=relevel(bord_gr, ref ="BO2")) %>%
  mutate(bord_grsimp = case_when(bord==1 | bord==2  ~ "BO12",
                                 bord==3 |  bord==4 ~ "BO34",
                                 bord==5 |  bord==6 ~ "BO56",
                                 bord>=7 ~ "BO7P")) %>%
  mutate(bord_grsimp=factor(bord_grsimp, levels = c("BO12", "BO34", "BO56", "BO7P"))) %>%
  mutate(bord_grsimp=relevel(bord_grsimp, ref ="BO12")) %>%
  mutate(birthorder = case_when(bord==1 ~ "BO1",
                                bord==2 | bord==3 ~ "BO24",
                                bord>=4 ~ "BO4P"),
         spacing = case_when(b11 <24 ~ "SPU24",
                             b11>=24 & b11<=35 ~ "SP2435",
                             b11>=36 ~ "SP36P",
                             is.na(b11) ~ "SPFB"),
         matage = case_when(Mothers_age <18 ~ "MAU18",
                            Mothers_age >=18 & Mothers_age<40 ~ "MA1839",
                            Mothers_age >=40 ~ "MA40P")) %>%
  mutate(birthorder_risk=case_when(birthorder=="BO1" ~ "UnavoidFirst",
                                   birthorder=="BO4P" ~ "4P",
                                   TRUE ~ ""),
         space_risk = case_when(spacing=="SPU24" ~ "SPU24",
                                spacing=="SP2435" ~ "SP2435",
                                TRUE ~ ""),
         matage_risk = case_when(matage=="MAU18" ~ "MAU18",
                                 matage=="MA40P" ~ "MA40P",
                                 TRUE ~ "")) %>%
  mutate(birthorder_num = case_when(birthorder=="BO1" | birthorder=="BO4P" ~ 1, TRUE ~ 0),
         space_num = case_when(spacing=="SPU24" | spacing=="SP2435" ~ 1, TRUE ~ 0),
         matage_num =case_when(matage=="MAU18" |  matage=="MA40P" ~ 1, TRUE ~ 0 ),
         num_total = birthorder_num + space_num + matage_num,
         RiskNum= case_when(num_total==0 ~ "NoExtraRisk",
                            num_total==1 ~ "Single",
                            num_total==2 ~ "Double",
                            num_total==3 ~ "Triple")) %>%
  mutate(RiskGr=paste(RiskNum, birthorder_risk, space_risk, matage_risk, sep="")) %>%
  mutate(RiskGr=as.factor(RiskGr)) %>%
  mutate(RiskGr=relevel(RiskGr, ref ="NoExtraRisk"))  %>%
  mutate(RiskGR_Simple=case_when(RiskNum=="NoExtraRisk" ~ "NoExtraRisk",
                                 RiskNum== "Single" & birthorder_risk =="UnavoidFirst" ~ "UnavoidFirst",
                                 RiskNum== "Single" ~ "Single" ,
                                 RiskNum== "Double" ~ "Double" ,
                                 RiskNum== "Triple" ~ "Triple" ))  %>%
  mutate(RiskGR_Simple=as.factor(RiskGR_Simple)) %>%
  mutate(RiskGR_Simple=relevel(RiskGR_Simple, ref ="NoExtraRisk")) %>%
  mutate(Sex=case_when(b4==1 ~ "Male", 
                       b4==2 ~ "Female")) %>%
  mutate(Residence=case_when(v025==1 ~ "Urban", 
                             v025==2 ~ "Rural")) %>%
  mutate(MotherEduc=case_when(v106==0 ~ "No Education",
                              v106==1 ~ "Primary",
                              v106==2 ~ "Secondary",
                              v106==3 ~ "Higher")) %>%
  mutate(Wealth=case_when(v190==1 ~ "Poorest",
                          v190==2 ~ "Poorer",
                          v190==3 ~ "Middle",
                          v190==4 ~ "Richer",
                          v190==5 ~ "Richest")) %>%
  mutate(Refridgerator=case_when(v122 == 0 | v122==9  ~ "No",
                                 v122==1 ~ "Yes",
                                 v122==7  ~ "Missing",
                                 is.na(v122) ~ "Missing")) %>%
  mutate(Toilet=case_when(v116>=10 & v116<=19 ~ "Flush",
                          v116>=20 & v116<=29 ~ "Pit",
                          v116>=30 & v116<=36 ~ "None",
                          v116>=41 & v116<=99 ~ "Other, Missing",
                          is.na(v116)  ~ "Other, Missing")) %>%
  mutate(Water=case_when(v113>=10 & v113<=15 ~ "Piped",
                         v113>=20 & v113<=25 ~ "Open Well",
                         v113>=30 & v113<=38 ~ "Protected Well",
                         v113>=40 & v113<=47 ~ "Surface",
                         v113>=50 & v113<=52 ~ "Rain",
                         v113>=61 & v113<=63 ~ "Tanker Truck",
                         v113>=71 & v113<=73 ~ "Bottled",
                         v113>=96 & v113<=99 ~ "Other, Missing",
                         is.na(v113)  ~ "Other, Missing"))  %>%
  mutate(wanted = case_when(m10==1 ~ "Then",
                            m10==2 ~ "Later",
                            m10==3 ~ "No More",
                            TRUE ~ "Missing")) %>%
  mutate(OutPrePreg=case_when(v228==0 & bord==1 ~ "First Birth", # going to test if I can break this apart or not because of colinearity
                              PrecedingPreg=="B" ~ "Live Birth",
                              PrecedingPreg=="T" ~ "Not a Live Birth",
                              v228==0 ~ "Live Birth",
                              is.na(PrecedingPreg) ~ "Not Available",
                              PrecedingPreg==" " | PrecedingPreg=="" | PrecedingPreg=="Missing" ~ "Not Available" ))  %>%
  mutate(OutPrePreg_Simp=case_when(OutPrePreg== "First Birth" | OutPrePreg==  "Not Available" ~  "Not Available",
                                   OutPrePreg==  "Live Birth" ~  "Live Birth",
                                   OutPrePreg=="Not a Live Birth" ~ "Not a Live Birth")) %>%
  mutate(ContrFailure=case_when(Failure==1 ~ "Yes",
                                Failure==0 ~ "No",
                                Failure==99 ~ "Not Asked",
                                is.na(Failure) ~ "Not Asked")) %>%
  mutate(Tetanus= case_when(m1==0 ~ "None",
                            m1==1 ~ "One",
                            m1>=2 & m1<=7 ~ "2+",
                            m1==8 | m1==9 ~ "Missing, DK",
                            is.na(m1) ~ "Missing, DK")) %>%
  mutate(TimingAntenatal=case_when(m14==0 ~ "No Antenatal",
                                   m13==0 | m13==1 | m13==2 ~ "< 3 Months",
                                   m13==3 | m13==4 ~ "3-4 Months",
                                   m13==5 | m13==6 ~ "5-6 Months",
                                   m13==7 | m13==8 ~ "7-8 Months",
                                   m13==9 | m13==10 | m13==11 ~ "9 Months",
                                   m13==98 | m13==99 ~ "Missing, DK",
                                   is.na(m13) ~ "No Antenatal")) %>%
  mutate(Provider_Prenatalsimp=case_when(m2a==1 ~ "Doctor",
                                         m2b==1 ~ "Nurse/Midwife",
                                         m2c==1 ~ "Nurse/Midwife",
                                         m2d==1 ~ "Other Medical",
                                         m2e==1 ~ "Other Medical",
                                         m2f==1 ~ "Other Medical",
                                         m2g==1 ~ "TBA",
                                         m2h==1 ~ "Other Person",
                                         m2i==1 ~ "Other Person",
                                         m2j==1 ~ "Other Person",
                                         m2k==1 ~ "Other Person",
                                         m2l==1 ~ "Other Person",
                                         m2m==1 ~ "Other Person",
                                         m2n==1 ~ "No One",
                                         TRUE ~ "Other Person")) %>%
  mutate(Provider_Deliverysimp=case_when(m3a==1 ~ "Doctor",
                                         m3b==1 ~ "Nurse/Midwife",
                                         m3c==1 ~ "Nurse/Midwife",
                                         m3d==1 ~ "Other Medical",
                                         m3e==1 ~ "Other Medical",
                                         m3f==1 ~ "Other Medical",
                                         m3g==1 ~ "TBA",
                                         m3h==1 ~ "Other Person",
                                         m3i==1 ~ "Other Person",
                                         m3j==1 ~ "Other Person",
                                         m3k==1 ~ "Other Person",
                                         m3l==1 ~ "Other Person",
                                         m3m==1 ~ "Other Person",
                                         m3n==1 ~ "No One",
                                         TRUE ~ "Other Person")) %>%
  left_join(new_olderchild, by=c("caseid", "v000", "v005", "v007", "v008",  "bord")) %>%
  mutate(survival_preceding =  case_when(is.na(sub_cmc_death) ~ "Did Not Die",
                                         sub_cmc_death <= cmc_conception ~ "Preceding Died",
                                         sub_cmc_death > cmc_conception ~  "Did Not Die") )  %>% 
  mutate(exneonatal_time=case_when(b6 <=106 ~ b6 - 100,
                                   b6 >106 ~ 6,
                                   is.na(b6) ~ 6),
         exneonatal_status=case_when(b6 <=106 ~ 2,
                                     b6 >106 ~ 1,
                                     is.na(b6) ~ 1))  %>% 
  mutate(neonatal_time=case_when(b6 <=130 ~ b6 - 100,
                                 b6 >130 ~ 30,
                                 is.na(b6) ~ 30),
         neonatal_status=case_when(b6 <=130 ~ 2,
                                   b6 >130 ~ 1,
                                   is.na(b6) ~ 1)) %>%
  mutate(postneonatal_time=case_when(b7 < 12 ~ b7,
                                     b7>=12 ~ 12,
                                     is.na(b7) ~ 12),
         postneonatal_status=case_when(b7 ==0 ~ 1,
                                       b7 >=1 & b7<=11 ~ 2,
                                       b7>=12 ~ 1,
                                       is.na(b7) ~ 1)) %>%
  mutate(infant_time=case_when(b7 < 12 ~ b7,
                               b7>=12 ~ 12,
                               is.na(b7) ~ 12),
         infant_status=case_when(b7 >=0 & b7<=11 ~ 2,
                                 b7>=12 ~ 1,
                                 is.na(b7) ~ 1)) %>%
  mutate(child_time=case_when(b7 < 60 ~ b7,
                              b7>=60 ~ 60,
                              is.na(b7) ~ 60),
         child_status=case_when(b7 < 12 ~ 1, # censored
                                b7 >=12 & b7<=59 ~ 2,
                                b7>=60 ~ 1,
                                is.na(b7) ~ 1)) %>%
  mutate(under5_time=case_when(b7 < 60 ~ b7,
                               b7>=60 ~ 60,
                               is.na(b7) ~ 60),
         under5_status=case_when(b7 >=0 & b7<=59 ~ 2,
                                 b7>=60 ~ 1,
                                 is.na(b7) ~ 1)) %>%
  mutate(Country=substr(v000, start = 1, stop = 2))



# # # # # # # # #  # # # # #  # # # #  # # # #  # # # # # # 
# Only including singletons

new_births_clean179 <- new_births_clean %>% filter(timesince <= 179)    %>% filter(b0==0)
new_births_clean59 <- new_births_clean %>% filter(timesince <= 59)  %>% filter(b0==0)

new_births_cleannon_first <- new_births_clean179 %>% filter(interval!="FirstBorn")
# # # # # # # # #  # # # # #  # # # #  # # # #  # # # # # # 

new_birth_intervals <-    as.data.frame(prop.table(table( new_births_clean179$interval ))) %>%
  mutate(Survey="Total") %>%  spread(Var1, Freq)

new_bc_mean <- as.data.frame(mean(new_births_cleannon_first$birth_conce)) %>% rename(bc_mean=1)  %>% mutate(Survey="Total") 
new_bc_median <- as.data.frame(median(new_births_cleannon_first$birth_conce, na.rm = TRUE))  %>% rename(bc_median=1)  %>% mutate(Survey="Total") 

new_birth_n <-    as.data.frame(table( new_births_clean179$interval)) %>% summarise(N=sum(Freq)) %>% mutate(Survey="Total") 

new_births_df <- full_join(new_birth_intervals,  new_bc_mean,  by="Survey") %>% full_join(new_bc_median, by="Survey")   %>% full_join(new_birth_n, by="Survey") %>% 
  rename(Country=Survey) %>%   select(Country, Under6, M6to11, M12to17, M18to23, M24to29, M30to35, M36to47, M48to59, M60to95, M96P, FirstBorn, bc_mean, bc_median,  N )

birth_intervals_clean_total <- bind_rows(birth_intervals_clean, new_births_df) %>%
  mutate(Under6=round(Under6*100,1), 
         M6to11=round(M6to11*100,1), 
         M12to17=round(M12to17*100,1), 
         M18to23 =round(M18to23*100,1), 
         M24to29 =round(M24to29*100,1), 
         M30to35=round(M30to35*100,1), 
         M36to47 =round(M36to47*100,1), 
         M48to59=round(M48to59*100,1), 
         M60to95=round(M60to95*100,1), 
         M96P=round(M96P*100,1),
         FirstBorn=round(FirstBorn*100,1),
         bc_mean=round(bc_mean,1),
         bc_median=round(bc_median,1),
         N=comma(N)) %>%
  rename(Year=FullYear, "<6"=Under6, "6-11"=M6to11, "12-17"=M12to17, "18-23"=M18to23, "24-29"=M24to29, "30-35"=M30to35, "36-47"=M36to47,
         "48-59"=M48to59, "60-95"=M60to95, "96+"=M96P, "First Births"=FirstBorn, Mean=bc_mean, Median=bc_median)

header2a <- c("Table 2. Distribution of births 0 to 179 months prior to survey by duration of preceding birth to conception interval, 84 DHS surveys, 2012 to 2022", "")
header2b <- c("", "Preceding birth to conception interval in months (%)")
header2c <- c("", "")

header2 <- data.frame(header2a, header2c, header2b)

footer2 <- c("Note: Percent distributions are based on weighted cases for all individual countries. The total percent distribution, however, is based on unweighted cases, because the application of standard individual country weights is not meaningful in the pooled sample and analyses using the pooled data are unweighted.")
footer2 <- data.frame(footer2)

#write.table(header2, file =  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by Duration of Preceding Birth to Conception Interval.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(birth_intervals_clean_total,  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by Duration of Preceding Birth to Conception Interval.csv" ,sep=",",  na="", append=TRUE, row.names=FALSE, col.names = TRUE)
#write.table(footer2,  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by Duration of Preceding Birth to Conception Interval.csv" ,sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)

# # # # # # # # #  # # # # #  # # # #  # # # #  # # # # # # 
new_birth_agegr <-    as.data.frame(prop.table(table( new_births_clean179$Mothers_age_gr )))  %>% 
  spread(Var1, Freq) %>% mutate(Survey="Total") 

new_age_mean <- as.data.frame(mean(new_births_clean179$Mothers_age)) %>% rename(age_mean=1)  %>% mutate(Survey="Total") 
new_age_median <- as.data.frame(median(new_births_clean179$Mothers_age, na.rm = TRUE))  %>% rename(age_median=1)  %>% mutate(Survey="Total") 

new_age_n <-    as.data.frame(table( new_births_clean179$Mothers_age_gr)) %>% summarise(N=sum(Freq)) %>% mutate(Survey="Total") 

new_age_atbirth_df <- full_join(new_birth_agegr,  new_age_mean,  by="Survey") %>%
  full_join(new_age_median, by="Survey") %>% full_join(new_age_n, by="Survey")  %>% 
  rename(Country=Survey)  %>% 
  select(Country,  AgeU18, Age1824, Age2534, Age3539, Age40P, age_mean, age_median,  N )

age_at_birth_clean_total <- bind_rows(birth_age_clean, new_age_atbirth_df) %>%
  mutate(AgeU18=round(AgeU18*100,1), 
         Age1824=round(Age1824*100,1), 
         Age2534=round(Age2534*100,1), 
         Age3539 =round(Age3539*100,1), 
         Age40P =round(Age40P*100,1), 
         age_mean=round(age_mean,1),
         age_median=round(age_median,1),
         N=comma(N)) %>%
  rename(Year=FullYear, "<18"=AgeU18,"18-24"=Age1824,"25-34"=Age2534,"35-39"=Age3539,"40+"=Age40P, Mean=age_mean, Median=age_median)



header3a <- c("Table 3. Distribution of births 0 to 179 months prior to survey by the mother's age at child's birth, 84 DHS surveys, 2012 to 2022", "", "" )
header3b <- c("", "",  "Mother's age at child's birth in years (%)")
header3c <- c("","", "")

header3 <- data.frame(header3a, header3c, header3b)

footer3 <- c("Note: Percent distributions are based on weighted cases for all individual countries. The total percent distribution, however, is based on unweighted cases, because the application of standard individual country weights is not meaningful in the pooled sample and analyses using the pooled data are unweighted.")
footer3 <- data.frame(footer3)

#write.table(header3, file =  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by Mothers Age at Childs Birth.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(age_at_birth_clean_total,  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by Mothers Age at Childs Birth.csv" ,sep=",",  na="", append=TRUE, row.names=FALSE, col.names = TRUE)
#write.table(footer3, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by Mothers Age at Childs Birth.csv" ,sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)

# # # # # # # # # # # # # # #  # # # # # # # # # # # # # 
new_birth_bordgr <-    as.data.frame(prop.table(table( new_births_clean179$bord_gr )))  %>% 
  spread(Var1, Freq) %>% mutate(Survey="Total") 

new_bord_mean <- as.data.frame(mean(new_births_clean179$bord)) %>% rename(bord_mean=1)  %>% mutate(Survey="Total") 
new_bord_median <- as.data.frame(median(new_births_clean179$bord, na.rm = TRUE))  %>% rename(bord_median=1)  %>% mutate(Survey="Total") 

new_bord_n <-    as.data.frame(table( new_births_clean179$bord_gr)) %>% summarise(N=sum(Freq)) %>% mutate(Survey="Total") 

new_bord_df <- full_join(new_birth_bordgr,  new_bord_mean,  by="Survey") %>%
  full_join(new_bord_median, by="Survey") %>% full_join(new_bord_n, by="Survey")  %>% 
  rename(Country=Survey)  %>% 
  select(Country,  BO1, BO2, BO34, BO56, BO7P, bord_mean, bord_median,  N)

BirthOrder_table <- bind_rows(birth_order_clean, new_bord_df) %>%
  mutate(BO1=round(BO1*100,1), 
         BO2=round(BO2*100,1), 
         BO34=round(BO34*100,1), 
         BO56 =round(BO56*100,1), 
         BO7P =round(BO7P*100,1), 
         bord_mean=round(bord_mean,1),
         bord_median=round(bord_median,1),
         N=comma(N)) %>%
  rename(Year=FullYear, "1"=BO1,"2"=BO2,"3-4"=BO34,"5-6"=BO56,"7+"=BO7P, Mean=bord_mean, Median=bord_median)

header4a <- c("Table 4. Distribution of births 0 to 179 months prior to survey by child's birth order, 84 DHS surveys, 2012 to 2022", "", "" )
header4b <- c("", "",  "Birth order (%)")
header4c <- c("","", "")

header4 <- data.frame(header4a, header4c, header4b)

footer4 <- c("Note: Percent distributions are based on weighted cases for all individual countries. The total percent distribution, however, is based on unweighted cases, because the application of standard individual country weights is not meaningful in the pooled sample and analyses using the pooled data are unweighted.")
footer4 <- data.frame(footer4)

#write.table(header4, file = "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by Childs Birth Order.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(BirthOrder_table, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by Childs Birth Order.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = TRUE)
#write.table(footer4, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by Childs Birth Order.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)

# # # # # # # # # # # # # # #  # # # # # # # # # # # # # 
birth_riskfull_gr <-    as.data.frame(prop.table(table( new_births_clean179$RiskGr )))  %>% 
  spread(Var1, Freq) %>% mutate(Survey="Total") 

new_riskfull_n <-    as.data.frame(table( new_births_clean179$RiskGr)) %>% summarise(N=sum(Freq)) %>% mutate(Survey="Total") 

new_riskfull_df <- full_join(birth_riskfull_gr,  new_riskfull_n,  by="Survey") %>%
  rename(Country=Survey)  %>% 
  select(Country ,   NoExtraRisk , SingleUnavoidFirst ,
         SingleSPU24,      SingleSP2435,    SingleMAU18 ,   SingleMA40P,  Single4P  ,
         Double4PSPU24,   Double4PSP2435 , DoubleUnavoidFirstMAU18 , DoubleUnavoidFirstMA40P ,    Double4PMAU18 , Double4PMA40P,   
         DoubleSPU24MAU18, DoubleSP2435MAU18, DoubleSPU24MA40P , DoubleSP2435MA40P ,     
         Triple4PSPU24MAU18 ,  Triple4PSPU24MA40P, Triple4PSP2435MAU18 , Triple4PSP2435MA40P , N )


BirthRiskFull_table <- bind_rows(birth_riskfull_clean, new_riskfull_df)  %>%
  replace(is.na(.), 0) %>% 
  mutate(FullYear=case_when(Country=="Total" ~ "",
                            Country!="Total" ~ FullYear)) %>%
  mutate(NoExtraRisk=round(NoExtraRisk*100,1), 
         SingleUnavoidFirst =round(SingleUnavoidFirst*100,1),
         SingleSPU24=round(SingleSPU24*100,1), 
         SingleSP2435=round(SingleSP2435*100,1),
         SingleMAU18 =round(SingleMAU18*100,1), 
         SingleMA40P=round(SingleMA40P*100,1),
         Single4P =round(Single4P*100,1), 
         Double4PSPU24=round(Double4PSPU24*100,1),
         Double4PSP2435=round(Double4PSP2435*100,1), 
         DoubleUnavoidFirstMAU18=round(DoubleUnavoidFirstMAU18*100,1),
         DoubleUnavoidFirstMA40P=round(DoubleUnavoidFirstMA40P*100,1), 
         Double4PMAU18=round(Double4PMAU18*100,1),
         Double4PMA40P =round(Double4PMA40P*100,1), 
         DoubleSPU24MAU18=round(DoubleSPU24MAU18*100,1),
         DoubleSP2435MAU18=round(DoubleSP2435MAU18*100,1), 
         DoubleSPU24MA40P=round(DoubleSPU24MA40P*100,1),
         DoubleSP2435MA40P=round(DoubleSP2435MA40P*100,1), 
         Triple4PSPU24MAU18=round(Triple4PSPU24MAU18*100,1),
         Triple4PSPU24MA40P=round(Triple4PSPU24MA40P*100,1), 
         Triple4PSP2435MAU18=round(Triple4PSP2435MAU18*100,1),
         Triple4PSP2435MA40P=round(Triple4PSP2435MA40P*100,1), 
         N=comma(N)) %>%
  rename(Year=FullYear, "No Extra Risk"= NoExtraRisk , "Unaviodable First Birth Risk"=SingleUnavoidFirst ,
         "Single Risk Spacing <24 mos"=SingleSPU24,    "Single Risk Spacing 24-35 mos"=  SingleSP2435, "Single Risk Age <18"=   SingleMAU18 ,  "Single Risk Age 40+"= SingleMA40P, "Single Risk Order 4+"= Single4P  ,
         "Double Risk Spacing <24 mos, Order 4+"= Double4PSPU24,  "Double Risk Spacing 24-35 mos, Order 4+"= Double4PSP2435 , "Double Risk First Birth, Age <18"=DoubleUnavoidFirstMAU18 ,
         "Double Risk First Birth, Age 40+"=DoubleUnavoidFirstMA40P ,  "Double Risk Order 4+, Age <18"=  Double4PMAU18 , "Double Risk Order 4+, Age 40+"=Double4PMA40P,   
         "Double Risk Spacing <24 mos, Age <18"=DoubleSPU24MAU18, "Double Risk Spacing 24-35 mos, Age <18"=DoubleSP2435MAU18, "Double Risk Spacing <24 mos, Age 40+"=DoubleSPU24MA40P , 
         "Double Risk Spacing 24-35 mos, Age 40+"=DoubleSP2435MA40P ,     
         "3-Way Risk Spacing <24 mos, Order 4+, Age <18"=Triple4PSPU24MAU18 ,  "3-Way Risk Spacing <24 mos, Order 4+, Age 40+"=Triple4PSPU24MA40P, 
         "3-Way Risk Spacing 24-35 mos, Order 4+, Age <18"= Triple4PSP2435MAU18 , "3-Way Risk Spacing 24-35, Order 4+, Age 40+"= Triple4PSP2435MA40P )

#write.csv(BirthRiskFull_table, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by maternal fertility related risk factors.csv", row.names = F, na="")

header5a <- c("Table 5. Distribution of births 0 to 179 months prior to survey by maternal fertility related risk factors, 84 DHS surveys, 2012 to 2022", "", "" )
header5b <- c("", "",  "Extra risk due to fertility pattern (%)")
header5c <- c("","", "")

header5 <- data.frame(header5a, header5c, header5b)

footer5 <- c("Note: Percent distributions are based on weighted cases for all individual countries. The total percent distribution, however, is based on unweighted cases, because the application of standard individual country weights is not meaningful in the pooled sample and analyses using the pooled data are unweighted.")
footer5 <- data.frame(footer5)

#write.table(header5, file = "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by maternal fertility related risk factors.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(BirthRiskFull_table, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by maternal fertility related risk factors.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = TRUE)
#write.table(footer5, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by maternal fertility related risk factors.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)




# # # # # # # # # # # # # # #  # # # # # # # # # # # # # 
birth_risksimp_gr <-    as.data.frame(prop.table(table( new_births_clean179$RiskGR_Simple )))  %>% 
  spread(Var1, Freq) %>% mutate(Survey="Total") 

new_risksimp_n <-    as.data.frame(table( new_births_clean179$RiskGR_Simple)) %>% summarise(N=sum(Freq)) %>% mutate(Survey="Total") 

new_risksimp_df <- full_join(birth_risksimp_gr,  new_risksimp_n,  by="Survey") %>%
  rename(Country=Survey) %>%
  select(Country,  NoExtraRisk, UnavoidFirst, Single, Double, Triple, N)

BirthRiskSimp_table <- bind_rows(birth_risksimp_clean, new_risksimp_df) %>%
  mutate(NoExtraRisk=round(NoExtraRisk*100,1), 
         UnavoidFirst =round(UnavoidFirst*100,1),
         Single=round(Single*100,1), 
         Double=round(Double*100,1),
         Triple =round(Triple*100,1), 
         N=comma(N)) %>%
  rename(Year=FullYear, "No Extra Risk"= NoExtraRisk , 
         "Unaviodable First Birth Risk"=UnavoidFirst , "Any Single Risk"=Single , "Any Double Risk"=Double , "Any 3-Way Risk"=Triple )


header6a <- c("Table 6. Distribution of births 0 to 179 months prior to survey by maternal fertility related risk factors, 84 DHS surveys, 2012 to 2022", "", "" )
header6b <- c("", "",  "Summary Measure of Extra Risk (%)")
header6c <- c("","", "")

header6 <- data.frame(header6a, header6c, header6b)

footer6 <- c("Note: Percent distributions are based on weighted cases for all individual countries. The total percent distribution, however, is based on unweighted cases, because the application of standard individual country weights is not meaningful in the pooled sample and analyses using the pooled data are unweighted.")
footer6 <- data.frame(footer6)

#write.table(header6, file =  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by maternal fertility related risk factors Summary.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(BirthRiskSimp_table,  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by maternal fertility related risk factors Summary.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = TRUE)
#write.table(footer6,  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of Births 0 to 179 Months Prior to Survey by maternal fertility related risk factors Summary.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)


################################################################################################################################
surveybreakdown <- as.data.frame(table(new_births_clean179$Country)) %>% mutate(Variable="Country", month=179)

################################################################################################################################

# Control Variables
Sex_179 <- as.data.frame(table(new_births_clean179$Sex)) %>% mutate(Variable="Sex", month=179)
Sex_59 <- as.data.frame(table(new_births_clean59$Sex)) %>% mutate(Variable="Sex", month=59)

Residence_179 <- as.data.frame(table(new_births_clean179$Residence)) %>% mutate(Variable="Residence", month=179)
Residence_59 <- as.data.frame(table(new_births_clean59$Residence)) %>% mutate(Variable="Residence", month=59)

MotherEduc_179 <- as.data.frame(table(new_births_clean179$MotherEduc)) %>% mutate(Variable="MotherEduc", month=179)
MotherEduc_59 <- as.data.frame(table(new_births_clean59$MotherEduc)) %>% mutate(Variable="MotherEduc", month=59)

Wealth_179 <- as.data.frame(table(new_births_clean179$Wealth)) %>% mutate(Variable="Wealth", month=179)
Wealth_59 <- as.data.frame(table(new_births_clean59$Wealth)) %>% mutate(Variable="Wealth", month=59)

Refridgerator_179 <- as.data.frame(table(new_births_clean179$Refridgerator)) %>% mutate(Variable="Refridgerator", month=179)
Refridgerator_59 <- as.data.frame(table(new_births_clean59$Refridgerator)) %>% mutate(Variable="Refridgerator", month=59)

Toilet_179 <- as.data.frame(table(new_births_clean179$Toilet)) %>% mutate(Variable="Toilet", month=179)
Toilet_59 <- as.data.frame(table(new_births_clean59$Toilet)) %>% mutate(Variable="Toilet", month=59)

Water_179 <- as.data.frame(table(new_births_clean179$Water)) %>% mutate(Variable="Water", month=179)
Water_59 <- as.data.frame(table(new_births_clean59$Water)) %>% mutate(Variable="Water", month=59)

Gestation_179 <- as.data.frame(table(new_births_clean179$Gestation)) %>% mutate(Variable="Gestation", month=179)
Gestation_59 <- as.data.frame(table(new_births_clean59$Gestation)) %>% mutate(Variable="Gestation", month=59)

survival_preceding_179 <- as.data.frame(table(new_births_clean179$survival_preceding)) %>% mutate(Variable="survival_preceding", month=179)
survival_preceding_59 <- as.data.frame(table(new_births_clean59$survival_preceding)) %>% mutate(Variable="survival_preceding", month=59)

OutPrePreg_Simp_59 <- as.data.frame(table(new_births_clean59$OutPrePreg_Simp)) %>% mutate(Variable="OutPrePreg", month=59)

wanted_59 <- as.data.frame(table(new_births_clean59$wanted)) %>% mutate(Variable="wanted", month=59)

ContrFailure_59 <- as.data.frame(table(new_births_clean59$ContrFailure)) %>% mutate(Variable="ContrFailure", month=59)

Provider_Prenatal_59 <- as.data.frame(table(new_births_clean59$Provider_Prenatalsimp)) %>% mutate(Variable="Provider_Prenatal", month=59)

Provider_Delivery_59 <- as.data.frame(table(new_births_clean59$Provider_Deliverysimp)) %>% mutate(Variable="Provider_Delivery", month=59)

Tetanus_59 <- as.data.frame(table(new_births_clean59$Tetanus)) %>% mutate(Variable="Tetanus", month=59)

TimingAntenatal_59 <- as.data.frame(table(new_births_clean59$TimingAntenatal)) %>% mutate(Variable="TimingAntenatal", month=59)

annex_179 <- bind_rows(Sex_179, Residence_179, MotherEduc_179, Wealth_179, Refridgerator_179, Toilet_179, Water_179, Gestation_179, survival_preceding_179) %>% 
  group_by(Variable) %>% mutate(Percent= (Freq/sum(Freq))*100) %>% rename(Freq_179=Freq, Percent_179=Percent) %>% select(-month)
annex_59 <- bind_rows(Sex_59, Residence_59, MotherEduc_59, Wealth_59, Refridgerator_59, Toilet_59, Water_59, Gestation_59, survival_preceding_59, 
                      OutPrePreg_Simp_59, wanted_59, ContrFailure_59, Provider_Prenatal_59, Provider_Delivery_59, Tetanus_59, TimingAntenatal_59) %>% 
  group_by(Variable) %>% mutate(Percent= (Freq/sum(Freq))*100) %>% rename(Freq_59=Freq, Percent_59=Percent) %>% select(-month)

Var1 <- c("Sex of Index Child", "Type of Place of Residence", "Mother's Highest Educational Level", "Wealth Index Quintiles", "Household Has Refigerator", "Type of Toilet/Latrine",
                 "Source of Drinking Water", "Length of Gestation (Months)", "Survival of Preceding Child", "Additional control variables included in models predicting early neonatal, neonatal, post-neonatal, and infant mortality",
                 "Outcome of Preceding Pregnancy", "Time Wanted Pregnancy", "Pregnancy was Result of Contraceptive Failure", "Prental Care Provider", "Delivery Care Provider", "Prenatal Tetanus Injections", "Timing of First Antenatal Check")
blank_annex <- data.frame(Var1) %>% mutate(Variable="", Percent_179=NA, Freq_179=NA, Percent_59=NA, Freq_59=NA)

Annex <- full_join(annex_179, annex_59, by=c("Variable", "Var1")) %>% select(Variable, Var1, Percent_179, Freq_179, Percent_59, Freq_59) %>%
  mutate(Percent_179=round(Percent_179,1),
         Percent_59=round(Percent_59,1),
         Freq_179=comma(Freq_179),
         Freq_59=comma(Freq_59)) %>%
  bind_rows(blank_annex) %>%
  mutate(Order=case_when(Variable=="" & Var1=="Sex of Index Child" ~1,
                         Variable=="Sex" & Var1=="Male" ~2,
                         Variable=="Sex" & Var1=="Female" ~3,
                         Variable=="" & Var1=="Type of Place of Residence" ~4,
                         Variable=="Residence" & Var1=="Urban" ~5,
                         Variable=="Residence" & Var1=="Rural" ~6,
                         Variable=="" & Var1=="Mother's Highest Educational Level" ~7,
                         Variable=="MotherEduc" & Var1=="No Education" ~8,
                         Variable=="MotherEduc" & Var1=="Primary" ~9,
                         Variable=="MotherEduc" & Var1=="Secondary" ~10,
                         Variable=="MotherEduc" & Var1=="Higher" ~11,
                         Variable=="" & Var1=="Wealth Index Quintiles" ~12,
                         Variable=="Wealth" & Var1=="Poorest" ~13,
                         Variable=="Wealth" & Var1=="Poorer" ~14,
                         Variable=="Wealth" & Var1=="Middle" ~15,
                         Variable=="Wealth" & Var1=="Richer" ~16,
                         Variable=="Wealth" & Var1=="Richest" ~17,
                         Variable=="" & Var1=="Household Has Refigerator" ~18,
                         Variable=="Refridgerator" & Var1=="Yes" ~19,
                         Variable=="Refridgerator" & Var1=="No" ~20,
                         Variable=="Refridgerator" & Var1=="Missing" ~21,
                         Variable=="" & Var1=="Type of Toilet/Latrine" ~22,
                         Variable=="Toilet" & Var1=="Flush" ~23,
                         Variable=="Toilet" & Var1=="Pit" ~24,
                         Variable=="Toilet" & Var1=="None" ~25,
                         Variable=="Toilet" & Var1=="Other, Missing" ~26,
                         Variable=="" & Var1=="Source of Drinking Water" ~27,
                         Variable=="Water" & Var1=="Piped" ~28,
                         Variable=="Water" & Var1=="Open Well" ~29,
                         Variable=="Water" & Var1=="Protected Well" ~30,
                         Variable=="Water" & Var1=="Surface" ~31,
                         Variable=="Water" & Var1=="Rain" ~32,
                         Variable=="Water" & Var1=="Tanker Truck" ~33,
                         Variable=="Water" & Var1=="Bottled" ~34,
                         Variable=="Water" & Var1=="Other, Missing" ~35,
                         Variable=="" & Var1=="Length of Gestation (Months)" ~36,
                         Variable=="Gestation" & Var1=="7" ~37,
                         Variable=="Gestation" & Var1=="8" ~38,
                         Variable=="Gestation" & Var1=="9" ~39,
                         Variable=="Gestation" & Var1=="10" ~40,
                         Variable=="" & Var1=="Survival of Preceding Child" ~41,
                         Variable=="survival_preceding" & Var1=="Did Not Die" ~42,
                         Variable=="survival_preceding" & Var1=="Preceding Died" ~43,
                         Variable=="" & Var1=="Additional control variables included in models predicting early neonatal, neonatal, post-neonatal, and infant mortality" ~44,
                         Variable=="" & Var1=="Outcome of Preceding Pregnancy" ~45,
                         Variable=="OutPrePreg" & Var1=="Live Birth" ~46,
                         Variable=="OutPrePreg" & Var1=="Not a Live Birth" ~47,
                         Variable=="OutPrePreg" & Var1=="Not Available" ~48,
                         Variable=="" & Var1=="Time Wanted Pregnancy" ~49,
                         Variable=="wanted" & Var1=="Then" ~50,
                         Variable=="wanted" & Var1=="Later" ~51,
                         Variable=="wanted" & Var1=="No More" ~52,
                         Variable=="wanted" & Var1=="Missing" ~53,
                         Variable=="" & Var1=="Pregnancy was Result of Contraceptive Failure" ~54,
                         Variable=="ContrFailure" & Var1=="Yes" ~55,
                         Variable=="ContrFailure" & Var1=="No" ~56,
                         Variable=="ContrFailure" & Var1=="Not Asked" ~57,
                         Variable=="" & Var1=="Prental Care Provider" ~58,
                         Variable=="Provider_Prenatal" & Var1=="Doctor" ~59,
                         Variable=="Provider_Prenatal" & Var1=="Nurse/Midwife" ~60,
                         Variable=="Provider_Prenatal" & Var1=="Other Medical" ~61,
                         Variable=="Provider_Prenatal" & Var1=="TBA" ~62,
                         Variable=="Provider_Prenatal" & Var1=="Other Person" ~63,
                         Variable=="Provider_Prenatal" & Var1=="No One" ~64,
                         Variable=="" & Var1=="Delivery Care Provider" ~65,
                         Variable=="Provider_Delivery" & Var1=="Doctor" ~66,
                         Variable=="Provider_Delivery" & Var1=="Nurse/Midwife" ~67,
                         Variable=="Provider_Delivery" & Var1=="Other Medical" ~68,
                         Variable=="Provider_Delivery" & Var1=="TBA" ~69,
                         Variable=="Provider_Delivery" & Var1=="Other Person" ~70,
                         Variable=="Provider_Delivery" & Var1=="No One" ~71,
                         Variable=="" & Var1=="Prenatal Tetanus Injections" ~72,
                         Variable=="Tetanus" & Var1=="None" ~73,
                         Variable=="Tetanus" & Var1=="One" ~74,
                         Variable=="Tetanus" & Var1=="2+" ~75,
                         Variable=="Tetanus" & Var1=="Missing, DK" ~76,
                         Variable=="" & Var1=="Timing of First Antenatal Check" ~77,
                         Variable=="TimingAntenatal" & Var1=="No Antenatal" ~78,
                         Variable=="TimingAntenatal" & Var1=="< 3 Months" ~79,
                         Variable=="TimingAntenatal" & Var1=="3-4 Months" ~80,
                         Variable=="TimingAntenatal" & Var1=="5-6 Months" ~81,
                         Variable=="TimingAntenatal" & Var1=="7-8 Months" ~82,
                         Variable=="TimingAntenatal" & Var1=="9 Months" ~83,
                         Variable=="TimingAntenatal" & Var1=="Missing, DK" ~84)) %>% arrange(Order) %>% ungroup() %>% select(-Variable, -Order) %>% rename("Control Variable"=Var1)
  

headerAa <- c("Appendix Table A1. Appendix Table A1. Distribution of births 0 to 179 months and 0 to 59 months prior to survey by control variables used in multivariate analyses, 84 DHS surveys, 2012 to 2022", "" , "")
headerAb <- c("", "Births 0 to 179 monhs prior to the survey", "Percent")
headerAc <- c("", "Births 0 to 59 monhs prior to the survey", "Percent")
headerAd <- c("", "", "Frequency")
headerAe <- c("", "", "Frequency")

headerA <- data.frame(headerAa, headerAb, headerAd, headerAc, headerAe)

footerA <- c("Note: Distributions and percentages are based on unweighted cases, since the application of standard individual country weights is not meaningful in the merged sample.")
footerA <- data.frame(footerA)

#write.table(headerA, file =  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of births 0 to 179 months and 0 to 59 months prior to survey by control variables used in multivariate analyses.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(Annex,  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of births 0 to 179 months and 0 to 59 months prior to survey by control variables used in multivariate analyses.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)
#write.table(footerA,  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Distribution of births 0 to 179 months and 0 to 59 months prior to survey by control variables used in multivariate analyses.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)


################################################################################################################################

# Unadjusted Odds Ratios
# In AS37: The 95 percent confidence interval of the relative risk ratio is calculated by adding or subtracting 1.96 times the summary standard error from the coefficient before exponentiation.
# Now can do that with the survival package 


ExpCoef <- c(1)
LCI <- c(NA)
UCI <- c(NA)

Variable <- c("M3647 (ref)")
reference_interval <- data.frame( Variable, ExpCoef, LCI, UCI)
Variable <- c("Age1824 (ref)")
reference_age <- data.frame( Variable, ExpCoef, LCI, UCI)
Variable <- c("BO2 (ref)")
reference_bord <- data.frame( Variable, ExpCoef, LCI, UCI)
Variable <- c("BO12 (ref)")
reference_bordsimp <- data.frame( Variable, ExpCoef, LCI, UCI)
Variable <- c("NoExtraRisk (ref)")
reference_risk <- data.frame( Variable, ExpCoef, LCI, UCI)

# # # # # # # # # # # # # # # # # # # # # # # # # # # 
exneo_interval <- summary(coxph(Surv(exneonatal_time, exneonatal_status) ~ as.factor(interval), data = new_births_clean59))

exneo_interval_n <- as.data.frame(exneo_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

exneo_interval_exp <- as.data.frame(exneo_interval$conf.int)  %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5)  %>% select(Variable, ExpCoef, LCI, UCI) %>%
  bind_rows(reference_interval) %>% 
  bind_rows(exneo_interval_n) %>%
  rename(EarlyNeonatal_uRR=ExpCoef, EarlyNeonatal_LCI=LCI, EarlyNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
neo_interval <- summary(coxph(Surv(neonatal_time, neonatal_status) ~ as.factor(interval), data = new_births_clean59))

neo_interval_n <- as.data.frame(neo_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

neo_interval_exp <- as.data.frame(neo_interval$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_interval) %>% 
  bind_rows(neo_interval_n) %>%
  rename(Neonatal_uRR=ExpCoef, Neonatal_LCI=LCI, Neonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
postneo_interval <- summary(coxph(Surv(postneonatal_time, postneonatal_status) ~ as.factor(interval), data = new_births_clean59))

postneo_interval_n <- as.data.frame(postneo_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

postneo_interval_exp <- as.data.frame(postneo_interval$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_interval) %>% 
  bind_rows(postneo_interval_n) %>%
  rename(PostNeonatal_uRR=ExpCoef, PostNeonatal_LCI=LCI, PostNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
infant_interval <- summary(coxph(Surv(infant_time, infant_status) ~ as.factor(interval), data = new_births_clean59))

infant_interval_n <- as.data.frame(infant_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

infant_interval_exp <- as.data.frame(infant_interval$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_interval) %>% 
  bind_rows(infant_interval_n) %>%
  rename(Infant_uRR=ExpCoef, Infant_LCI=LCI, Infant_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
child_interval <- summary(coxph(Surv(child_time, child_status) ~ as.factor(interval), data = new_births_clean179))

child_interval_n <- as.data.frame(child_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

child_interval_exp <- as.data.frame(child_interval$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select( Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_interval) %>% 
  bind_rows(child_interval_n) %>%
  rename(Child_uRR=ExpCoef, Child_LCI=LCI, Child_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
under5_interval <- summary(coxph(Surv(under5_time, under5_status) ~ as.factor(interval), data = new_births_clean179))

under5_interval_n <- as.data.frame(under5_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

under5_interval_exp <- as.data.frame(under5_interval$conf.int) %>%  
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_interval) %>% 
  bind_rows(under5_interval_n) %>%
  rename(Under5_uRR=ExpCoef, Under5_LCI=LCI, Under5_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
Interval_Results <- full_join(exneo_interval_exp, neo_interval_exp, by="Variable") %>%
  full_join(postneo_interval_exp, by="Variable") %>%
  full_join(infant_interval_exp, by="Variable") %>%
  full_join(child_interval_exp, by="Variable") %>%
  full_join(under5_interval_exp, by="Variable") %>% 
  mutate(order=case_when(Variable== "Under6" ~ 1,
                         Variable== "M6to11"   ~ 2,
                         Variable=="M12to17"  ~ 3,
                         Variable== "M18to23" ~ 4,
                         Variable=="M24to29"  ~ 5,
                         Variable== "M30to35" ~ 6,
                         Variable=="M3647 (ref)" ~ 7,
                         Variable=="M48to59" ~ 8,
                         Variable=="M60to95" ~ 9,
                         Variable== "M96P"  ~ 10,
                         Variable== "FirstBorn" ~ 11,
                         Variable== "Total N"   ~ 12)) %>%
  arrange(order) %>% select(-order)



levels(as.factor(Interval_Results$Variable))
##################################################################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # 
exneo_Mothers_age <- summary(coxph(Surv(exneonatal_time, exneonatal_status) ~ as.factor(Mothers_age_gr), data = new_births_clean59))

exneo_Mothers_age_n <- as.data.frame(exneo_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

exneo_Mothers_age_exp <- as.data.frame(exneo_Mothers_age$conf.int)  %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5)  %>% select(Variable, ExpCoef, LCI, UCI) %>%
  bind_rows(reference_age) %>% 
  bind_rows(exneo_Mothers_age_n) %>%
  rename(EarlyNeonatal_uRR=ExpCoef, EarlyNeonatal_LCI=LCI, EarlyNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
neo_Mothers_age <- summary(coxph(Surv(neonatal_time, neonatal_status) ~ as.factor(Mothers_age_gr), data = new_births_clean59))

neo_Mothers_age_n <- as.data.frame(neo_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

neo_Mothers_age_exp <- as.data.frame(neo_Mothers_age$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_age) %>% 
  bind_rows(neo_Mothers_age_n) %>%
  rename(Neonatal_uRR=ExpCoef, Neonatal_LCI=LCI, Neonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
postneo_Mothers_age <- summary(coxph(Surv(postneonatal_time, postneonatal_status) ~ as.factor(Mothers_age_gr), data = new_births_clean59))

postneo_Mothers_age_n <- as.data.frame(postneo_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

postneo_Mothers_age_exp <- as.data.frame(postneo_Mothers_age$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_age) %>% 
  bind_rows(postneo_Mothers_age_n) %>%
  rename(PostNeonatal_uRR=ExpCoef, PostNeonatal_LCI=LCI, PostNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
infant_Mothers_age <- summary(coxph(Surv(infant_time, infant_status) ~ as.factor(Mothers_age_gr), data = new_births_clean59))

infant_Mothers_age_n <- as.data.frame(infant_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

infant_Mothers_age_exp <- as.data.frame(infant_Mothers_age$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_age) %>% 
  bind_rows(infant_Mothers_age_n) %>%
  rename(Infant_uRR=ExpCoef, Infant_LCI=LCI, Infant_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
child_Mothers_age <- summary(coxph(Surv(child_time, child_status) ~ as.factor(Mothers_age_gr), data = new_births_clean179))

child_Mothers_age_n <- as.data.frame(child_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

child_Mothers_age_exp <- as.data.frame(child_Mothers_age$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select( Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_age) %>% 
  bind_rows(child_Mothers_age_n) %>%
  rename(Child_uRR=ExpCoef, Child_LCI=LCI, Child_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
under5_Mothers_age <- summary(coxph(Surv(under5_time, under5_status) ~ as.factor(Mothers_age_gr), data = new_births_clean179))

under5_Mothers_age_n <- as.data.frame(under5_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

under5_Mothers_age_exp <- as.data.frame(under5_Mothers_age$conf.int) %>%  
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_age) %>% 
  bind_rows(under5_Mothers_age_n) %>%
  rename(Under5_uRR=ExpCoef, Under5_LCI=LCI, Under5_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
Mothers_age_Results <- full_join(exneo_Mothers_age_exp, neo_Mothers_age_exp, by="Variable") %>%
  full_join(postneo_Mothers_age_exp, by="Variable") %>%
  full_join(infant_Mothers_age_exp, by="Variable") %>%
  full_join(child_Mothers_age_exp, by="Variable") %>%
  full_join(under5_Mothers_age_exp, by="Variable") %>% 
  mutate(order=case_when(Variable==  "AgeU18" ~ 1,
                         Variable==  "Age1824 (ref)"  ~ 2,
                         Variable=="Age2534"    ~ 3,
                         Variable==  "Age3539"   ~ 4,
                         Variable==  "Age40P" ~ 5,
                         Variable==  "Total N"  ~ 6)) %>%
  arrange(order) %>% select(-order)



##########################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # 
exneo_bord <- summary(coxph(Surv(exneonatal_time, exneonatal_status) ~ as.factor(bord_gr), data = new_births_clean59))

exneo_bord_n <- as.data.frame(exneo_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

exneo_bord_exp <- as.data.frame(exneo_bord$conf.int)  %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 19, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5)  %>% select(Variable, ExpCoef, LCI, UCI) %>%
  bind_rows(reference_bord) %>% 
  bind_rows(exneo_bord_n) %>%
  rename(EarlyNeonatal_uRR=ExpCoef, EarlyNeonatal_LCI=LCI, EarlyNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
neo_bord <- summary(coxph(Surv(neonatal_time, neonatal_status) ~ as.factor(bord_gr), data = new_births_clean59))

neo_bord_n <- as.data.frame(neo_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

neo_bord_exp <- as.data.frame(neo_bord$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 19, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_bord) %>% 
  bind_rows(neo_bord_n) %>%
  rename(Neonatal_uRR=ExpCoef, Neonatal_LCI=LCI, Neonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
postneo_bord <- summary(coxph(Surv(postneonatal_time, postneonatal_status) ~ as.factor(bord_gr), data = new_births_clean59))

postneo_bord_n <- as.data.frame(postneo_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

postneo_bord_exp <- as.data.frame(postneo_bord$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 19, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_bord) %>% 
  bind_rows(postneo_bord_n) %>%
  rename(PostNeonatal_uRR=ExpCoef, PostNeonatal_LCI=LCI, PostNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
infant_bord <- summary(coxph(Surv(infant_time, infant_status) ~ as.factor(bord_gr), data = new_births_clean59))

infant_bord_n <- as.data.frame(infant_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

infant_bord_exp <- as.data.frame(infant_bord$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 19, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_bord) %>% 
  bind_rows(infant_bord_n) %>%
  rename(Infant_uRR=ExpCoef, Infant_LCI=LCI, Infant_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
child_bord <- summary(coxph(Surv(child_time, child_status) ~ as.factor(bord_gr), data = new_births_clean179))

child_bord_n <- as.data.frame(child_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

child_bord_exp <- as.data.frame(child_bord$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 19, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select( Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_bord) %>% 
  bind_rows(child_bord_n) %>%
  rename(Child_uRR=ExpCoef, Child_LCI=LCI, Child_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
under5_bord <- summary(coxph(Surv(under5_time, under5_status) ~ as.factor(bord_gr), data = new_births_clean179))

under5_bord_n <- as.data.frame(under5_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

under5_bord_exp <- as.data.frame(under5_bord$conf.int) %>%  
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 19, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_bord) %>% 
  bind_rows(under5_bord_n) %>%
  rename(Under5_uRR=ExpCoef, Under5_LCI=LCI, Under5_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
BirthOrder_Results <- full_join(exneo_bord_exp, neo_bord_exp, by="Variable") %>%
  full_join(postneo_bord_exp, by="Variable") %>%
  full_join(infant_bord_exp, by="Variable") %>%
  full_join(child_bord_exp, by="Variable") %>%
  full_join(under5_bord_exp, by="Variable") %>% 
  mutate(order=case_when(Variable==  "BO1"  ~ 1,
                         Variable==   "BO2 (ref)"  ~ 2,
                         Variable==  "BO34"     ~ 3,
                         Variable==     "BO56"   ~ 4,
                         Variable==  "BO7P" ~ 5,
                         Variable==  "Total N"  ~ 6)) %>%
  arrange(order) %>% select(-order)


##########################################################################################################

Variable <- c("Birth to conception interval (months)")
var1df <- data.frame(Variable)

Variable <- c("Mother's age at child's birth")
var2df <- data.frame(Variable)

Variable <- c("Birth Order")
var3df <- data.frame(Variable)

new_results <- bind_rows(var1df, Interval_Results, var2df, Mothers_age_Results, var3df, BirthOrder_Results)

header7a <- c("Table 7. Unadjusted relative risk of mortality by duration of preceding birth to conception interval, mother's age at child's birth, and the birth order, children born 0 to 179 months prior to the survey, 84 DHS surveys, 2012 to 2022", "" , "")
header7b <- c("", "", "URR")
header7c <- c("", "Early Neonatal", "CI-")
header7d <- c("", "", "CI+")
header7e <- c("", "", "URR")
header7f <- c("", "Neonatal", "CI-")
header7g <- c("", "", "CI+")
header7h <- c("", "", "URR")
header7i <- c("", "Post-neonatal", "CI-")
header7j <- c("", "", "CI+")
header7k <- c("", "", "URR")
header7l <- c("", "Infant", "CI-")
header7m <- c("", "", "CI+")
header7n <- c("", "", "URR")
header7o <- c("", "Child", "CI-")
header7p <- c("", "", "CI+")
header7q <- c("", "", "URR")
header7r <- c("", "Under five", "CI-")
header7s <- c("", "", "CI+")


header7 <- data.frame(header7a, header7b, header7c, header7d, header7e, header7f, header7g, header7h, header7i, header7j, header7k, header7l, header7m, header7n, header7o, header7p, header7q, header7r, header7s)

footer7 <- c("Note: Age range of analysis:", "ENN (early neonatal), NN (neonatal), PNN (post–neonatal), and Infant Mortality: births in 0 to 59 months prior to survey.", "Child and Under–Five Mortality: births in 0 to 179 months prior to survey.")
footer7 <- data.frame(footer7)

#write.table(header7, file =  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Unadjusted Relative Risk of Mortality by Duration of Preceding Birth to Conception Interval Mothers Age at Childs Birth and the Birth Order.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(new_results,  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Unadjusted Relative Risk of Mortality by Duration of Preceding Birth to Conception Interval Mothers Age at Childs Birth and the Birth Order.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)
#write.table(footer7, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Unadjusted Relative Risk of Mortality by Duration of Preceding Birth to Conception Interval Mothers Age at Childs Birth and the Birth Order.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)


##########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
exneo_riskfull <- summary(coxph(Surv(exneonatal_time, exneonatal_status) ~ as.factor(RiskGr), data = new_births_clean59))

exneo_riskfull_n <- as.data.frame(exneo_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

exneo_riskfull_exp <- as.data.frame(exneo_riskfull$conf.int)  %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5)  %>% select(Variable, ExpCoef, LCI, UCI) %>% 
  bind_rows(reference_risk) %>% 
  bind_rows(exneo_riskfull_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                         LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                         UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(EarlyNeonatal_uRR=ExpCoef, EarlyNeonatal_LCI=LCI, EarlyNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
neo_riskfull <- summary(coxph(Surv(neonatal_time, neonatal_status) ~ as.factor(RiskGr), data = new_births_clean59))

neo_riskfull_n <- as.data.frame(neo_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

neo_riskfull_exp <- as.data.frame(neo_riskfull$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(neo_riskfull_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                        LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                        UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Neonatal_uRR=ExpCoef, Neonatal_LCI=LCI, Neonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
postneo_riskfull <- summary(coxph(Surv(postneonatal_time, postneonatal_status) ~ as.factor(RiskGr), data = new_births_clean59))

postneo_riskfull_n <- as.data.frame(postneo_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

postneo_riskfull_exp <- as.data.frame(postneo_riskfull$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(postneo_riskfull_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                            LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                            UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(PostNeonatal_uRR=ExpCoef, PostNeonatal_LCI=LCI, PostNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
infant_riskfull <- summary(coxph(Surv(infant_time, infant_status) ~ as.factor(RiskGr), data = new_births_clean59))

infant_riskfull_n <- as.data.frame(infant_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

infant_riskfull_exp <- as.data.frame(infant_riskfull$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(infant_riskfull_n) %>%   mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                            LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                            UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Infant_uRR=ExpCoef, Infant_LCI=LCI, Infant_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
child_riskfull <- summary(coxph(Surv(child_time, child_status) ~ as.factor(RiskGr), data = new_births_clean179))

child_riskfull_n <- as.data.frame(child_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

child_riskfull_exp <- as.data.frame(child_riskfull$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select( Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(child_riskfull_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                          LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                          UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Child_uRR=ExpCoef, Child_LCI=LCI, Child_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
under5_riskfull <- summary(coxph(Surv(under5_time, under5_status) ~ as.factor(RiskGr), data = new_births_clean179))

under5_riskfull_n <- as.data.frame(under5_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

under5_riskfull_exp <- as.data.frame(under5_riskfull$conf.int) %>%  
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(under5_riskfull_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                           LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                           UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Under5_uRR=ExpCoef, Under5_LCI=LCI, Under5_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
RiskFull_Results <- full_join(exneo_riskfull_exp, neo_riskfull_exp, by="Variable") %>%
  full_join(postneo_riskfull_exp, by="Variable") %>%
  full_join(infant_riskfull_exp, by="Variable") %>%
  full_join(child_riskfull_exp, by="Variable") %>%
  full_join(under5_riskfull_exp, by="Variable") %>% 
  mutate(order=case_when(Variable=="NoExtraRisk (ref)"  ~ 1,
                         Variable=="SingleUnavoidFirst"    ~ 2,
                         Variable=="SingleSPU24" ~ 3,
                         Variable== "SingleSP2435"  ~ 4,
                         Variable=="SingleMAU18"  ~ 5,
                         Variable=="SingleMA40P" ~ 6,
                         Variable=="Single4P"  ~ 7,
                         Variable=="Double4PSPU24"  ~ 8,
                         Variable=="Double4PSP2435"  ~ 9,
                         Variable=="DoubleUnavoidFirstMAU18" ~ 10,
                         Variable== "DoubleUnavoidFirstMA40P" ~ 11,
                         Variable== "Double4PMAU18" ~ 12,
                         Variable=="Double4PMA40P" ~ 13,
                         Variable=="DoubleSPU24MAU18"  ~ 14,
                         Variable=="DoubleSP2435MAU18"  ~ 15,
                         Variable== "DoubleSPU24MA40P"  ~ 16,
                         Variable==  "DoubleSP2435MA40P" ~ 17,
                         Variable=="Triple4PSP2435MAU18" ~ 18,
                         Variable=="Triple4PSPU24MA40P"  ~ 19,
                         Variable=="Triple4PSPU24MAU18"  ~ 20,
                         Variable== "Triple4PSP2435MA40P"   ~ 21,
                         Variable==   "Total N" ~ 22)) %>%
  arrange(order) %>% select(-order) 

header8a <- c("Table 8. Unadjusted relative risk of mortality by mother's fertility related risk, children born 0 to 179 months prior to the survey, 84 DHS surveys, 2012 to 2022", "" , "")
header8b <- c("", "", "URR")
header8c <- c("", "Early Neonatal", "CI-")
header8d <- c("", "", "CI+")
header8e <- c("", "", "URR")
header8f <- c("", "Neonatal", "CI-")
header8g <- c("", "", "CI+")
header8h <- c("", "", "URR")
header8i <- c("", "Post-neonatal", "CI-")
header8j <- c("", "", "CI+")
header8k <- c("", "", "URR")
header8l <- c("", "Infant", "CI-")
header8m <- c("", "", "CI+")
header8n <- c("", "", "URR")
header8o <- c("", "Child", "CI-")
header8p <- c("", "", "CI+")
header8q <- c("", "", "URR")
header8r <- c("", "Under five", "CI-")
header8s <- c("", "", "CI+")


header8 <- data.frame(header8a, header8b, header8c, header8d, header8e, header8f, header8g, header8h, header8i, header8j, header8k, header8l, header8m, header8n, header8o, header8p, header8q, header8r, header8s)

footer8 <- c("Note: Age range of analysis:", "ENN (early neonatal), NN (neonatal), PNN (post–neonatal), and Infant Mortality: births in 0 to 59 months prior to survey.", "Child and Under Five Mortality: births in 0 to 179 months prior to survey.")
footer8 <- data.frame(footer8)

#write.table(header8, file = "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Unadjusted Relative Risk of Mortality by the Mothers Fertility Related Risk.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(RiskFull_Results,  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Unadjusted Relative Risk of Mortality by the Mothers Fertility Related Risk.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)
#write.table(footer8, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Unadjusted Relative Risk of Mortality by the Mothers Fertility Related Risk.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)


##########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
exneo_risksimp <- summary(coxph(Surv(exneonatal_time, exneonatal_status) ~ as.factor(RiskGR_Simple), data = new_births_clean59))

exneo_risksimp_n <- as.data.frame(exneo_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

exneo_risksimp_exp <- as.data.frame(exneo_risksimp$conf.int)  %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5)  %>% select(Variable, ExpCoef, LCI, UCI) %>%
  bind_rows(reference_risk) %>% 
  bind_rows(exneo_risksimp_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                          LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                          UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(EarlyNeonatal_uRR=ExpCoef, EarlyNeonatal_LCI=LCI, EarlyNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
neo_risksimp <- summary(coxph(Surv(neonatal_time, neonatal_status) ~ as.factor(RiskGR_Simple), data = new_births_clean59))

neo_risksimp_n <- as.data.frame(neo_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

neo_risksimp_exp <- as.data.frame(neo_risksimp$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(neo_risksimp_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                        LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                        UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Neonatal_uRR=ExpCoef, Neonatal_LCI=LCI, Neonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
postneo_risksimp <- summary(coxph(Surv(postneonatal_time, postneonatal_status) ~ as.factor(RiskGR_Simple), data = new_births_clean59))

postneo_risksimp_n <- as.data.frame(postneo_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

postneo_risksimp_exp <- as.data.frame(postneo_risksimp$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(postneo_risksimp_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                            LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                            UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(PostNeonatal_uRR=ExpCoef, PostNeonatal_LCI=LCI, PostNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
infant_risksimp <- summary(coxph(Surv(infant_time, infant_status) ~ as.factor(RiskGR_Simple), data = new_births_clean59))

infant_risksimp_n <- as.data.frame(infant_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

infant_risksimp_exp <- as.data.frame(infant_risksimp$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(infant_risksimp_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                           LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                           UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Infant_uRR=ExpCoef, Infant_LCI=LCI, Infant_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
child_risksimp <- summary(coxph(Surv(child_time, child_status) ~ as.factor(RiskGR_Simple), data = new_births_clean179))

child_risksimp_n <- as.data.frame(child_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

child_risksimp_exp <- as.data.frame(child_risksimp$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select( Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(child_risksimp_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                          LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                          UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Child_uRR=ExpCoef, Child_LCI=LCI, Child_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
under5_risksimp <- summary(coxph(Surv(under5_time, under5_status) ~ as.factor(RiskGR_Simple), data = new_births_clean179))

under5_risksimp_n <- as.data.frame(under5_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

under5_risksimp_exp <- as.data.frame(under5_risksimp$conf.int) %>%  
  rownames_to_column( var = "rowname") %>% mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(under5_risksimp_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                           LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                           UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Under5_uRR=ExpCoef, Under5_LCI=LCI, Under5_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
RiskSimp_Results <- full_join(exneo_risksimp_exp, neo_risksimp_exp, by="Variable") %>%
  full_join(postneo_risksimp_exp, by="Variable") %>%
  full_join(infant_risksimp_exp, by="Variable") %>%
  full_join(child_risksimp_exp, by="Variable") %>%
  full_join(under5_risksimp_exp, by="Variable") %>% 
  mutate(order=case_when(Variable=="NoExtraRisk (ref)"  ~ 1,
                         Variable=="UnavoidFirst"    ~ 2,
                         Variable=="Single" ~ 3,
                         Variable== "Double"  ~ 4,
                         Variable=="Triple"  ~ 5,
                         Variable==   "Total N" ~ 6)) %>%
  arrange(order) %>% select(-order)

#write.csv(RiskSimp_Results, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Unadjusted Relative Risk of Mortality by the Mothers Fertility Related Risk Simplified.csv", row.names = F, na="")

header9a <- c("Table 9. Unadjusted relative risk of mortality by mother's fertility related risk, simplified, children born 0 to 179 months prior to the survey, 84 DHS surveys, 2012 to 2022", "" , "")
header9b <- c("", "", "URR")
header9c <- c("", "Early Neonatal", "CI-")
header9d <- c("", "", "CI+")
header9e <- c("", "", "URR")
header9f <- c("", "Neonatal", "CI-")
header9g <- c("", "", "CI+")
header9h <- c("", "", "URR")
header9i <- c("", "Post-neonatal", "CI-")
header9j <- c("", "", "CI+")
header9k <- c("", "", "URR")
header9l <- c("", "Infant", "CI-")
header9m <- c("", "", "CI+")
header9n <- c("", "", "URR")
header9o <- c("", "Child", "CI-")
header9p <- c("", "", "CI+")
header9q <- c("", "", "URR")
header9r <- c("", "Under five", "CI-")
header9s <- c("", "", "CI+")


header9 <- data.frame(header9a, header9b, header9c, header9d, header9e, header9f, header9g, header9h, header9i, header9j, header9k, header9l, header9m, header9n, header9o, header9p, header9q, header9r, header9s)

footer9 <- c("Note: Age range of analysis:", "ENN (early neonatal), NN (neonatal), PNN (post–neonatal), and Infant Mortality: births in 0 to 59 months prior to survey.", "Child and Under Five Mortality: births in 0 to 179 months prior to survey.")
footer9 <- data.frame(footer9)

#write.table(header9, file = "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Unadjusted Relative Risk of Mortality by the Mothers Fertility Related Risk Simplified.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(RiskSimp_Results, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Unadjusted Relative Risk of Mortality by the Mothers Fertility Related Risk Simplified.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)
#write.table(footer9,"C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Unadjusted Relative Risk of Mortality by the Mothers Fertility Related Risk Simplified.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)

#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################

# Adjusted Odds Ratios
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
exneo_interval <- summary(coxph(Surv(exneonatal_time, exneonatal_status) ~ as.factor(interval) + Sex + Residence + MotherEduc +
                                  Wealth + Refridgerator + Toilet + Water + Gestation +
                                  survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                  Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

exneo_interval_n <- as.data.frame(exneo_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

exneo_interval_exp <- as.data.frame(exneo_interval$conf.int) %>% 
  rownames_to_column( var = "rowname") %>%
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5)  %>% select(Variable, ExpCoef, LCI, UCI) %>%
  bind_rows(reference_interval) %>% 
  bind_rows(exneo_interval_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                          LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                          UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(EarlyNeonatal_uRR=ExpCoef, EarlyNeonatal_LCI=LCI, EarlyNeonatal_UCI=UCI)


# # # # # # # # # # # # # # # # # # # # # # # # # # # 
neo_interval <- summary(coxph(Surv(neonatal_time, neonatal_status) ~ as.factor(interval) + Sex + Residence + MotherEduc +
                                Wealth + Refridgerator + Toilet + Water + Gestation +
                                survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

neo_interval_n <- as.data.frame(neo_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

neo_interval_exp <- as.data.frame(neo_interval$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_interval) %>% 
  bind_rows(neo_interval_n) %>%   mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                         LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                         UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Neonatal_uRR=ExpCoef, Neonatal_LCI=LCI, Neonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
postneo_interval <- summary(coxph(Surv(postneonatal_time, postneonatal_status) ~ as.factor(interval) + Sex + Residence + MotherEduc +
                                    Wealth + Refridgerator + Toilet + Water + Gestation +
                                    survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                    Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

postneo_interval_n <- as.data.frame(postneo_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

postneo_interval_exp <- as.data.frame(postneo_interval$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_interval) %>% 
  bind_rows(postneo_interval_n) %>%   mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                             LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                             UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(PostNeonatal_uRR=ExpCoef, PostNeonatal_LCI=LCI, PostNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
infant_interval <- summary(coxph(Surv(infant_time, infant_status) ~ as.factor(interval) + Sex + Residence + MotherEduc +
                                   Wealth + Refridgerator + Toilet + Water + Gestation +
                                   survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                   Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

infant_interval_n <- as.data.frame(infant_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

infant_interval_exp <- as.data.frame(infant_interval$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_interval) %>% 
  bind_rows(infant_interval_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                           LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                           UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Infant_uRR=ExpCoef, Infant_LCI=LCI, Infant_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
child_interval <- summary(coxph(Surv(child_time, child_status) ~ as.factor(interval) + Sex + Residence + MotherEduc + Wealth + Refridgerator +
                                  Toilet + Water + Gestation + survival_preceding , data = new_births_clean179))

child_interval_n <- as.data.frame(child_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

child_interval_exp <- as.data.frame(child_interval$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select( Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_interval) %>% 
  bind_rows(child_interval_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                         LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                         UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Child_uRR=ExpCoef, Child_LCI=LCI, Child_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
under5_interval <- summary(coxph(Surv(under5_time, under5_status) ~ as.factor(interval) + Sex + Residence + MotherEduc + Wealth + Refridgerator +
                                   Toilet + Water + Gestation + survival_preceding , data = new_births_clean179))

under5_interval_n <- as.data.frame(under5_interval$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

under5_interval_exp <- as.data.frame(under5_interval$conf.int) %>%  
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 20, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_interval) %>% 
  bind_rows(under5_interval_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                           LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                           UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Under5_uRR=ExpCoef, Under5_LCI=LCI, Under5_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
Interval_Results_Adj <- full_join(exneo_interval_exp, neo_interval_exp, by="Variable") %>%
  full_join(postneo_interval_exp, by="Variable") %>%
  full_join(infant_interval_exp, by="Variable") %>%
  full_join(child_interval_exp, by="Variable") %>%
  full_join(under5_interval_exp, by="Variable") %>% 
  mutate(order=case_when(Variable== "Under6" ~ 1,
                         Variable== "M6to11"   ~ 2,
                         Variable=="M12to17"  ~ 3,
                         Variable== "M18to23" ~ 4,
                         Variable=="M24to29"  ~ 5,
                         Variable== "M30to35" ~ 6,
                         Variable=="M3647 (ref)" ~ 7,
                         Variable=="M48to59" ~ 8,
                         Variable=="M60to95" ~ 9,
                         Variable== "M96P"  ~ 10,
                         Variable== "FirstBorn" ~ 11,
                         Variable== "Total N"   ~ 12)) %>%
  arrange(order) %>% select(-order)



levels(as.factor(Interval_Results$Variable))
##################################################################################################################################


# # # # # # # # # # # # # # # # # # # # # # # # # # # 
exneo_Mothers_age <- summary(coxph(Surv(exneonatal_time, exneonatal_status) ~ as.factor(Mothers_age_gr) + Sex + Residence + MotherEduc +
                                     Wealth + Refridgerator + Toilet + Water + Gestation +
                                     survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                     Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

exneo_Mothers_age_n <- as.data.frame(exneo_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

exneo_Mothers_age_exp <- as.data.frame(exneo_Mothers_age$conf.int)  %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5)  %>% select(Variable, ExpCoef, LCI, UCI) %>%
  bind_rows(reference_age) %>% 
  bind_rows(exneo_Mothers_age_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                             LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                             UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(EarlyNeonatal_uRR=ExpCoef, EarlyNeonatal_LCI=LCI, EarlyNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
neo_Mothers_age <- summary(coxph(Surv(neonatal_time, neonatal_status) ~ as.factor(Mothers_age_gr) + Sex + Residence + MotherEduc +
                                   Wealth + Refridgerator + Toilet + Water + Gestation +
                                   survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                   Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

neo_Mothers_age_n <- as.data.frame(neo_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

neo_Mothers_age_exp <- as.data.frame(neo_Mothers_age$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_age) %>% 
  bind_rows(neo_Mothers_age_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                           LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                           UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Neonatal_uRR=ExpCoef, Neonatal_LCI=LCI, Neonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
postneo_Mothers_age <- summary(coxph(Surv(postneonatal_time, postneonatal_status) ~ as.factor(Mothers_age_gr) + Sex + Residence + MotherEduc +
                                       Wealth + Refridgerator + Toilet + Water + Gestation +
                                       survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                       Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

postneo_Mothers_age_n <- as.data.frame(postneo_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

postneo_Mothers_age_exp <- as.data.frame(postneo_Mothers_age$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_age) %>% 
  bind_rows(postneo_Mothers_age_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                               LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                               UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(PostNeonatal_uRR=ExpCoef, PostNeonatal_LCI=LCI, PostNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
infant_Mothers_age <- summary(coxph(Surv(infant_time, infant_status) ~ as.factor(Mothers_age_gr) + Sex + Residence + MotherEduc +
                                      Wealth + Refridgerator + Toilet + Water + Gestation +
                                      survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                      Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

infant_Mothers_age_n <- as.data.frame(infant_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

infant_Mothers_age_exp <- as.data.frame(infant_Mothers_age$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_age) %>% 
  bind_rows(infant_Mothers_age_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                             LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                             UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>% 
  rename(Infant_uRR=ExpCoef, Infant_LCI=LCI, Infant_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
child_Mothers_age <- summary(coxph(Surv(child_time, child_status) ~ as.factor(Mothers_age_gr) + Sex + Residence + MotherEduc + Wealth + Refridgerator +
                                     Toilet + Water + Gestation + survival_preceding, data = new_births_clean179))

child_Mothers_age_n <- as.data.frame(child_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

child_Mothers_age_exp <- as.data.frame(child_Mothers_age$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select( Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_age) %>% 
  bind_rows(child_Mothers_age_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                             LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                             UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Child_uRR=ExpCoef, Child_LCI=LCI, Child_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
under5_Mothers_age <- summary(coxph(Surv(under5_time, under5_status) ~ as.factor(Mothers_age_gr) + Sex + Residence + MotherEduc + Wealth + Refridgerator +
                                      Toilet + Water + Gestation + survival_preceding, data = new_births_clean179))

under5_Mothers_age_n <- as.data.frame(under5_Mothers_age$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

under5_Mothers_age_exp <- as.data.frame(under5_Mothers_age$conf.int) %>%  
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 26, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_age) %>% 
  bind_rows(under5_Mothers_age_n) %>%  mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                              LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                              UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Under5_uRR=ExpCoef, Under5_LCI=LCI, Under5_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
Mothers_age_Results_Adj <- full_join(exneo_Mothers_age_exp, neo_Mothers_age_exp, by="Variable") %>%
  full_join(postneo_Mothers_age_exp, by="Variable") %>%
  full_join(infant_Mothers_age_exp, by="Variable") %>%
  full_join(child_Mothers_age_exp, by="Variable") %>%
  full_join(under5_Mothers_age_exp, by="Variable") %>% 
  mutate(order=case_when(Variable==  "AgeU18" ~ 1,
                         Variable==  "Age1824 (ref)"  ~ 2,
                         Variable=="Age2534"    ~ 3,
                         Variable==  "Age3539"   ~ 4,
                         Variable==  "Age40P" ~ 5,
                         Variable==  "Total N"  ~ 6)) %>%
  arrange(order) %>% select(-order)

###############################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
exneo_bord <- summary(coxph(Surv(exneonatal_time, exneonatal_status) ~ as.factor(bord_grsimp) + Sex + Residence + MotherEduc +
                              Wealth + Refridgerator + Toilet + Water + Gestation +
                              survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                              Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

exneo_bord_n <- as.data.frame(exneo_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

exneo_bord_exp <- as.data.frame(exneo_bord$conf.int)  %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 23, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5)  %>% select(Variable, ExpCoef, LCI, UCI) %>%
  bind_rows(reference_bordsimp) %>% 
  bind_rows(exneo_bord_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                     LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                     UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(EarlyNeonatal_uRR=ExpCoef, EarlyNeonatal_LCI=LCI, EarlyNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
neo_bord <- summary(coxph(Surv(neonatal_time, neonatal_status) ~ as.factor(bord_grsimp) + Sex + Residence + MotherEduc +
                            Wealth + Refridgerator + Toilet + Water + Gestation +
                            survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                            Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

neo_bord_n <- as.data.frame(neo_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

neo_bord_exp <- as.data.frame(neo_bord$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 23, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_bordsimp) %>% 
  bind_rows(neo_bord_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                   LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                   UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Neonatal_uRR=ExpCoef, Neonatal_LCI=LCI, Neonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
postneo_bord <- summary(coxph(Surv(postneonatal_time, postneonatal_status) ~ as.factor(bord_grsimp) + Sex + Residence + MotherEduc +
                                Wealth + Refridgerator + Toilet + Water + Gestation +
                                survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

postneo_bord_n <- as.data.frame(postneo_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

postneo_bord_exp <- as.data.frame(postneo_bord$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 23, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_bordsimp) %>% 
  bind_rows(postneo_bord_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                       LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                       UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(PostNeonatal_uRR=ExpCoef, PostNeonatal_LCI=LCI, PostNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
infant_bord <- summary(coxph(Surv(infant_time, infant_status) ~ as.factor(bord_grsimp) + Sex + Residence + MotherEduc +
                               Wealth + Refridgerator + Toilet + Water + Gestation +
                               survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                               Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

infant_bord_n <- as.data.frame(infant_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

infant_bord_exp <- as.data.frame(infant_bord$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 23, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_bordsimp) %>% 
  bind_rows(infant_bord_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                      LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                      UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Infant_uRR=ExpCoef, Infant_LCI=LCI, Infant_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
child_bord <- summary(coxph(Surv(child_time, child_status) ~ as.factor(bord_grsimp) + Sex + Residence + MotherEduc + Wealth + Refridgerator +
                              Toilet + Water + Gestation + survival_preceding , data = new_births_clean179))

child_bord_n <- as.data.frame(child_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

child_bord_exp <- as.data.frame(child_bord$conf.int) %>% 
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 23, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select( Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_bordsimp) %>% 
  bind_rows(child_bord_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                     LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                     UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Child_uRR=ExpCoef, Child_LCI=LCI, Child_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
under5_bord <- summary(coxph(Surv(under5_time, under5_status) ~ as.factor(bord_grsimp) + Sex + Residence + MotherEduc + Wealth + Refridgerator +
                               Toilet + Water + Gestation + survival_preceding , data = new_births_clean179))

under5_bord_n <- as.data.frame(under5_bord$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

under5_bord_exp <- as.data.frame(under5_bord$conf.int) %>%  
  rownames_to_column( var = "rowname") %>% 
  mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 23, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_bordsimp) %>% 
  bind_rows(under5_bord_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                      LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                      UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Under5_uRR=ExpCoef, Under5_LCI=LCI, Under5_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
BirthOrder_Results_Adj <- full_join(exneo_bord_exp, neo_bord_exp, by="Variable") %>%
  full_join(postneo_bord_exp, by="Variable") %>%
  full_join(infant_bord_exp, by="Variable") %>%
  full_join(child_bord_exp, by="Variable") %>%
  full_join(under5_bord_exp, by="Variable") %>% 
  mutate(order=case_when(
    Variable==   "BO12 (ref)"  ~ 1,
    Variable==  "BO34"     ~ 2,
    Variable==     "BO56"   ~ 3,
    Variable==  "BO7P" ~ 4,
    Variable==  "Total N"  ~ 5)) %>%
  arrange(order) %>% select(-order)




Variable <- c("Birth to conception interval (months)")
var1df <- data.frame(Variable)

Variable <- c("Mother's age at child's birth")
var2df <- data.frame(Variable)

Variable <- c("Birth Order")
var3df <- data.frame(Variable)

new_results_Adj <- bind_rows(var1df, Interval_Results_Adj, var2df, Mothers_age_Results_Adj, var3df, BirthOrder_Results_Adj)

header10a <- c("Table 10. Adjusted relative risk of mortality by duration of preceding birth to conception interval, mother's age at child's birth, and the birth order, children born 0 to 179 months prior to the survey, 84 DHS surveys, 2012 to 2022", "" , "")
header10b <- c("", "", "URR")
header10c <- c("", "Early Neonatal", "CI-")
header10d <- c("", "", "CI+")
header10e <- c("", "", "URR")
header10f <- c("", "Neonatal", "CI-")
header10g <- c("", "", "CI+")
header10h <- c("", "", "URR")
header10i <- c("", "Post-neonatal", "CI-")
header10j <- c("", "", "CI+")
header10k <- c("", "", "URR")
header10l <- c("", "Infant", "CI-")
header10m <- c("", "", "CI+")
header10n <- c("", "", "URR")
header10o <- c("", "Child", "CI-")
header10p <- c("", "", "CI+")
header10q <- c("", "", "URR")
header10r <- c("", "Under five", "CI-")
header10s <- c("", "", "CI+")


header10 <- data.frame(header10a, header10b, header10c, header10d, header10e, header10f, header10g, header10h, header10i, header10j, header10k, header10l, header10m, header10n, header10o, header10p, header10q, header10r, header10s)

footer10 <- c("Note: In addition to the three key fertility risk behavior characteristics, adjusted models included the following variables", 
              "ENN, NN, PNN, and Infant Mortality: Sex of index child, urban or rural area of residence, wantedness of child, mother's education, whether conception was a result of contraceptive failure, outcome of preceding pregnancy (live birth or stillbirth), type of provider of prenatal care, type of provider of delivery assistance, number of prenatal tetanus injections, timing of first prenatal care visit,quintile of DHS Wealth Index, type of water supply, type of toilet facility, possession of refrigerator, duration of pregnancy, and whether preceding child died before conception of index child.", 
              "Child and Under Five Mortality: Sex of index child, urban or rural area of residence, mother's education, quintile of Wealth Index, type of water supply, type of toilet facility, possession of refrigerator, duration of pregnancy, and whether preceding child died before conception of index child.",
              "Age range of analysis:",
"ENN, NN, PNN, and Infant Mortality: 0 to 59 months",
"Child and Under Five Mortality: 0 to 179 months")
footer10 <- data.frame(footer10)

#write.table(header10, file =  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Adjusted Relative Risk of Mortality by Duration of Preceding Birth to Conception Interval Mothers Age at Childs Birth and the Birth Order.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(new_results_Adj,  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Adjusted Relative Risk of Mortality by Duration of Preceding Birth to Conception Interval Mothers Age at Childs Birth and the Birth Order.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)
#write.table(footer10, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Adjusted Relative Risk of Mortality by Duration of Preceding Birth to Conception Interval Mothers Age at Childs Birth and the Birth Order.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)

#######################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
exneo_riskfull <- summary(coxph(Surv(exneonatal_time, exneonatal_status) ~ as.factor(RiskGr) + Sex + Residence + MotherEduc +
                                  Wealth + Refridgerator + Toilet + Water + Gestation +
                                  survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                  Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

exneo_riskfull_n <- as.data.frame(exneo_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

exneo_riskfull_exp <- as.data.frame(exneo_riskfull$conf.int)  %>% 
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5)  %>% select(Variable, ExpCoef, LCI, UCI) %>%
  bind_rows(reference_risk) %>% 
  bind_rows(exneo_riskfull_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                         LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                         UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(EarlyNeonatal_uRR=ExpCoef, EarlyNeonatal_LCI=LCI, EarlyNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
neo_riskfull <- summary(coxph(Surv(neonatal_time, neonatal_status) ~ as.factor(RiskGr) + Sex + Residence + MotherEduc +
                                Wealth + Refridgerator + Toilet + Water + Gestation +
                                survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

neo_riskfull_n <- as.data.frame(neo_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

neo_riskfull_exp <- as.data.frame(neo_riskfull$conf.int) %>% 
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(neo_riskfull_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                       LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                       UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Neonatal_uRR=ExpCoef, Neonatal_LCI=LCI, Neonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
postneo_riskfull <- summary(coxph(Surv(postneonatal_time, postneonatal_status) ~ as.factor(RiskGr) + Sex + Residence + MotherEduc +
                                    Wealth + Refridgerator + Toilet + Water + Gestation +
                                    survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                    Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

postneo_riskfull_n <- as.data.frame(postneo_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

postneo_riskfull_exp <- as.data.frame(postneo_riskfull$conf.int) %>% 
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(postneo_riskfull_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                           LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                           UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(PostNeonatal_uRR=ExpCoef, PostNeonatal_LCI=LCI, PostNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
infant_riskfull <- summary(coxph(Surv(infant_time, infant_status) ~ as.factor(RiskGr) + Sex + Residence + MotherEduc +
                                   Wealth + Refridgerator + Toilet + Water + Gestation +
                                   survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                   Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

infant_riskfull_n <- as.data.frame(infant_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

infant_riskfull_exp <- as.data.frame(infant_riskfull$conf.int) %>% 
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(infant_riskfull_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                          LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                          UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Infant_uRR=ExpCoef, Infant_LCI=LCI, Infant_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
child_riskfull <- summary(coxph(Surv(child_time, child_status) ~ as.factor(RiskGr) + Sex + Residence + MotherEduc + Wealth + Refridgerator +
                                  Toilet + Water + Gestation + survival_preceding, data = new_births_clean179))

child_riskfull_n <- as.data.frame(child_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

child_riskfull_exp <- as.data.frame(child_riskfull$conf.int) %>% 
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select( Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(child_riskfull_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                         LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                         UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Child_uRR=ExpCoef, Child_LCI=LCI, Child_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
under5_riskfull <- summary(coxph(Surv(under5_time, under5_status) ~ as.factor(RiskGr) + Sex + Residence + MotherEduc + Wealth + Refridgerator +
                                   Toilet + Water + Gestation + survival_preceding, data = new_births_clean179))

under5_riskfull_n <- as.data.frame(under5_riskfull$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

under5_riskfull_exp <- as.data.frame(under5_riskfull$conf.int) %>%  
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 18, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(under5_riskfull_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                          LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                          UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Under5_uRR=ExpCoef, Under5_LCI=LCI, Under5_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
RiskFull_Results_Adj <- full_join(exneo_riskfull_exp, neo_riskfull_exp, by="Variable") %>%
  full_join(postneo_riskfull_exp, by="Variable") %>%
  full_join(infant_riskfull_exp, by="Variable") %>%
  full_join(child_riskfull_exp, by="Variable") %>%
  full_join(under5_riskfull_exp, by="Variable") %>% 
  mutate(order=case_when(Variable=="NoExtraRisk (ref)"  ~ 1,
                         Variable=="SingleUnavoidFirst"    ~ 2,
                         Variable=="SingleSPU24" ~ 3,
                         Variable== "SingleSP2435"  ~ 4,
                         Variable=="SingleMAU18"  ~ 5,
                         Variable=="SingleMA40P" ~ 6,
                         Variable=="Single4P"  ~ 7,
                         Variable=="Double4PSPU24"  ~ 8,
                         Variable=="Double4PSP2435"  ~ 9,
                         Variable=="DoubleUnavoidFirstMAU18" ~ 10,
                         Variable== "DoubleUnavoidFirstMA40P" ~ 11,
                         Variable== "Double4PMAU18" ~ 12,
                         Variable=="Double4PMA40P" ~ 13,
                         Variable=="DoubleSPU24MAU18"  ~ 14,
                         Variable=="DoubleSP2435MAU18"  ~ 15,
                         Variable== "DoubleSPU24MA40P"  ~ 16,
                         Variable==  "DoubleSP2435MA40P" ~ 17,
                         Variable=="Triple4PSP2435MAU18" ~ 18,
                         Variable=="Triple4PSPU24MA40P"  ~ 19,
                         Variable=="Triple4PSPU24MAU18"  ~ 20,
                         Variable== "Triple4PSP2435MA40P"   ~ 21,
                         Variable==   "Total N" ~ 22)) %>%
  arrange(order) %>% select(-order)

header11a <- c("Table 11. Adjusted relative risk of mortality by the mother's fertility related risk, children born 0 to 179 months prior to the survey, 84 DHS surveys, 2012 to 2022", "" , "")
header11b <- c("", "", "URR")
header11c <- c("", "Early Neonatal", "CI-")
header11d <- c("", "", "CI+")
header11e <- c("", "", "URR")
header11f <- c("", "Neonatal", "CI-")
header11g <- c("", "", "CI+")
header11h <- c("", "", "URR")
header11i <- c("", "Post-neonatal", "CI-")
header11j <- c("", "", "CI+")
header11k <- c("", "", "URR")
header11l <- c("", "Infant", "CI-")
header11m <- c("", "", "CI+")
header11n <- c("", "", "URR")
header11o <- c("", "Child", "CI-")
header11p <- c("", "", "CI+")
header11q <- c("", "", "URR")
header11r <- c("", "Under five", "CI-")
header11s <- c("", "", "CI+")


header11 <- data.frame(header11a, header11b, header11c, header11d, header11e, header11f, header11g, header11h, header11i, header11j, header11k, header11l, header11m, header11n, header11o, header11p, header11q, header11r, header11s)

footer11 <- c("Note: Ajusted models included the following variables", 
              "ENN, NN, PNN, and Infant Mortality: Sex of index child, urban or rural area of residence, wantedness of child, mother's education, whether conception was a result of contraceptive failure, outcome of preceding pregnancy (live birth or stillbirth), type of provider of prenatal care, type of provider of delivery assistance, number of prenatal tetanus injections, timing of first prenatal care visit,quintile of DHS Wealth Index, type of water supply, type of toilet facility, possession of refrigerator, duration of pregnancy, and whether preceding child died before conception of index child.", 
              "Child and Under Five Mortality: Sex of index child, urban or rural area of residence, mother's education, quintile of Wealth Index, type of water supply, type of toilet facility, possession of refrigerator, duration of pregnancy, and whether preceding child died before conception of index child.",
              "Age range of analysis:",
              "ENN, NN, PNN, and Infant Mortality: 0 to 59 months",
              "Child and Under Five Mortality: 0 to 179 months",
              "NC: No cases")
footer11 <- data.frame(footer11)

#write.table(header11, file = "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Adjusted Relative Risk of Mortality by the Mothers Fertility Related Risk.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(RiskFull_Results_Adj,  "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Adjusted Relative Risk of Mortality by the Mothers Fertility Related Risk.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)
#write.table(footer11, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Adjusted Relative Risk of Mortality by the Mothers Fertility Related Risk.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)


##########################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
exneo_risksimp <- summary(coxph(Surv(exneonatal_time, exneonatal_status) ~ as.factor(RiskGR_Simple) + Sex + Residence + MotherEduc +
                                  Wealth + Refridgerator + Toilet + Water + Gestation +
                                  survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                  Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

exneo_risksimp_n <- as.data.frame(exneo_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

exneo_risksimp_exp <- as.data.frame(exneo_risksimp$conf.int)  %>% 
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5)  %>% select(Variable, ExpCoef, LCI, UCI) %>%
  bind_rows(reference_risk) %>% 
  bind_rows(exneo_risksimp_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                         LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                         UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(EarlyNeonatal_uRR=ExpCoef, EarlyNeonatal_LCI=LCI, EarlyNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
neo_risksimp <- summary(coxph(Surv(neonatal_time, neonatal_status) ~ as.factor(RiskGR_Simple) + Sex + Residence + MotherEduc +
                                Wealth + Refridgerator + Toilet + Water + Gestation +
                                survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

neo_risksimp_n <- as.data.frame(neo_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

neo_risksimp_exp <- as.data.frame(neo_risksimp$conf.int) %>% 
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(neo_risksimp_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                       LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                       UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Neonatal_uRR=ExpCoef, Neonatal_LCI=LCI, Neonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
postneo_risksimp <- summary(coxph(Surv(postneonatal_time, postneonatal_status) ~ as.factor(RiskGR_Simple) + Sex + Residence + MotherEduc +
                                    Wealth + Refridgerator + Toilet + Water + Gestation +
                                    survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                    Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

postneo_risksimp_n <- as.data.frame(postneo_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

postneo_risksimp_exp <- as.data.frame(postneo_risksimp$conf.int) %>% 
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(postneo_risksimp_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                           LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                           UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(PostNeonatal_uRR=ExpCoef, PostNeonatal_LCI=LCI, PostNeonatal_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
infant_risksimp <- summary(coxph(Surv(infant_time, infant_status) ~ as.factor(RiskGR_Simple) + Sex + Residence + MotherEduc +
                                   Wealth + Refridgerator + Toilet + Water + Gestation +
                                   survival_preceding + OutPrePreg_Simp + wanted + ContrFailure +
                                   Provider_Prenatalsimp + Provider_Deliverysimp + Tetanus + TimingAntenatal, data = new_births_clean59))

infant_risksimp_n <- as.data.frame(infant_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

infant_risksimp_exp <- as.data.frame(infant_risksimp$conf.int) %>% 
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(infant_risksimp_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                          LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                          UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Infant_uRR=ExpCoef, Infant_LCI=LCI, Infant_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
child_risksimp <- summary(coxph(Surv(child_time, child_status) ~ as.factor(RiskGR_Simple) + Sex + Residence + MotherEduc + Wealth + Refridgerator +
                                  Toilet + Water + Gestation + survival_preceding, data = new_births_clean179))

child_risksimp_n <- as.data.frame(child_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

child_risksimp_exp <- as.data.frame(child_risksimp$conf.int) %>% 
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select( Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(child_risksimp_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                         LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                         UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Child_uRR=ExpCoef, Child_LCI=LCI, Child_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
under5_risksimp <- summary(coxph(Surv(under5_time, under5_status) ~ as.factor(RiskGR_Simple) + Sex + Residence + MotherEduc + Wealth + Refridgerator +
                                   Toilet + Water + Gestation + survival_preceding, data = new_births_clean179))

under5_risksimp_n <- as.data.frame(under5_risksimp$n) %>% rename(LCI=1) %>% mutate(Variable="Total N", ExpCoef=NA, UCI=NA)  %>% 
  select(Variable, ExpCoef, LCI, UCI)

under5_risksimp_exp <- as.data.frame(under5_risksimp$conf.int) %>%  
  rownames_to_column( var = "rowname") %>%   mutate(type=str_sub(as.character(rowname), 1, 2)) %>%
  filter(type=="as") %>% 
  mutate(Variable=str_sub(as.character(rowname), 25, -1)) %>%
  rename(ExpCoef=2, LCI=4, UCI=5) %>% select(Variable, ExpCoef, LCI, UCI)  %>%
  bind_rows(reference_risk) %>% 
  bind_rows(under5_risksimp_n) %>% mutate(ExpCoef=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(ExpCoef,2)) ),
                                          LCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(LCI,2)) ),
                                          UCI=case_when(UCI>1000 ~ "nc", TRUE ~ as.character(round(UCI,2)) )) %>%
  rename(Under5_uRR=ExpCoef, Under5_LCI=LCI, Under5_UCI=UCI)
# # # # # # # # # # # # # # # # # # # # # # # # # # # 
RiskSimp_Results_Adj <- full_join(exneo_risksimp_exp, neo_risksimp_exp, by="Variable") %>%
  full_join(postneo_risksimp_exp, by="Variable") %>%
  full_join(infant_risksimp_exp, by="Variable") %>%
  full_join(child_risksimp_exp, by="Variable") %>%
  full_join(under5_risksimp_exp, by="Variable") %>% 
  mutate(order=case_when(Variable=="NoExtraRisk (ref)"  ~ 1,
                         Variable=="UnavoidFirst"    ~ 2,
                         Variable=="Single" ~ 3,
                         Variable== "Double"  ~ 4,
                         Variable=="Triple"  ~ 5,
                         Variable==   "Total N" ~ 6)) %>%
  arrange(order) %>% select(-order)

#write.csv(RiskSimp_Results_Adj, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Adjusted Relative Risk of Mortality by the Mothers Fertility Related Risk Simplified.csv", row.names = F, na="")


header12a <- c("Table 12. Adjusted relative risk of mortality by the mother's fertility related risk, children born 0 to 179 months prior to the survey, simplified, 84 DHS surveys, 2012 to 2022", "" , "")
header12b <- c("", "", "URR")
header12c <- c("", "Early Neonatal", "CI-")
header12d <- c("", "", "CI+")
header12e <- c("", "", "URR")
header12f <- c("", "Neonatal", "CI-")
header12g <- c("", "", "CI+")
header12h <- c("", "", "URR")
header12i <- c("", "Post-neonatal", "CI-")
header12j <- c("", "", "CI+")
header12k <- c("", "", "URR")
header12l <- c("", "Infant", "CI-")
header12m <- c("", "", "CI+")
header12n <- c("", "", "URR")
header12o <- c("", "Child", "CI-")
header12p <- c("", "", "CI+")
header12q <- c("", "", "URR")
header12r <- c("", "Under five", "CI-")
header12s <- c("", "", "CI+")


header12 <- data.frame(header12a, header12b, header12c, header12d, header12e, header12f, header12g, header12h, header12i, header12j, header12k, header12l, header12m, header12n, header12o, header12p, header12q, header12r, header12s)

footer12 <- c("Note: Ajusted models included the following variables", 
              "ENN, NN, PNN, and Infant Mortality: Sex of index child, urban or rural area of residence, wantedness of child, mother's education, whether conception was a result of contraceptive failure, outcome of preceding pregnancy (live birth or stillbirth), type of provider of prenatal care, type of provider of delivery assistance, number of prenatal tetanus injections, timing of first prenatal care visit,quintile of DHS Wealth Index, type of water supply, type of toilet facility, possession of refrigerator, duration of pregnancy, and whether preceding child died before conception of index child.", 
              "Child and Under Five Mortality: Sex of index child, urban or rural area of residence, mother's education, quintile of Wealth Index, type of water supply, type of toilet facility, possession of refrigerator, duration of pregnancy, and whether preceding child died before conception of index child.",
              "Age range of analysis:",
              "ENN, NN, PNN, and Infant Mortality: 0 to 59 months",
              "Child and Under Five Mortality: 0 to 179 months")
footer12 <- data.frame(footer12)

#write.table(header12, file = "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Adjusted Relative Risk of Mortality by the Mothers Fertility Related Risk Simplified.csv",sep=",",  na="", append=FALSE, row.names=FALSE, col.names = FALSE)
#write.table(RiskSimp_Results_Adj, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Adjusted Relative Risk of Mortality by the Mothers Fertility Related Risk Simplified.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)
#write.table(footer12, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Adjusted Relative Risk of Mortality by the Mothers Fertility Related Risk Simplified.csv",sep=",",  na="", append=TRUE, row.names=FALSE, col.names = FALSE)


########################################################################################
# Graphics comparing to 2014 Report
Interval_Results_Adj_clean <- Interval_Results_Adj  %>%
  gather(Var, Value, EarlyNeonatal_uRR:Under5_UCI) %>%
  separate(Var, c("Mortality", "Type"), sep="_") %>%
  spread(Type, Value) %>%
  filter(Variable != "Total N" ) %>%
  mutate(Variable=case_when(Variable=="M12to17" ~ "12-17" ,
                            Variable== "M18to23"  ~ "18-23" ,
                            Variable== "M24to29"  ~ "24-29"  ,
                            Variable==  "M30to35" ~ "30-35" ,
                            Variable=="M3647 (ref)" ~ "36-47 (ref)",
                            Variable=="M48to59" ~ "48-59" ,
                            Variable== "M6to11" ~   "6-11" ,
                            Variable== "M60to95" ~ "60-95" ,
                            Variable=="M96P" ~ "96 Plus" ,
                            Variable=="FirstBorn" ~ "First Birth" ,
                            Variable== "Under6"   ~ "Under 6" )) %>%
  mutate(Mortality=case_when(Mortality =="Child"  ~  "Child" ,
                             Mortality ==   "EarlyNeonatal" ~ "Early Neonatal",
                             Mortality =="Infant" ~ "Infant" ,
                             Mortality == "Neonatal" ~  "Neonatal" ,
                             Mortality == "PostNeonatal"  ~  "Post Neonatal",
                             Mortality ==  "Under5" ~ "Under Five"    )) %>%
  mutate(Report="2023 Analysis") %>%
  rename(aRR=uRR, CILower=LCI, CIUpper=UCI) %>%
  mutate(aRR=as.numeric(as.character(aRR)),
         CILower=as.numeric(as.character(CILower)),
         CIUpper=as.numeric(as.character(CIUpper))) %>%
  select(Report, Mortality, Variable, aRR, CILower, CIUpper) %>%
  bind_rows(spacing_2014) %>%
  mutate(Mortality = fct_relevel(Mortality, c("Early Neonatal",    "Neonatal",   "Post Neonatal" ,  "Infant",    "Child"  ,   "Under Five"  ))) %>%
  mutate(Variable = fct_relevel(Variable, c( "First Birth" ,     "96 Plus",   "60-95" , "48-59"  ,      "36-47 (ref)",     "30-35" ,       "24-29" ,     "18-23",   "12-17",  "6-11" ,"Under 6" ))) 

     


ggplot(Interval_Results_Adj_clean, aes(x=aRR, y=Variable, color=Report,  shape=Report)) +
  geom_point() +
  geom_errorbarh(aes(xmin=CILower, xmax=CIUpper), height=.3)  +
  facet_grid(~ Mortality) +
  scale_shape_manual(values=c(0, 1)) +
  scale_x_continuous(breaks = c(0.5, 1, 2, 3, 4), labels=c(0.5, 1, 2, 3, 4) , limits = c(0.5, 4)) +
  coord_trans(x = "log10") +
  geom_vline(xintercept = 1) +
  theme_bw() +
  labs(y="") +
  theme(strip.background=element_rect(fill="white"),
        axis.text=element_text(color = "black"),
        panel.grid.minor=element_blank())

ggsave("C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Figure 1 Interval Graphic ARR.png", height = 5, width = 13, units = "in")


Mothers_age_Results_Adj_clean <- Mothers_age_Results_Adj  %>%
  gather(Var, Value, EarlyNeonatal_uRR:Under5_UCI) %>%
  separate(Var, c("Mortality", "Type"), sep="_") %>%
  spread(Type, Value)  %>%
  filter(Variable != "Total N" ) %>%
  mutate(Variable=case_when(Variable== "Age1824 (ref)"  ~ "18-24 (ref)" ,
                            Variable=="Age2534"  ~ "25-34" ,
                            Variable== "Age3539" ~ "35-39",
                            Variable== "Age40P" ~  "40 or More"  ,
                            Variable=="AgeU18"   ~ "Under 18"  )) %>%
  mutate(Mortality=case_when(Mortality =="Child"  ~  "Child" ,
                             Mortality ==   "EarlyNeonatal" ~ "Early Neonatal",
                             Mortality =="Infant" ~ "Infant" ,
                             Mortality == "Neonatal" ~  "Neonatal" ,
                             Mortality == "PostNeonatal"  ~  "Post Neonatal",
                             Mortality ==  "Under5" ~ "Under Five"    ))  %>%
  mutate(Report="2023 Analysis") %>%
  rename(aRR=uRR, CILower=LCI, CIUpper=UCI) %>%
  mutate(aRR=as.numeric(as.character(aRR)),
         CILower=as.numeric(as.character(CILower)),
         CIUpper=as.numeric(as.character(CIUpper))) %>%
  select(Report, Mortality, Variable, aRR, CILower, CIUpper) %>%
  bind_rows(matage_2014) %>%
  mutate(Mortality = fct_relevel(Mortality, c("Early Neonatal",    "Neonatal",   "Post Neonatal" ,  "Infant",    "Child"  ,   "Under Five"  ))) %>%
  mutate(Variable = fct_relevel(Variable, c("40 or More", "35-39",  "25-34" ,  "18-24 (ref)" , "Under 18" ))) 



ggplot(Mothers_age_Results_Adj_clean, aes(x=aRR, y=Variable, color=Report,  shape=Report)) +
  geom_point() +
  geom_errorbarh(aes(xmin=CILower, xmax=CIUpper), height=.3)  +
  facet_grid(~ Mortality) +
  scale_shape_manual(values=c(0, 1)) +
  scale_x_continuous(breaks = c(0.5, 1, 2, 3), labels=c(0.5, 1, 2, 3) , limits = c(0.5, 3)) +
  coord_trans(x = "log10") +
  geom_vline(xintercept = 1) +
  theme_bw() +
  labs(y="") +
  theme(strip.background=element_rect(fill="white"),
        axis.text=element_text(color = "black"),
        panel.grid.minor=element_blank())

ggsave("C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Figure 2 Mothers Age Graphic ARR.png", height = 4, width = 13, units = "in")


levels(as.factor(matage_2014$Variable))
levels(as.factor(Mothers_age_Results_Adj$Variable))



BirthOrder_Results_Adj_clean <- BirthOrder_Results_Adj  %>%
  gather(Var, Value, EarlyNeonatal_uRR:Under5_UCI) %>%
  separate(Var, c("Mortality", "Type"), sep="_") %>%
  spread(Type, Value)  %>%
  filter(Variable != "Total N" ) %>%
  mutate(Variable=case_when(Variable== "BO12 (ref)" ~  "1 to 2 (ref)",
                            Variable==  "BO34"  ~  "3 to 4" ,
                            Variable==   "BO56"  ~ "5 to 6" ,
                            Variable==   "BO7P"  ~  "7 or More"    )) %>%
  mutate(Mortality=case_when(Mortality =="Child"  ~  "Child" ,
                             Mortality ==   "EarlyNeonatal" ~ "Early Neonatal",
                             Mortality =="Infant" ~ "Infant" ,
                             Mortality == "Neonatal" ~  "Neonatal" ,
                             Mortality == "PostNeonatal"  ~  "Post Neonatal",
                             Mortality ==  "Under5" ~ "Under Five"    ))  %>%
  mutate(Report="2023 Analysis") %>%
  rename(aRR=uRR, CILower=LCI, CIUpper=UCI) %>%
  mutate(aRR=as.numeric(as.character(aRR)),
         CILower=as.numeric(as.character(CILower)),
         CIUpper=as.numeric(as.character(CIUpper))) %>%
  select(Report, Mortality, Variable, aRR, CILower, CIUpper) %>%
  bind_rows(parity_2014) %>%
  mutate(Mortality = fct_relevel(Mortality, c("Early Neonatal",    "Neonatal",   "Post Neonatal" ,  "Infant",    "Child"  ,   "Under Five"  ))) %>%
  mutate(Variable = fct_relevel(Variable, c( "7 or More" , "5 to 6" , "3 to 4" , "1 to 2 (ref)" ))) 

levels(as.factor(parity_2014$Variable))
levels(as.factor(BirthOrder_Results_Adj_clean$Variable))

ggplot(BirthOrder_Results_Adj_clean, aes(x=aRR, y=Variable, color=Report,  shape=Report)) +
  geom_point() +
  geom_errorbarh(aes(xmin=CILower, xmax=CIUpper), height=.3)  +
  facet_grid(~ Mortality) +
  scale_shape_manual(values=c(0, 1)) +
  scale_x_continuous(breaks = c(0.5, 1, 2), labels=c(0.5, 1, 2) , limits = c(0.5, 2)) +
  coord_trans(x = "log10") +
  geom_vline(xintercept = 1) +
  theme_bw() +
  labs(y="") +
  theme(strip.background=element_rect(fill="white"),
        axis.text=element_text(color = "black"),
        panel.grid.minor=element_blank())

ggsave("C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Result Tables/Figure 3 Birth Order Graphic ARR.png", height = 4, width = 13, units = "in")
