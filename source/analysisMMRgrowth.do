/* analysisMMRgrowth.do v0.00   damiancclarke              yyyy-mm-dd:2014-03-02
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

I suggest that for graphs and regs we focus upon changes on changes (ie delta M-
R on delta-logGDP) and in the WHO panel note that we are taking 5-year differen-
es of each var , thereby allowing time for changes in income to impact mmr.
* Repeating this on the annual DHS panel, we should compare results using it as
it is with annual-changes and then using 5-yearly changes.
* Note that in a reg of dY on dX with FE on the RHS, the FE are capturing trends.
So you could run without FE and then include FE (following the tradition - as in
the mmr-edu tables of seeing whether trends matter).

To understand the long run relationships it is useful to look additionally at
(a) absolute levels on levels ie (MMR) on (log GDP) - this is like our mmr-ed
paper
(b) proportional changes ie (delta *log* MMR) on delta-logGDP
See esp slide-12 of my attd lec slides.
Sonia

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) globals and locals
********************************************************************************
global DAT "~/investigacion/2015/growthMMR/data"
global OUT "~/investigacion/2015/growthMMR/results"
global LOG "~/investigacion/2015/growthMMR/log"

log using "$LOG/analysisMMRgrowth.txt", text replace
cap mkdir "$OUT/regression"
cap mkdir "$OUT/plot"

********************************************************************************
*** (2) open data, gen variables
********************************************************************************
use "$DAT/MMRgrowth"
drop _merge*
destring IMR, replace

bys country (year): gen deltaMMR    = MMR[_n+1]-MMR[_n]
bys country (year): gen deltalogMMR = ln_MMR[_n+1]-ln_MMR[_n]
bys country (year): gen deltalogGDP = ln_GDPpc[_n+1]-ln_GDPpc[_n]

encode country, gen(cc)

gen M_yr_sch_sq = M_yr_sch*M_yr_sch
gen F_yr_sch_sq = F_yr_sch*F_yr_sch


********************************************************************************
*** (3) Regressions
********************************************************************************
reg deltaMMR deltalogGDP, robust
reg deltaMMR deltalogGDP i.year, robust
outreg2 using "$OUT/regression/deltaMMR_deltalnGDP.xls", replace excel
areg deltaMMR deltalogGDP i.year, abs(cc) robust
outreg2 using "$OUT/regression/deltaMMR_deltalnGDP_FE.xls", replace excel

reg deltalogMMR deltalogGDP, robust
reg deltalogMMR deltalogGDP i.year, robust
outreg2 using "$OUT/regression/deltalnMMR_deltalnGDP.xls", replace excel
areg deltalogMMR deltalogGDP i.year, abs(cc) robust
outreg2 using "$OUT/regression/deltalnMMR_deltalnGDP_FE.xls", replace excel

reg MMR ln_GDPpc, robust
reg MMR ln_GDPpc i.year, robust
outreg2 using "$OUT/regression/MMR_lnGDP.xls", replace excel
areg MMR ln_GDPpc i.year, abs(cc) robust
outreg2 using "$OUT/regression/MMR_lnGDP_FE.xls", replace excel


local c1 F_yr_sch F_yr_sch_sq M_yr_sch M_yr_sch_sq
local c2 `c1' percentattend
local c3 `c2' Immunization
local c4 `c3' TeenBirths
local c5 `c4' IMR
local c6 `c5' fertility

foreach num of numlist 1(1)6 {
    reg deltaMMR deltalogGDP `c`num'', robust
    reg deltaMMR deltalogGDP i.year `c`num'', robust
    outreg2 using "$OUT/regression/deltaMMR_deltalnGDP.xls", append excel
    areg deltaMMR deltalogGDP i.year `c`num'', abs(cc) robust
    outreg2 using "$OUT/regression/deltaMMR_deltalnGDP_FE.xls", append excel

    reg deltalogMMR deltalogGDP `c`num'', robust
    reg deltalogMMR deltalogGDP i.year `c`num'', robust
    outreg2 using "$OUT/regression/deltalnMMR_deltalnGDP.xls", append excel
    areg deltalogMMR deltalogGDP i.year `c`num'', abs(cc) robust 
    outreg2 using "$OUT/regression/deltalnMMR_deltalnGDP_FE.xls", append excel

    reg MMR ln_GDPpc `c`num'', robust
    reg MMR ln_GDPpc i.year `c`num'', robust
    outreg2 using "$OUT/regression/MMR_lnGDP.xls", append excel
    areg MMR ln_GDPpc i.year `c`num'', abs(cc) robust 
    outreg2 using "$OUT/regression/MMR_lnGDP_FE.xls", append excel
}

********************************************************************************
*** (4) Plot
********************************************************************************
scatter deltaMMR deltalogGDP if deltaMMR<500, scheme(s1color)
graph export "$OUT/plot/deltaMMR_deltalnGDP.eps", as(eps) replace

scatter deltalogMMR deltalogGDP, scheme(s1color)
graph export "$OUT/plot/deltalnMMR_deltalnGDP.eps", as(eps) replace

scatter MMR ln_GDPpc, scheme(s1color)
graph export "$OUT/plot/MMR_lnGDP.eps", as(eps) replace

collapse delta* MMR ln_GDPpc, by(country)
scatter deltaMMR deltalogGDP if deltaMMR<500, scheme(s1color)
graph export "$OUT/plot/deltaMMR_deltalnGDP_average.eps", as(eps) replace

scatter deltalogMMR deltalogGDP, scheme(s1color)
graph export "$OUT/plot/deltalnMMR_deltalnGDP_average.eps", as(eps) replace

scatter MMR ln_GDPpc, scheme(s1color)
graph export "$OUT/plot/MMR_lnGDP_average.eps", as(eps) replace


********************************************************************************
*** (X) Close
********************************************************************************
log close
