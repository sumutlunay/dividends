proc sql;
	create table base0
	as select CONSOL, COSTAT, CURCD,DATADATE, DATAFMT, FYEAR, GDWLIP, GVKEY, INDFMT, POPSRC, RCP, SETP, 
			SPIOP, WDP,	AT,	CEQ, CIK, CONM, CSHO, CUSIP, EXCHG,	FIC, FYR, IB, LT, OANCF, PRCC_F, PRCC_C, 
			SALE, SPI, TIC, SICH, OIBDP, DVC, OIADP, XRD, DLTT, ADRR, ACT,  LCT, CH, DD1, TXP, CAPX, DP, DV,
			WCAP, RE, PPENT, PPEGT, COGS, XIDOC, RECCH, XINT, IBC, RECT, INVT, DLC, XAD, AP, INTAN, RECD, AU, PI,
			TSTKC, PRSTKC, SSTK, DVPSX_F, AJEX, EPSPX, dpact, ebit, DVPSP_C, DVPSP_F, INTPN, NI, PSTKRV
		from compd.funda;
quit;

	/*Clean Data!!*/
data base1;
	set base0;
	if datafmt = "STD";/*Non restated data*/
	if indfmt = "INDL"; /*Industrial format*/
/* 	if fyear ne .; */
/* 	if at ne .; */
	logat = log(at);
	lev = (DLTT/AT);
	da = LT/AT;
	profit = IB/AT;
	opprofit = OIBDP/AT;
	invest = capx/at;
	if missing(dvc) then div1=0;
	div1=dvc/OIBDP;
	invat=1/at;
	tang = PPENT/AT;
	earnings = ib -(0.6*SPI);
	purch1 = PRSTKC - PSTKRV;
	purch2 = PRSTKC - SSTK;
	if missing(ib) then loss=.;
	else if ib<0 then loss=1;
	else loss=0;
	if dvc>0 then payer=1; else payer=0;
	dps=dvc/csho;
/* 	epsalt=epspx; */
	eps=ib/csho;
*	fcf = (OANCF-XIDOC+INTPN-((PI-NI)/PI)*XINT-CAPX)/AT;
		if missing(DV) then DV=0;
		if missing(CAPX) then CAPX=0;
	fcf = (OANCF-DV-CAPX)/AT;
	cfo = (OANCF-XIDOC)/AT;
run;

/*Create Lag Variables*/
data lags;
	set base1 (rename=(at = lagat
				dvc = lagdv
				TSTKC = lagtreas
				dps = lagdps
				sale = lagsale
				eps = lageps
				EPSPX = lagalteps
				DVPSP_F = lagaltdps));
	lagyear=fyear+1;
	keep gvkey lagyear lagat lagdv lagtreas lagdps lagsale lageps lagalteps lagaltdps;
run;

/*Create Lead Variables*/
data leads;
	set base1 (rename=(sale = leadsale));
	leadyear=fyear-1;
	keep gvkey leadyear leadsale;
run;

proc sql;
	create table base2
	as select * 
	from base1 as a, lags as b
	where a.gvkey=b.gvkey
	and a.fyear = b.lagyear;
quit;

proc sql;
	create table base3
	as select * 
	from base2 as a, leads as b
	where a.gvkey=b.gvkey
	and a.fyear = b.leadyear;
quit;

data base3;
	set base3;
	salgrowth = (leadsale-sale)/sale;
	deldiv=(dvc-lagdv);
	if TSTKC=0 and lagtreas=0
		then repurch=purch1;
		else repurch=TSTKC-lagtreas;
	if repurch<0 then repurch=0;
/* 	repurch=purch1; */
	payout1=(dvc+repurch)/OIBDP;
	payout2=(dvc+repurch)/lagat;
	stockiss=-1*(purch1);
	payoutps=(dvc+repurch)/csho;
	
	repurch1=repurch/OIBDP;
	repurch2=repurch/lagat;
	div2=dvc/lagat;

run;

/*Create Lag Payout*/
data lag2;
	set base3 (rename=(payout1 = lagpayout1 payout2 = lagpayout2
						repurch = lagrepurch payoutps = lagpayoutps));
	lagyear=fyear+1;
	keep gvkey lagyear lagrepurch lagpayout1 lagpayout2 lagpayoutps; 
run;

proc sql;
	create table base3
	as select * 
	from base3 as a, lag2 as b
	where a.gvkey=b.gvkey
	and a.fyear = b.lagyear;
quit;

data base3;
	set base3;
	chgdv = dvc - lagdv;
	chgrepurch = repurch - lagrepurch;
	
	lagpayout = (lagdv + lagrepurch);
	chgpayout = dvc+repurch - lagpayout;
	chgpayoutps = payoutps - lagpayoutps; 
	
	chgdps = dps - lagdps;
	chgeps = eps - lageps;
	chgaltdps = DVPSP_F - lagaltdps;
	chgalteps = EPSPX - lagalteps;
	
run;
	
	/*Volatility Measures*/
	/*Income volatility up to 10 years back*/
data window1;
	set base3;
	begy=fyear-9;
	endy=fyear;
	indy=fyear;
	keep gvkey begy endy indy;
run;

proc sort data=window1 nodupkey;
	by gvkey indy;
run;

data base4;
	set base3;
	keep gvkey fyear ib;
run;

proc sql;
	create table window2
	as select * from base4 as a,
	window1 as b
	where a.gvkey=b.gvkey
	and 	b.begy <= a.fyear <= b.endy;
quit;

proc sort data=window2;
	by gvkey indy;
run;

proc means data=window2 noprint;
	by gvkey indy;
	output out=window3 std(ib)=involat
		n(ib)=nib;
run;

data window3;
	set window3;
	if nib<5 then involat=.;
	drop _TYPE_ _FREQ_;
run;

proc sql;
	create table base5
	as select * from base3 as a,
	window3 as b
	where a.gvkey=b.gvkey
	and a.fyear=b.indy;
quit;

	/*Get Header SIC Codes from Company file*/
data company;
	set comp.names;
	keep gvkey sic;
run;

proc sql;
	create table base6
	as select * from base5 as a
	left join company as b
	on a.gvkey=b.gvkey;
quit;

data base6;
	set base6;
	%FFI48(SIC);
run;

/*PSM Variables*/
data base6;
	set base6;
	int_cov = EBIT/XINT;
	if EBIT<0 then int_cov=0;
	intang = intan/at;
	ppe = (ppegt-dpact)/lagat;
	growth = (sale-lagsale)/lagsale;
run;

proc rank data=base6 out=base7 ties=low groups=5;
   var at da;
   ranks atRank daRank;
run;

data base7;
	set base7;
	numsic=input(sic,4.);
/* 	if 6000<=numsic<=6999 then delete; */
/* 	if 4900<=numsic<=4939 then delete; */
/* 	if numsic<=1000 then delete; */
/* 	if numsic>=8999 then delete; */
	sic3=substr(sic,1,3);
	ind3=input(sic3,3.);
run;
	
/*Define local folders on home directory*/
libname q "/home/kennesaw/Sunay/Dividends";
libname z "/scratch/kennesaw/";

/*Add numdivs variable from quarterly data*/
proc sql;
create table base8
as select a.*, b.numdivs, b.divs4, b.divs3, b.divs2, b.divs1
from base7 as a
left join z.numdivs as b
on a.gvkey = b.gvkey
and a.fyear = b.fyearq;
quit;

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
/*
proc import datafile="E:\Dividends\From Sharon\update_2020.xlsx"
			out=privatesupdate dbms=xlsx;
			sheet=Cleanlist;
run;

data p.privatesupdate;
	set privatesupdate;
	if missing(A) then delete;
run;

data p.privatesupdate_ready;
	set p.privatesupdate (rename = (y=fyear gvkey1=gvkey));
	if missing(gvkey) then delete;
	if private=1;
	gvkey1=input(gvkey,6.);
	keep gvkey1  fyear ownership PERank private financier gov sub_coop coop;
run;
*/
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
data base8;
	set base8;
	numgvkey=input(gvkey,6.);
run;

proc sql;
	create table base9
	as select * from base8 as b
	left join privatesfull as a
	on b.numgvkey=a.gvkey1
	and a.fyear=b.fyear;
quit;

data z.fullcomp;
	set base9;
	if 1978<=fyear<=2019;
	if missing(private) then private=0;
run;

	/*House Cleaning*/
proc datasets lib=work kill memtype=data nolist; run;
quit;
