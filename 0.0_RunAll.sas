%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/0.1_Update From Sharon.sas';
%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/1.1_Compustat_Q.sas';
%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/1.2_Compustat.sas';
*%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/1.3_Descriptives.sas';
%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/2.1_SOA.sas';
%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/2.2_SOA_Q.sas';
%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/3.1_FullModel.sas';
%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/3.2_FullModel_Q.sas';
%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/4.1_WithinPrivates.sas';
%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/4.2_WithinPrivates_Q.sas';
%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/5.1_PrePost.sas';
%include'/home/kennesaw/Sunay/Dividends/DividendsRepo/5.2_PrePost_Q.sas';
run;

/*For printing the logs*/
/* %macro run_one (path); */
/*    proc printto log="&path.log"; */
/*    run; */
/*    proc printto print="&path.lst"; */
/*    run; */
/*    %include "&path.sas"; */
/*    run; */
/* %mend run_one; */


