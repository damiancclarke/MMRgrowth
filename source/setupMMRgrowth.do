/* setupMMRgrowth.do v1.00       damiancclarke             yyyy-mm-dd:2015-02-28
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file generates country-level observations for maternal mortality and econo-
mic growth rates, along with a number of other time-varying covariates related
to health, income and access. It generates the file MMRgrowth.dta.


It requires the following data sources:
  > BL2013_F_v2.0.dta: Barro-Lee education data (female)
  > BL2013_M_v2.0.dta: Barro-Lee education data (male)
  > MM_Base          : WHO MMR database


*/

clear all
version 11
set more off
cap log close

********************************************************************************
*** (1) globals
********************************************************************************
global DAT "~/investigacion/2015/growthMMR/data"
global COD "~/investigacion/2015/growthMMR/source"
global LOG "~/investigacion/2015/growthMMR/log"
    
log using "$LOG/setupMMR.txt", text replace


********************************************************************************
*** (2) Create Barro-Lee data set with male and female education
********************************************************************************
use "$DAT/BL2013_M_v2.0.dta"
foreach var of varlist lu lp lpc ls lsc lh lhc yr_sch yr_sch_* {
    rename `var' M_`var'
}
keep M_*  country year agefrom ageto 
merge 1:1 country year agefrom ageto using "$DAT/BL2013_F_v2.0.dta", gen(_mMF)
drop _mMF

rename agefrom AF
rename ageto   AT

keep if AF==15&AT==19|AF==20&AT==24|AF==25&AT==29|AF==30&AT==34|AF==35&AT==39
collapse *_lu *_lp *_ls *_lh *_yr_sch*, by(country year WBcode region_code)

********************************************************************************
*** (3) Merge Barro-Lee with MMR
********************************************************************************
replace country="Libya"                     if country=="Libyan Arab Jamahiriya"
replace country="Cote d'Ivoire"             if country=="Cote dIvoire"
replace country="Dominican Republic"        if country=="Dominican Rep."
replace country="United States of America"  if country=="USA"
replace country="Bolivia (Plurinational State of)"   if country=="Bolivia"
replace country="Venezuela (Bolivarian Republic of)" if country=="Venezuela"

keep if year > 1985
merge m:1 country year using "$DAT/MM_base", gen(_mergeBLMMR)
keep if _mergeBLMMR==3
drop _mergeBLMMR

save "$DAT/MMRgrowth.dta", replace

********************************************************************************
*** (4) Merge Barro-Lee with GDP, other controls
********************************************************************************
local fl GDPpc Immunization fertility population TeenBirths IMR GDPgrowth

foreach var of local fl {
    use "$DAT/WB_`var'", clear
    reshape long v, i(countryname countrycode) j(year)
    rename v `var'
    replace year=year+1957

    do "$COD/WHO_Countrynaming.do"
    keep if year==1990|year==1995|year==2000|year==2005|year==2010

    rename countryname country
    merge m:m country year using "$DAT/MMRgrowth.dta", gen(_merge`var')
    save "$DAT/MMRgrowth.dta", replace
}

use "$DAT/WB_birthphysician", clear
do  "$COD/WHO_Countrynaming.do"
rename countryname country

merge m:m country year using "$DAT/MMRgrowth.dta", gen(_merge`var')
save "$DAT/MMReduc_BASE_F", replace

********************************************************************************
*** (5) Variable creation
********************************************************************************
exit
    
gen ln_yrsch  = log(yr_sch)
gen ln_MMR    = log(MMR)
gen ln_GDPpc  = log(GDPpc)

********************************************************************************
*** (6) Save, clean
********************************************************************************
lab dat "Education and Maternal Mortality by country 1990-2010 (Bhalotra Clarke)"
save "$DAT/MMReduc_BASE_F", replace

log close
