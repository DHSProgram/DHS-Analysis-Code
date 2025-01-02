# # Running IR files with calendars

library(survival)


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

surveys_clean <- surveys %>% select(API_ID, Survey, BR) %>% mutate(IR=paste(Survey, ".DTA", sep="") , BR=paste(BR, ".DTA", sep="")) %>% 
  select(-Survey) %>%
  full_join(spacing, by="API_ID") %>%
  filter(BirthSpacingStudy!="") %>% filter(BirthSpacingStudy!= "NOT INCLUDED")

#surveys_clean <- surveys_clean[54,]

cal_results <- setNames(data.frame(matrix(ncol = 2,  nrow = 0)),  c("Survey", "CalStatus"))  %>%
  mutate(Survey=as.character(Survey),
         CalStatus=as.character(CalStatus))

cal_results_country <- setNames(data.frame(matrix(ncol = 2,  nrow = 1)),  c("Survey", "CalStatus"))  %>%
  mutate(Survey=as.character(Survey),
         CalStatus=as.character(CalStatus))

for (row in 1:nrow(surveys_clean)) {
  women_data <- surveys_clean[row, "IR"]
  countryname <- surveys_clean[row, "API_ID"]
  
  # You will need to reset the directory to where you DHS surveys are stored
  setwd("C:/Users/KristinBietsch/Files/DHSLoop")
  

  women <- read_dta(women_data, col_select = any_of(c("v005",  "v000", "caseid", "v017", "vcal_1" , "vcal_2")))
  
  
  if (exists("vcal_1", women) & !is.na(sum(women$v017))) {
   Cal <- "Calendar"
  } else{
    Cal <- "No Calendar"
  }

  cal_results_country$Survey <- countryname
  cal_results_country$CalStatus <- Cal
 
   cal_results <- bind_rows(cal_results, cal_results_country)
}
###############################################################
cal_results_clean <- cal_results %>% rename(API_ID=Survey) %>% 
  mutate(CalStatus=case_when(API_ID=="BF2003DHS" ~ "Preg Calendar",
                             API_ID=="CM2004DHS" ~ "No Calendar",
                             API_ID=="GA2012DHS" ~ "No Calendar",
                             API_ID=="HT2000DHS" ~ "No Calendar",
                             API_ID=="MD2004DHS" ~ "Preg Calendar",
                             API_ID=="MW2000DHS" ~ "Preg Calendar",
                             API_ID=="MZ2003DHS" ~ "Preg Calendar",
                             API_ID=="SN2005DHS" ~ "Preg Calendar",
                             API_ID=="ST2008DHS" ~ "No Calendar",
                             TRUE ~ CalStatus))

calendar_surveys <- surveys_clean %>% full_join(cal_results_clean, by="API_ID") %>%
  filter(CalStatus=="Calendar")
calendar_surveys_mini <- calendar_surveys %>% select(API_ID, CalStatus)
write.csv(calendar_surveys_mini, "C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/Surveys with Calendar Contraception Data.csv", row.names = F, na="")
####################################################################

#calendar_surveys <- calendar_surveys[116:118,]

for (row in 1:nrow(calendar_surveys)) {
  women_data <- calendar_surveys[row, "IR"]
  countryname <- calendar_surveys[row, "API_ID"]
  
  setwd("C:/Users/KristinBietsch/Files/DHSLoop")
  
  
  women <- read_dta(women_data, col_select = any_of(c("v005",  "v000", "caseid", "v017", "vcal_1" , "vcal_2")))
  
    # set length of calendar in a local macro
    vcal_len <- as.numeric(nchar(women$vcal_1[1]))
    length_data <- seq( vcal_len, 1, -1)
    oplength_data <- seq( 1, vcal_len,  1)
    
    length_data <- data.frame(length_data, oplength_data)
    
    for (row in 1:nrow(length_data)) {
      var <- paste("vcal1_", length_data[row, "oplength_data"], sep="")
      var2 <- paste("vcal2_", length_data[row, "oplength_data"], sep="")
      num <-  paste(length_data[row, "length_data"])
      
      # contraceptive method, non-use, or birth, pregnancy, or termination
      women[[var]] = substr(women$vcal_1, num, num)
      # reason for discontinuation
      women[[var2]]  = substr(women$vcal_2, num, num)
      
    }
    
    if (!exists("vcal2_80", women) ) {
      women$vcal2_80 <- NA
      
    }
    
    women_small <- women %>% select(caseid, v017, vcal1_1:vcal2_80) %>%
      gather(Variable, Value, vcal1_1:vcal2_80) %>% separate(Variable, c("vcal", "month"), sep="_") %>%
      spread(vcal, Value) %>% mutate(month=as.numeric(as.character(month))) %>%
      arrange(caseid, month) %>% mutate(cmc_event=v017 + month- 1) 
    
    # need terminations
    
    birth_analysis1 <- women_small %>% mutate(BirthTerm=case_when(vcal1=="B" | vcal1=="T"  ~ 1,
                                                                  TRUE ~ 0)) %>%
      group_by(caseid) %>%
      mutate(cal_b_episode = cumsum(BirthTerm)-BirthTerm) %>% # Count the B/T's and create and episode ending in a B/T
      mutate(Preg_month=case_when(vcal1=="B" | vcal1=="T" | vcal1=="P" ~ 1,
                                  TRUE ~ 0)) %>% 
      group_by(caseid, cal_b_episode) %>% 
      mutate(Month_Pre_Preg= case_when(Preg_month==0 & lead(Preg_month)==1 ~ 1)) %>%
      mutate(event_Month_Pre_Preg = case_when(Month_Pre_Preg==1 ~ vcal1),
             disc_Month_Pre_Preg = case_when(Month_Pre_Preg==1 ~ vcal2))
    
    
    # assign event_Month_Pre_Preg & disc_Month_Pre_Preg to birth month
    event_Month_Pre_Preg1 <- birth_analysis1 %>% filter(Month_Pre_Preg==1) %>% 
      select(caseid, cal_b_episode, event_Month_Pre_Preg, disc_Month_Pre_Preg) %>%
      rename(event_Month_Pre_Preg1=event_Month_Pre_Preg, disc_Month_Pre_Preg1=disc_Month_Pre_Preg)
    
    # Outcome of preceding pregnancy
    precede_preg <-  birth_analysis1 %>% filter(BirthTerm==1) %>% ungroup() %>%
      group_by(caseid) %>%
      mutate(PrecedingPreg = lag(vcal1)) %>% ungroup() %>%
      select(caseid, cal_b_episode, PrecedingPreg) 
    
    # bring event and discontinuation code back in 
    birth_analysis2 <- birth_analysis1 %>%  left_join(event_Month_Pre_Preg1, by=c("caseid", "cal_b_episode"))   %>%
      left_join(precede_preg, by=c("caseid", "cal_b_episode"))   %>%
      group_by(caseid, cal_b_episode) %>% 
      mutate(Gestation=sum(Preg_month)) %>%
      ungroup() %>%
      filter(vcal1=="B") %>%
      filter(!is.na(event_Month_Pre_Preg1)) %>% # excluding births whose did not have one month or pre-pregnancy in calendar
      mutate(Failure=case_when(disc_Month_Pre_Preg1==1 ~ 1,
                               TRUE ~ 0)) %>%
      rename(b3=cmc_event) %>%
      select(caseid, b3, Gestation, Failure, PrecedingPreg)
    
    write_dta(birth_analysis2, paste("C:/Users/KristinBietsch/files/DHS Data/Birth Spacing Report/WomenBirth/", countryname,"_BirthsinCalendar.dta", sep=""))

}
