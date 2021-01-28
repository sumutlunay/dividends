libname z "/scratch/kennesaw/";

data data1;
	set z.fullcomp_q;
	array vars(4) salgrowth logat da opprofit;
	misval = cmiss(of vars[*]);
	if misval=0;
	if gov=1 then delete;
	if coop=1 then delete;
	if sub_coop=1 then delete;
	if missing(financier) then financier=0;
run;

	/*Winsorization*/
%winsorize(inset=data1, outset=data2, sortvar=fyearq, 
vars= 	salgrowth lev da opprofit profit div1 div2 netrepa grossrepa payouta
dvy netrepi payouti cfo fcf involat,
perc1=1, trim=0);

	/*Export to Stata*/
proc export data=data2
	outfile= "/home/kennesaw/Sunay/Dividends/levelfull_q.dta" replace;
run;

	/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
