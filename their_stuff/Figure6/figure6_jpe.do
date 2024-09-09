
/**This file creates the coefficients underlying Figure 6. It uses the panel data and ipums data as inputs and outputs a file with differences between first generation immigrants and natives as well as second generation immigrants and natives. The output file is called "f1st2ndGen_onePtPerCtry.dta"


* INPUT:
*  NATIVES_2NDGEN_SAMPLES: natives_and_2nd_gen.dta   (created by build_samples_from_IPUMS.do which reads in downloadable IPUMS data)
*  IMMIG_PANEL           : panel_all_forjpe.dta 
*  
* OUTPUT:
*  Graphs showing age profiles of occscore by country of origin for immigrants, cohorts in which their children should be,
*  and natives.
*
* REQUIRES:
*  addFakeObs.ado
*/


/***************************************************
 * Initialize
 ***************************************************/

clear all
set mem 200m

cap log close
log using plot_graphs.log, text replace

global NATIVES_2NDGEN_SAMPLES "IPUMS_2nd_gen_natives"
global IMMIG_PANEL "panel_all_01_var_subset"

// The following variables will be used in the regression.
// MAKE SURE that if you change the varlists, CHANGE THE addFakeObs PROGRAM in addFakeObs.ado
// that creates the fake ("representative") observations TO CALCULATE ALL THE VARIABLES THAT YOU ASK FOR IN THE REGRESSION
global ageProfVars	 "age age35 ageXage35"    // enter the variables acting as age profile (e.g age age2 age3)
// global ageProfVars	 "age age2 age3 age4"    // enter the variables acting as age profile (e.g age age2 age3)

global yrsUSProfVars "Iyrsusa2_*" 			 // enter the variables acting as years-in-US profile (e.g _YUSyrsusa2_*)
global controls		 ""						// enter additional controls ("marital" appeared in Ran's do-file, but is absent from Leah & Katherine's)

// y-axis range, if you want it fixed (if not, make sure global is empty
global yLabelRange "18(2)30"
global xLabelRange   "20(10)55"

global outcomes      "occscore_all"	// enter 

global COUNTRIES 	 "400 401 404 405 410 411 412 414 420 421 426 434 436 450 453 465"
// global COUNTRIES 	 "404 410"
global countryPrefix "Tbpl1_"

global firstGen_years_min  = 1900
global firstGen_years_max  = 1920
global secondGen_years_min = 1920
global secondGen_years_max = 1950

foreach gen in first second {
	global `gen'Gen_years_cond "inrange(year, ${`gen'Gen_years_min}, ${`gen'Gen_years_max})"
}

global firstGenSample 	"(sample == 1)"
global secondGenSample 	"(sample == 2)"
global nativesSample  	"(sample == 5)"

global group_firstGen_id			= 1
global group_firstGen_lab			"Immigrants, ${firstGen_years_min}-${firstGen_years_max}"
global group_secondGen_id			= 2
global group_secondGen_lab			"Sons of immigrants, ${secondGen_years_min}-${secondGen_years_max}"
global group_firstGens_natives_id	= 3
global group_firstGens_natives_lab	"Sons of US born parents, ${firstGen_years_min}-${firstGen_years_max}"
global group_secondGens_natives_id	= 4
global group_secondGens_natives_lab	"Sons of US born parents, ${secondGen_years_min}-${secondGen_years_max}"

foreach group in firstGen secondGen firstGens_natives secondGens_natives {
	label define groups ${group_`group'_id} "${group_`group'_lab}", add
}

// These are used to cut the sample
global urban_cond = "(urban == 1)"
global rural_cond = "(urban == 0)"
global all_cond   = "inlist(urban, 0, 1)"

// These are used to read the results of the appropriate regression
global urban_flag = 1
global rural_flag = 0
global all_flag   = 9

global urban_urb_control ""
global rural_urb_control ""
global all_urb_control   ""

global urbanCutoffForPanel = .4

global fakeObsSample = 99

global fakeObsAgeIn1stYear 	= 25
global fakeObsImmigYear 	= 1890

global sampleMinAge = 20
global sampleMaxAge = 60

/***************************************************
 * Load datasets and append one to the other
 ***************************************************/
use 			${IMMIG_PANEL} 
append using 	${NATIVES_2NDGEN_SAMPLES}
replace sample = 1 if sample == .

/************* EXCLUDE THE SOUTH *******************/
// Excluding the 11 confederate states from the sample of natives and 2ndgens
drop if inlist(statefip, 1, 5, 12, 13,  22, 28, 37, 45, 47, 48, 51)

label variable occscore_all "Occupation score"

replace urban = (shurb1 > ${urbanCutoffForPanel}) if sample == 1 & !missing(shurb1)

// Many migrants are missing the shurb1 var so I am imputing them with "urban in at least one year" if they are missing
tempvar tempegen
egen `tempegen' = max(urban*(year==1900)) if sample == 1, by(bpl idnum_1900*)
replace urban = `tempegen' if urban == . & sample == 1
drop `tempegen'


// Italy used to be the base group so there was no variable for it in the Panel
replace ${countryPrefix}434 = 1 if bpl == 434 & sample == 1

xi i.statefip, prefix(_S)
xi i.year    , prefix(_Y)

/***************************************************
 * Run regressions, predict and save results for a representative individual
 ***************************************************/

// start by generating variables that will contain the predicted value for the fake obs.
foreach outcome of varlist $outcomes {
	gen `outcome'_hat = .
}
gen group = .
gen N_in_reg = .
gen urban_sample = .

label define urban_sample 0 "Rural" 1 "Urban" 9 "Pooled"
label values urban_sample urban_sample

// Now to actual regressions...
// First, for the natives -- who don't change when we draw another country's graph --
// run four regressions:
// 1. Urban natives in censuses 1900-1920
// 2. Urban natives in censuses 1920-1950
// 3. Rural natives in censuses 1900-1920
// 4. Rural natives in censuses 1920-1950
foreach outcome of varlist $outcomes {
	foreach geo in urban rural all {
		foreach comparingTo in firstGen secondGen {
			di " "
			di as input "reg `outcome' ${ageProfVars} ${controls} ${`geo'_urb_control} /* _S* */ _Y* if (${`geo'_cond}) & ${`comparingTo'_years_cond} & ${nativesSample}  & inrange(age, $sampleMinAge, $sampleMaxAge)"

			reg `outcome' ${ageProfVars} ${controls} ${`geo'_urb_control} /* _S* */ _Y* ///
					if (${`geo'_cond}) & ${`comparingTo'_years_cond} & ${nativesSample} & inrange(age, $sampleMinAge, $sampleMaxAge)
			
			addFakeObs `outcome'_hat , years(${`comparingTo'_years_min}(10)${`comparingTo'_years_max}) age1styear(${fakeObsAgeIn1stYear})
			
			local inCond = r(inCond)
			
			replace urban_sample = ${`geo'_flag}				`inCond'
			replace group = ${group_`comparingTo's_natives_id} 	`inCond'
			
			replace N_in_reg = e(N)								`inCond'
			
			//debug
			ereturn list
			list N_in_reg `inCond'
			
		}
	}
}

global firstGen_addl_covars  "${yrsUSProfVars}"
global secondGen_addl_covars ""

global firstGen_addl_fakeObs_args  "immig imyear(${fakeObsImmigYear})"
global secondGen_addl_fakeObs_args ""

foreach country in $COUNTRIES {
	local ctry_name : label bpl_lbl `country'
	di as input "Predicting for `ctry_name' (`country')"
	di			"====================================="
	tab sample if ${countryPrefix}`country' == 1
	tab sample urban if ${countryPrefix}`country' == 1
	
	foreach outcome of varlist $outcomes {
		foreach geo in urban rural all {
			foreach generation in first second {
				di " "
				di as input "reg `outcome' ${ageProfVars} ${`generation'Gen_addl_covars} ${controls} /* _S* */ _Y* if (${`geo'_cond}) & ${`generation'Gen_years_cond} & ${`generation'GenSample} & (${countryPrefix}`country' == 1)"

				cap noisily reg `outcome' ${ageProfVars} ${`generation'Gen_addl_covars} ${controls} ${`geo'_urb_control} /* _S* */ _Y* ///
						if 	(${`geo'_cond}) & ///
							${`generation'Gen_years_cond} & ///
							${`generation'GenSample} & ///
							(${countryPrefix}`country' == 1)
				
				if (_rc == 0) {   // if the regression had no error, predict
					addFakeObs `outcome'_hat , years(${`generation'Gen_years_min}(10)${`generation'Gen_years_max})  age1styear(${fakeObsAgeIn1stYear}) ${`generation'Gen_addl_fakeObs_args}
					
					local inCond = r(inCond)
					
					replace urban_sample = ${`geo'_flag}		`inCond'
					replace group = ${group_`generation'Gen_id} `inCond'
					replace ${countryPrefix}`country' = 1		`inCond'
					replace N_in_reg = e(N)						`inCond'
				}
				else {
					exit
				}
			}
		}
	}
}

label values group groups


/************************************************
 * Record differences between 1st gen and natives, and then 2nd gen and natives, for each country, for those aged 35
 * (20 years in the U.S if 1st gen immigrant). Save these to f1st2ndGen_onePtPerCtry.dta. The pooled values of these are then used in Figure 6.
 ************************************************/
postfile onePtPerCtryGen str32 outcome str30 sample str50 country ctry_code fst_gen_diff snd_gen_diff reg_n_obs_1st reg_n_obs_2nd using f1st2ndGen_onePtPerCtry.dta, replace
foreach outcome in $outcomes {
	foreach urban_sample in 0 1 9 {
		local sample_name : label urban_sample `urban_sample'
		su `outcome'_hat if urban_sample == `urban_sample' & age == 35 & group == 3
		local natives_1stgen_comparable = r(mean)
		
		su `outcome'_hat if urban_sample == `urban_sample' & age == 35 & group == 4
		local natives_2ndgen_comparable = r(mean)
		
		foreach country in $COUNTRIES {
			local ctry_name : label bpl_lbl `country'
			
			su `outcome'_hat if urban_sample == `urban_sample' & age == 35 & group == 1 & Tbpl1_`country' == 1
			local diff_1stgen = `r(mean)' - `natives_1stgen_comparable'
			
			su N_in_reg      if urban_sample == `urban_sample' & age == 35 & group == 1 & Tbpl1_`country' == 1
			local n_reg_1st = `r(mean)'
			
			su `outcome'_hat if urban_sample == `urban_sample' & age == 35 & group == 2 & Tbpl1_`country' == 1
			local diff_2ndgen = `r(mean)' - `natives_2ndgen_comparable'

			su N_in_reg      if urban_sample == `urban_sample' & age == 35 & group == 2 & Tbpl1_`country' == 1
			local n_reg_2nd = `r(mean)'

			post onePtPerCtryGen ("`outcome'") ("`sample_name'") ("`ctry_name'") (`country') (`diff_1stgen') (`diff_2ndgen')  (`n_reg_1st') (`n_reg_2nd')
		}
	}
}

postclose onePtPerCtryGen

log close

