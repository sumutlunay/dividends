libname z "/scratch/kennesaw/";

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
vars= 	dvc lagdv chgdv
		repurch lagrepurch chgrepurch
		dps lagdps chgdps
		chgpayoutps payoutps lagpayoutps
		eps epsalt fcf cfo profit opprofit,
perc1=1, trim=0);

	/*Save a SAS version for visuals*/
data z.visuals1;
	set data2;
	keep gvkey fyear manag employ pe1 pe2 
		dvc lagdv chgdv
		repurch lagrepurch chgrepurch
		dps lagdps chgdps
		chgpayoutps payoutps lagpayoutps
		eps epsalt fcf cfo profit opprofit;
run;

	/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
