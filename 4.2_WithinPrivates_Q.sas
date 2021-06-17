libname z "/scratch/kennesaw/";

data data1;
	set z.fullcomp_q;
	array vars(4) salgrowth logat da opprofit;
	misval = cmiss(of vars[*]);
	if misval=0;
	if private=1;
	if gov=1 then delete;
	if coop=1 then delete;
	if sub_coop=1 then delete;
	if missing(financier) then financier=0;
	if 4900<=numsic<=4949 then delete;/*Delete financials*/
	if 6000<=numsic<=6999 then delete;/*Delete utilities*/ 
	if 1984<=fyearq<=2018;
run;
run;

	/*Winsorization*/
%winsorize(inset=data1, outset=data2, sortvar=datacqtr, 
vars= 	salgrowth lev da opprofit profit div1 div2 netrepa netrepi 
		grossrepa grossrepi
		payouta payouti
		dps lagdps chgdps
		chgpayoutps payoutps lagpayoutps
		fcf cfo
		dps lagdps chgdps DVPSPQ lagaltdps chgaltdps
		eps lageps chgeps epspxq lagalteps chgalteps,
perc1=1, trim=0);

	/*Export to Stata*/
proc export data=data2
	outfile= "/home/kennesaw/Sunay/Dividends/withinprivates_q.dta" replace;
run;

	/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
