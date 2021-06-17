proc sql;
	create table base0
	as select DATAFMT, FYEARQ, DATACQTR, GDWLIPQ, GVKEY, INDFMT, POPSRC, RCPQ, SETPQ, 
			SPIOPQ, WDPQ, ATQ,	CEQQ, CIK, CONM, CSHOQ, CUSIP, EXCHG,	FIC, FYR, IBQ, LTQ, OANCFY, 
			SALEQ, SPIQ, TIC, OIBDPQ, DVY, OIADPQ, DLTTQ, ADRRQ, ACTQ,  LCTQ, CHQ, CAPXY, PPENTQ,
			PRSTKCY, SSTKY, TSTKQ, PRCRAQ, PRSTKCY, PSTKQ, CSHIQ, PRCCQ, XINTQ, INTANQ, ppegtq, dpactq,
			DVPSPQ, EPSPXQ
		from compd.fundq;
quit;

	/*Clean Data!!*/
data base1;
	set base0;
	if datafmt = "STD";/*Non restated data*/
	if indfmt = "INDL"; /*Industrial format*/
	if fyearq ne .;
	if atq ne .;
	if missing(DVY) then DVY=0;
	logat = log(atq);
	lev = (DLTTQ/ATQ);
	da = LTQ/ATQ;
	profit = IBQ/ATQ;
	opprofit = OIBDPQ/ATQ;
	invest = capxy/atq;
	dps = dvy/cshoq;
	eps = IBQ/cshoq;
	div1=DVY/OIBDPQ;
	div2=DVY/atq;
	invat=1/atq;
	tang = PPENTQ/ATQ;
	if missing(ibq) then loss=.;
	else if ibq<0 then loss=1;
	else loss=0;
	if dvy>0 then payer=1; else payer=0;
	if missing(TSTKQ) then TSTKQ=0;
		if missing(DVY) then DVY=0;
		if missing(CAPXY) then CAPXY=0;
	fcf = (OANCFY-DVY-CAPXY)/ATQ;
	cfo= oancfy/atq;
run;

/*Create Lag Variables*/
proc sort data=base1; 
	by gvkey DATACQTR;
run;

data base1;
	set base1;
	by gvkey DATACQTR;
	lagquarter=lag(DATACQTR);
	lagat = lag(atq);
	lagdv = lag(DVY);
	lagtreas = lag(TSTKQ);
	lagPRSTKCY = lag(PRSTKCY);
	lagPSTKQ = lag(PSTKQ);
	lagsale=lag(saleq);
	lagdps=lag(dps);
	lageps=lag(eps);
	lagaltdps=lag(DVPSPQ);
	lagalteps=lag(EPSPXQ);
	if first.gvkey then do
		lagat=.;
		lagdv=.;
		lagtreas=.;
		lagPRSTKCY=.;
		lagPSTKQ = .;
		lagsale = .;
		lagdps=.;
		lageps=.;
		lagaltdps=.;
		lagalteps=.;
	end;
run;

/*Create Lead Variables*/
proc sort data=base1; 
	by gvkey descending DATACQTR;
run;

data base1;
	set base1;
	by gvkey descending DATACQTR;
	leadsale=lag(saleq);
	if first.gvkey then do
		leadsale=.;
	end;
run;

data base1;
	set base1;
	salgrowth = (leadsale-saleq)/saleq;
	deldiv=(dvy-lagdv)/lagdv;
/*Grennan-JFE 2018 Calculation*/
	if missing(PRCRAQ) then 
		grossrep = 	(PRSTKCY - lagPRSTKCY) - (PSTKQ - lagPSTKQ);
	else grossrep = CSHOPQ*PRCRAQ;

	if (TSTKQ=0 and lagtreas=0) then /*Modified this part to make consistent with Fama&French-2001*/
		netrep = grossrep-(CSHIQ*PRCCQ);
		else netrep=TSTKQ-lagtreas;

	if netrep<0 then netrep=0;
	if grossrep<0 then grossrep=0;
	grossrepa = grossrep/lagat;
	netrepa = netrep/lagat;

	payouta = (grossrep+dvy)/lagat;
	payoutps = (grossrep+dvy)/cshoq;
run;

/*Alternative Denominator by Operating Profit*/
data base1;
	set base1;
	grossrepi = grossrep/OIBDPQ;
	netrepi = netrep/OIBDPQ;
	payouti = (netrep+dvy)/OIBDPQ;
run;

/*Create More Lag Variables*/
proc sort data=base1; 
	by gvkey DATACQTR;
run;

data base1;
	set base1;
	by gvkey DATACQTR;
	laggrossrep=lag(grossrep);
	lagnetrep = lag(netrep);
	lagpayoutps = lag(payoutps);
	if first.gvkey then do
		laggrossrep=.;
		lagnetrep=.;
	end;
	lagpayout = lagdv + lagnetrep;
	chggrossrep = grossrep - laggrossrep;
	chgnetrep = netrep - lagnetrep;
	chgdv = dvy - lagdv;
	chgpayout = netrep+dvy-lagpayout;

	chgdps = dps - lagdps;
	chgeps = eps - lageps;

	chgaltdps = DVPSPQ - lagaltdps;
	chgalteps = EPSPXQ - lagalteps;
	
	chgpayoutps = payoutps-lagpayoutps;
run;

/****/
	/*Volatility Measures*/
	/*Income volatility up to 4 years back*/
data window1;
	set base1;
	begy=fyearq-3;
	endy=fyearq;
	indy=fyearq;
	keep gvkey begy endy indy;
run;

proc sort data=window1 nodupkey;
	by gvkey indy;
run;

data base2;
	set base1;
	keep gvkey fyearq ibq;
run;

proc sql;
	create table window2
	as select * from base2 as a,
	window1 as b
	where a.gvkey=b.gvkey
	and 	b.begy <= a.fyearq <= b.endy;
quit;

proc sort data=window2;
	by gvkey indy;
run;

proc means data=window2 noprint;
	by gvkey indy;
	output out=window3 std(ibq)=involat
		n(ibq)=nib;
run;

data window3;
	set window3;
	if nib<5 then involat=.;
	drop _TYPE_ _FREQ_;
run;

proc sql;
	create table base3
	as select * from base1 as a,
	window3 as b
	where a.gvkey=b.gvkey
	and a.fyearq=b.indy;
quit;

	/*Get Header SIC Codes from Company file*/
data company;
	set comp.names;
	keep gvkey sic;
run;

proc sql;
	create table base4
	as select * from base3 as a
	left join company as b
	on a.gvkey=b.gvkey;
quit;

data base4;
	set base4;
	%FFI48(SIC);
run;

/*PSM Variables*/
data base4;
	set base4;
	int_cov = OIBDPQ/XINTQ;
	if OIBDPQ<0 then int_cov=0;
	intang = intanq/atq;
	if missing(intanq) then intang=0;
	if missing(ppegtq) then ppegtq=0;
	if missing(dpactq) then dpactq=0;
	ppe = (ppegtq-dpactq)/lagat;
	growth = (saleq-lagsale)/lagsale;
run;

proc rank data=base4 out=base5 ties=low groups=5;
   var atq da;
   ranks atqRank daRank;
run;

data base5;
	set base5;	
	numsic=input(sic,4.);
	if 6000<=numsic<=6999 then delete;
	if 4900<=numsic<=4939 then delete;
	if numsic<=1000 then delete;
	if numsic>=8999 then delete;
	sic3=substr(sic,1,3);
	ind3=input(sic3,3.);
	numgvkey=input(gvkey,6.);
run;

/*Calculate number of dividends per each fiscal year*/
proc sql;
create table base6
as select a.*, b.numdivs
from base5 as a
left join (select gvkey, fyearq, sum(payer) as numdivs 
			from base3
			group by gvkey, fyearq) as b
	on a.gvkey=b.gvkey
	and a.fyearq=b.fyearq;
quit;

data base6; set base6;
if numdivs>4 then numdivs=4;
if numdivs = 4 then divs4=1; else divs4=0;
if numdivs = 3 then divs3=1; else divs3=0;
if numdivs = 2 then divs2=1; else divs2=0;
if numdivs = 1 then divs1=1; else divs1=0;
run;

/*Define local folders on home directory*/
libname q "/home/kennesaw/Sunay/Dividends";
libname z "/scratch/kennesaw/";

/*Create separate dataset with numdivs to merge with annual data*/
data numdivs;
set base6;
keep gvkey fyearq numdivs divs4 divs3 divs2 divs1;
run;

proc sort data=numdivs out=z.numdivs nodupkey;
by gvkey fyearq;
run;

/*Sharon's initial data*/
/*Original data encoded in wlatin1, SAS environment is UTF-8, this leads to character truncation*/
/*Use CVP option in libname statement to expand character variable padding engine*/
libname p cvp "/home/kennesaw/Sunay/Dividends/From Sharon";

data privates1;
	set p.privatefirms_ownership;
	private=1;
	keep gvkey1 /*cusip*/ fyear /*yearIPO pe1 pe2 Manag Employ*/ ownership PERank private financier gov sub_coop coop
		PE_own CEO_own Mgmt_own Group_own Employ_Own Tribe_own Family_Own Chairman
		No_Deals No_Firms Equity_Invested;
run;

/*Sharon's update April-2020*/
data privates2;
	set p.privatesupdate_ready;
run;

/*Merge old data with update*/
data privatesfull;
	set privates1 privates2;
run;

proc sort data=privatesfull nodupkey;
	by gvkey1 fyear;
run;

/*Create Ownership Categories*/
data privatesfull;
	set privatesfull;
	if ownership = 1 then pe1=1; else pe1=0;
	if ownership = 2 then pe2=1; else pe2=0;
	if ownership = 3 then manag=1; else manag=0;
	if ownership = 4 then employ=1; else employ=0;
	if 1<=PERank<= 3 then largepe=1; else largepe=0;
run;

/*Additional Variables*/
/* data privatesfull; */
/* 	set privatesfull; */
/* 	array vars(8) PE_own CEO_own Mgmt_own Group_own Employ_Own Tribe_own Family_Own Chairman; */
/* 		do i=1 to 8; */
/* 		if missing(vars(i)) then vars(i)=0; */
/* 		end; */
/* run; */

data privatesfull;
	set privatesfull;
/* 	mgmt_ownership = Mgmt_own + Family_Own + Chairman + CEO_own; */
	if (no_firms>200 and (equity_invested/no_firms)>30) then Many_PE=1; else Many_PE=0;
run;

/*Merge with compustat*/
proc sql;
	create table base7
	as select * from base6 as a
	left join privatesfull as b
	on a.numgvkey=b.gvkey1
	and a.fyearq = b.fyear;
quit;

data z.fullcomp_q;
	set base7;
	if 1978<=fyearq<=2019;
	if missing(private) then private=0;
run;

	/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
