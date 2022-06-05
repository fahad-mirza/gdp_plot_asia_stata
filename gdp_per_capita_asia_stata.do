	* Install the following packages (One time install only):
		ssc install palettes, replace
		ssc install colrspace, replace
		ssc install schemepack, replace
	
	
	* Name of website to import data from:
	local website "https://api.worldbank.org/v2/en/indicator/NY.GDP.PCAP.CD?downloadformat=excel"
	
	* Importing the data by directly loading into Stata
	import excel "`website'", sheet("Data") cellrange(A4:BN270) firstrow clear
	
	* Renaming to add years in variables 
	rename(E-BN) (y#), addnumber(1960)
	rename *, lower

	* Keeping the needed countries in this case Asian.
	keep if inlist(countryname, "China", "Bangladesh", "Pakistan", "India")

	* Reshaping data to long format (personal preference and possibly ease of use)
	reshape long y, i(countryname) j(year) string
	rename y gdp_per_cap
	
	* Dropping the year values where gdp per capita is missing (Year 2021 in this case)
	* then separating the variable by country.
	* The year variable is then also converted to numeric
	drop if missing(gdp_per_cap)
	separate gdp_per_cap, by(countryname)
	destring year, replace
	
	* Generating the plot labels to be used
	* These labels are added to the end point (Year 2020)
	* Includes name of the country and its gdp per capita
	* The label is also split as we split gdp above
	quietly summarize year
	generate label = countryname + ";" + " $" + string(round(gdp_per_cap, .01)) if year == `r(max)'
	separate label, by(countryname)

	* This is a new set of variables which are magnifying the years 1975 to 1985
	* It is simply multiplying the original values by 10 to increase its impact
	* and then adding in 1200 to raise the intercept point thereby raising the
	* overall lines higher up while maintaining trend
	foreach v of varlist gdp_per_cap1 gdp_per_cap2 gdp_per_cap3 gdp_per_cap4 {
		quietly summarize `v'
		generate `v'2 = (`v' * 10) + 1200 if year >= 1975 & year <= 1985
	}
	
	* The following sets of code are storing year 2020 values in locals by the
	* name of cmax, bmax, imax, pmax.
	quietly summarize year
	local yr = `r(max)'

	quietly summarize gdp_per_cap if countryname == "China"  & year == `yr'
	local cmax : display round(`r(max)', .01)
	quietly summarize gdp_per_cap if countryname == "Bangladesh"  & year == `yr'
	local bmax : display round(`r(max)', .01)
	quietly summarize gdp_per_cap if countryname == "India"  & year == `yr'
	local imax : display round(`r(max)', .01)
	quietly summarize gdp_per_cap if countryname == "Pakistan"  & year == `yr'
	local pmax : display round(`r(max)', .01)

	* These locals are for the position of labels that we defined above:
	* China label position is to be between max values of bangladesh and china
	* Bangladesh position is to be $500 above the center of pakistan and bangladesh max
	* India is to be slightly below Bangladesh max value (hence subtraction)
	* Pakistan is simply between 0 and max of Pakistan
	local china : display ((`cmax' + `bmax') / 2)
	local bangladesh : display (((`bmax' + `pmax') / 2) + 500)
	local india : display ((`imax' - 200))
	local pakistan : display ((0 + `pmax') / 2)


********************************************************************************

	* Now we start plotting here (AREA PLOT VERSION)
	
	* We use the following RGB Color codes for plot colors 
	* 	China 		"214 39 40"
	* 	India 		"255 127 14"
	* 	Bangladesh 	"31 119 180"
	* 	Pakistan 	"44 160 44"
	
	* We can also automate this use colorpalette:
	colorpalette tableau, n(4) nograph 

	#delimit ;
	twoway 	
			(area gdp_per_cap2 year if year >= 1975, lwidth(0) fcolor("`r(p4)'")) 
			(area gdp_per_cap3 year if year >= 1975, lwidth(0) fcolor("`r(p2)'")) 
			(area gdp_per_cap1 year if year >= 1975, lwidth(0) fcolor("`r(p1)'")) 
			(area gdp_per_cap4 year if year >= 1975, lwidth(0) fcolor("`r(p3)'")) 
			
			(line gdp_per_cap1 year if year >= 1975 & year <= 2016, lpattern(dash) lcolor("`r(p1)'")) 
			(line gdp_per_cap3 year if year >= 1975 & year <=2006, lpattern(dash) lcolor("`r(p2)'"))
			
			(scatteri `china' 2024.5 "{bf}China; $`cmax'", ms(i) mlabpos(0) mlabcolor("`r(p4)'"))
			(scatteri `india' 2024 "{bf}India; $`imax'", ms(i) mlabpos(0) mlabcolor("`r(p2)'"))
			(scatteri `bangladesh' 2025.3 "{bf}Bangladesh; $`bmax'", ms(i) mlabpos(0) mlabcolor("`r(p1)'"))
			(scatteri `pakistan' 2024.8 "{bf}Pakistan; $`pmax'", ms(i) mlabpos(0) mlabcolor("`r(p3)'"))
			(scatteri 10000 1980.8 "{bf}GDP Per Capita", ms(i) mlabpos(0) mlabcolor(gs3) mlabsize(4))
			(scatteri 9500 1983.6 "Current regional standing | 2020", ms(i) mlabpos(0) mlabcolor(gs3) mlabsize(3))
			
			(scatteri 2000 1974.5 2000 1985.5 5500 1985.5 5500 1974.5, recast(area) lwidth(0.1) lcolor(black) fcolor(white)) //magnifying box
			(scatteri 1850 1975 "1975" 1850 1977 "1977" 1850 1979 "1979" 1850 1981 "1981" 1850 1983 "1983" 1850 1985 "1985", ms(i) mlabpos(0) mlabsize(1.75)) //labels on box
			
			(line gdp_per_cap12 year if year >= 1975, lpattern(dash) lcolor("`r(p1)'")) 
			(line gdp_per_cap22 year if year >= 1975, lpattern(dash) lcolor("`r(p4)'")) 
			(line gdp_per_cap32 year if year >= 1975, lpattern(dash) lcolor("`r(p2)'")) 
			(line gdp_per_cap42 year if year >= 1975, lpattern(dash) lcolor("`r(p3)'")) 
			
			,
			
			xlabel(1975(5)`yr', nogrid labsize(2.1)) 
			xscale(lstyle(none) range(1975 `yr'))
			xtitle("")
			
			ylabel(none, nogrid)
			yscale(range(0 10500))
			
			note("Source: World Bank", size(2) margin(t=3))
			legend(off) 
			graphregion(margin(r=15))
			plotregion(margin(b=0))
			scheme(white_tableau) 
			;
	#delimit cr 
	
	
	* To export this graph you can use the following code:
	*graph export "./animation_gdp_cap/gdp_per_capita_asia.png", as(png) width(3840) replace
	
	
	
	
