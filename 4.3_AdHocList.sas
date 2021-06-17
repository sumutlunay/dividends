libname z "/scratch/kennesaw/";

/*Generate the list of Employee Owned Firms with Repurchases*/

data data1;
	set z.fullcomp;
	array vars(4) salgrowth logat da opprofit;
	misval = cmiss(of vars[*]);
	if misval=0;
	if private=1;
	if gov=1 then delete;
	if coop=1 then delete;
	if sub_coop=1 then delete;
	if missing(financier) then financier=0;
run;

	/*Winsorization*/
%winsorize(inset=data1, outset=data2, sortvar=fyear, 
vars= 	salgrowth lev da opprofit profit div1 div2 payout1 payout2
		repurch1 repurch2,
perc1=1, trim=0);

data data2; set data2;
if employ=1;
if repurch>0;
run;

/* proc sort data=data2 nodupkey; */
/* by gvkey; */
/* run; */

	/*Export to Excel*/
proc export 
  data=data2 
  dbms=xlsx 
  outfile="/home/kennesaw/Sunay/Dividends/repurch_employ.xlsx" 
  replace;
run;

	/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
