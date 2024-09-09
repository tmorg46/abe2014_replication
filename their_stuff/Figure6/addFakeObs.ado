
/***************************************************
 * A program that creates fake, or dummy, observations to predict 
 * an outcome variable from the covariates. The observations will be added
 * to the bottom of the dataset and will contain sample == ${fakeObsSample}
 * in order to flag them as such.
 *
 * Requires two globals to be set:
 * $fakeObsSample   (the sample id the program will give fake observations)
 * $countryPrefix   (the prefix of the country dummy variables to turn into 0)
 ***************************************************/
program define addFakeObs, rclass
	syntax varname, ///
					Years(numlist ascending) [AGE1styear(integer 25) ///
					IMMig IMYear(integer 1890)]
	quietly {
		// See how many years were requested, to know how many obs to add (one data point for each year)
		numlist "`years'"
		local data_points : word count `r(numlist)'
		
		// Add as many new obs as new data points (one for each year)
		local currentObs = _N
		local newObs = `currentObs' + `data_points'
		set obs `newObs'
		
		local fromObs = `currentObs' + 1   // will contain the obs num of the first newly created obs
		
		// Filling some first variables: 
		// (1) sample code
		replace sample = ${fakeObsSample} 				in `fromObs'/`newObs'
		
		// (2) state, year and country dummies with zeros
		foreach var of varlist _S* _Y* ${countryPrefix}* {
			replace `var' = 0 							in `fromObs'/`newObs'
		}
		// our representative guy will be from statefip == 27 (Minnesota)
		replace _Sstatefip_27 = 1 						in `fromObs'/`newObs'
		
/*		// the representative guy will be urban (when the regression is split to urban rural it doesn't play any role... 
		// it only matters for the pooled reg)
		replace urban = 1								in `fromObs'/`newObs'
	*/	
		// the proper year dummy will depend on the observation.
		
		// Give each new obs a different year.
		local obs_i = `fromObs'
		foreach year of numlist `years' {
		
			replace year = `year' in `obs_i'   // each obs will get a different year

			cap replace _Yyear_`year' = 1 			in `obs_i'
			
			local ++obs_i
		}
		
		// setting the age
		// In the first observation age is the argument passed to the program.
		// In the next ones it is the age of the previous obs + the year difference since then (10 usually)
		replace age  = cond(_n == `fromObs', `age1styear', age[_n-1] + (year - year[_n-1])) in `fromObs'/`newObs'
		
		// This is the place to add the variables that change with year or are a function of age etc
		forvalues power = 2/4 {
			replace age`power' = age^`power' in `fromObs'/`newObs'
		}
		replace age35 = age >= 35 in `fromObs'/`newObs'
		replace ageXage35 = age * age35 in `fromObs'/`newObs'
		
		if ("`immig'" != "") {
			replace yrimmig = `imyear'					in `fromObs'/`newObs'
			replace yrsusa1 = year - `imyear' 			in `fromObs'/`newObs'
			tempvar yrsusa2_4_egen
			egen `yrsusa2_4_egen' = cut(yrsusa1) 		in `fromObs'/`newObs', ///
								at(0 .01 5.01 10.01 20.01 30.01 999) icodes
			replace yrsusa2 = `yrsusa2_4_egen' in `fromObs'/`newObs'
			drop `yrsusa2_4_egen'
			
			forvalues i = 1/5 {
				replace Iyrsusa2_`i' = yrsusa2 == `i' 	in `fromObs'/`newObs'
			}
		}
		
		tempvar temp
		predict `temp'
		replace `varlist' = `temp' 						in `fromObs'/`newObs'
		
		qui su `varlist' 								in `fromObs'/`newObs'
		if (r(N) == 0) {
			di as error "Predicted value missing for all observations. Maybe a variable generation is missing in addFakeObs"
		}
		return local inCond 							"in `fromObs'/`newObs'"
	}
	di as text "Added `data_points' observations for years `years', a person aged `age1styear' in the first year" ///
			cond("`immig'" != "", ", immigrated in `imyear'", "")
end
	