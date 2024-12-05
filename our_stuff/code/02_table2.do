/*

step 2: replicate Table 1 from the ABE paper

*/

clear all
frames reset

global route "/Users/tmorg46/Desktop/abe2014_replication/our_stuff"


******************************************************
* Replicate their Table 1 - Sample Sizes & Match Rates
******************************************************
// pending
*we need to get 1900 baseline number-in-universe counts, so we'll loop through our pooled-cs and panel specifications:
foreach spec in pcs links {
		
	*open the canadian version first:
	use if year==1900 using "${route}/intermediate_datasets/canada_`spec'.dta", clear
		
	*loop through the two birthplaces
	foreach bpl_name in USA Canada {
		
		qui sum year if bpl_name=="`bpl_name'"
		local `spec'_`bpl_name'_men = r(N) // this stores the count in a local!
		
	}

	*now let's go get the ladies:
	use if year==1900 using "${route}/intermediate_datasets/women_`spec'.dta", clear

	*and now loop through all the countries:
	levelsof bpl_name, local(bpl_names) // get them all into a list in a local

	foreach bpl_name of local bpl_names { // and loop through that local!
		
		qui sum year if bpl_name=="`bpl_name'"
		local `spec'_`bpl_name'_women = r(N)
		
	}
}


*now calculate the link rates and put them in even more locals!
foreach bpl_name in USA Canada { // start with the men

	local linkrate_`bpl_name'_men = `links_`bpl_name'_men' / `pcs_`bpl_name'_men'

}

foreach bpl_name of local bpl_names { // and now the women:

	local linkrate_`bpl_name'_women = `links_`bpl_name'_women' / `pcs_`bpl_name'_women'
	
}


*and put everything into a matrix for the table later!!
matrix men = J(2,3,.)

matrix rownames men = Canada USA

matrix men[1,1] = `pcs_Canada_men'
matrix men[1,2] = `links_Canada_men'
matrix men[1,3] = `linkrate_Canada_men'

matrix men[2,1] = `pcs_USA_men'
matrix men[2,2] = `links_USA_men'
matrix men[2,3] = `linkrate_USA_men'

matrix men_count = men[1..., 1..2]
matrix men_rates = men[1..., 3] // this splits the matrix so we can format the numbers nicely later


*now put the women's results into their own separate matrix:
matrix women = J(17,3,.) // the 16 sending countries + USA each get a row

matrix rownames women = ///
	Austria Belgium Denmark ///
	England Finland France	///
	Germany Ireland Italy	///
	Norway Portugal Russia	///
	Scotland Sweden 		///
	Switzerland Wales USA		// we've named the rows of this matrix now, so it's nice later!

local count = 1 // this will let us iterate through countries by row

foreach bpl_name in ///
	Austria Belgium Denmark ///
	England Finland France	///
	Germany Ireland Italy	///
	Norway Portugal Russia	///
	Scotland Sweden 		///
	Switzerland Wales USA {		// I want this specific order for the table
	
	matrix women[`count',1] = `pcs_`bpl_name'_women'
	matrix women[`count',2] = `links_`bpl_name'_women'
	matrix women[`count',3] = `linkrate_`bpl_name'_women'
	
	local count = `count' + 1
}

matrix women_count = women[1..., 1..2]
matrix women_rates = women[1..., 3] // this splits the matrix so we can format the numbers nicely later:


*now it's time to put together the table into an Excel file:
putexcel set "${route}/output/tables", sheet(table1, replace) modify // we're replacing the table1 sheet but modifying the document as a whole; this avoids deleting other tables later but still lets us refresh this table on each rerun

putexcel A1  = "Country"		///
		 B1  = "1900 Sample"	///
		 C1  = "Linked Sample"	///
		 D1  = "Link Rate"

putexcel A2  = "Men"
putexcel A3  = matrix(men_count), rownames nformat(#,###)
putexcel D3  = matrix(men_rates), nformat(#.000)
		 

putexcel A5  = "Women"
putexcel A6  = matrix(women_count), rownames nformat(#,###)
putexcel D6  = matrix(women_rates), nformat(#.000)

// and now we're done! we can hand put it into LaTeX because then it will be pretty :)










