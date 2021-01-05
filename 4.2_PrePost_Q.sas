libname q "/home/kennesaw/Sunay/Dividends";
proc sort data=q.fullcomp_q out=data1;
	by gvkey fyearq datacqtr;
run;

data data1;
	set data1;
	by gvkey fyearq datacqtr;
	if dvy>0 then divind = 1; else divind=0;
	lagdivind = lag(divind);
	lagpriv = lag(private);
	lagmanag = lag(manag);
	lagemploy = lag(employ);
	lagpe1 = lag(pe1);
	lagpe2 = lag(pe2);
	if first.gvkey then	lagdivind=.;
	if first.gvkey then	lagpriv=.;
	if first.gvkey then	lagmanag=.;
	if first.gvkey then	lagemploy=.;
	if first.gvkey then	lagpe1=.;
	if first.gvkey then	lagpe2=.;
	indicator = private - lagpriv;
	divchg = divind - lagdivind;
run;	

data indicators;
	set data1;
	if (indicator=1 or indicator=-1); /*-1 for IPO, +1 for going private*/
	indyear=fyearq;
	indqtr=datacqtr;
	group1 = manag+employ;
 	group2 = pe1+pe2;
	group3 = lagmanag+lagemploy;
 	group4 = lagpe1+lagpe2;
run;



proc sql;
	create table gopublic
	as select a.*, b.group1, b.group2, b.group3, b.group4, b.indyear, b.indqtr
	from data1 as a
	inner join indicators as b
	on a.gvkey=b.gvkey
	and b.indicator=-1
	and a.indicator<>1	
/*	and (b.fyearq-5) <= a.fyearq <= (b.fyearq+5)*/
	and a.datacqtr <> b.indqtr;
quit;

proc sql;
	create table goprivate
	as select a.*,b.group1, b.group2, b.group3, b.group4, b.indyear, b.indqtr
	from data1 as a
	inner join indicators as b
	on a.gvkey=b.gvkey
	and b.indicator=1
	and a.indicator<>-1
/*	and (b.fyearq-5) <= a.fyearq <= (b.fyearq+5)*/
	and a.datacqtr <> b.indqtr;
quit;

/*Pre-Post balance*/
	/*Publics*/

data gopublic1;
	set gopublic;
	array vars(4) salgrowth logat da opprofit;
	misval = cmiss(of vars[*]);
	if misval=0;
	if gov=1 then delete;
	if coop=1 then delete;
	if sub_coop=1 then delete;
	if missing(financier) then financier=0;
	yearspass = fyearq - indyear;
	qpass = 4*((input(substr(datacqtr,1,4),4.))-(input(substr(indqtr,1,4),4.))) - 
						((input(substr(indqtr,6,1),1.))-(input(substr(datacqtr,6,1),1.))) ;
	if (qpass<0 and private=0) then delete;
run;

proc sort data=gopublic1;
	by gvkey;
run;

proc means data=gopublic1 noprint;
	by gvkey;
	var private;
	output out=publics mean=mean;
run;

proc sql;
	create table gopublic2
	as select a.* from gopublic1 as a
	inner join publics as b
	on a.gvkey=b.gvkey
	and 0<b.mean<1;
quit;

	/*Privates*/
data goprivate1;
	set goprivate;
	array vars(4) salgrowth logat da opprofit;
	misval = cmiss(of vars[*]);
	if misval=0;
	if gov=1 then delete;
	if coop=1 then delete;
	if sub_coop=1 then delete;
	if missing(financier) then financier=0;
	yearspass = fyearq - indyear;
	qpass = 4*((input(substr(datacqtr,1,4),4.))-(input(substr(indqtr,1,4),4.))) - 
						((input(substr(indqtr,6,1),1.))-(input(substr(datacqtr,6,1),1.))) ;
	if (qpass<0 and private=1) then delete;
run;

proc sort data=goprivate1;
	by gvkey;
run;

proc means data=goprivate1 noprint;
	by gvkey;
	var private;
	output out=privates mean=mean;
run;

proc sql;
	create table goprivate2
	as select a.* from goprivate1 as a
	inner join privates as b
	on a.gvkey=b.gvkey
	and 0<b.mean<1;
quit;

/**Prepare for Analysis**/
	/*Winsorization*/
%winsorize(inset=gopublic2, outset=gopublic3, sortvar=datacqtr, 
vars= 	salgrowth lev da opprofit profit div1 div2 netrepa grossrepa payouta
dvy netrepi payouti,
perc1=1, trim=0);

	/*Export to Stata*/
proc export data=gopublic3
	outfile= "/home/kennesaw/Sunay/Dividends/gopublic_q.dta" replace;
run;

	/*Save a SAS version for visuals*/
data q.gopublic_q;
set gopublic3;
run;

	/*Winsorization*/
%winsorize(inset=goprivate2, outset=goprivate3, sortvar=datacqtr, 
vars= 	salgrowth lev da opprofit profit div1 div2 netrepa grossrepa payouta
dvy netrepi payouti,
perc1=1, trim=0);

	/*Export to Stata*/
proc export data=goprivate3
	outfile= "/home/kennesaw/Sunay/Dividends/goprivate_q.dta" replace;
run;

	/*Save a SAS version for visuals*/
data q.goprivate_q;
set goprivate3;
run;

	/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
