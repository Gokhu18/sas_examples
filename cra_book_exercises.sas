/* ###########################################################################################################################
#	Program:	migration_model.sas
#	Purpose: 	This script implements examples from the CRA book by Baesens et al.
#				Examples include: PIT/TTC PD model, cumulative (ordered) probit rating model
#
#	Inputs: 	mortgage.csv	
#	Outputs: 	
#
#
#
#
#
#
#
#	Comments
#	 11APR2019 - EJ - Created
#	 19JUN2019 - EJ - Modified to include additional examples from CRA book
#
#
############################################################################################################################# */

/*Importing Sample dataset*/
proc import 
 datafile="<output_directory>/mortgage.csv"
 out=work.mortgage
 dbms=csv
 replace
;
run;

/*Sorting dataset by time and loan id*/
proc sort data=work.mortgage out=mort_sort;
 by id time;
run;

/***PD example 1 ***/
/*My own coding -- not in the book */
data pd_example_1;
	set work.mort_sort;
	gdp_grwth_lag3=lag3(gdp_time);
	hpi_grwth_lag3=lag3(hpi_time/lag(hpi_time)-1);
	uer_lag1=lag(uer_time);
run;

/*Logistic PD Ex. 1 Regression with Probit Link*/
proc logistic data=pd_example_1 descending;
	model default_time = gdp_grwth_lag3 hpi_grwth_lag3 uer_lag1 / link=probit;
run;
/***PD example 2 ***/
/*Logistic PD Ex. 2 Regression with Probit Link*/
data pd_example_2;
	set work.mortgage;
	orig_time2=orig_time;
	if orig_time not in (20, 21, 22, 23, 24, 25)
	then orig_time2=0;
run;

proc logistic data=pd_example_2 descending;
	class orig_time2 / param=reference;
	model 	default_time = fico_orig_time 
			ltv_time gdp_time orig_time2 / link=probit;
run;

/***PD TTC v PIT Example***/
/*Logistic PD TTC Regression with Probit Link*/
proc logistic data=work.mortgage descending;
	model default_time = fico_orig_time ltv_orig_time / link=probit;
	output out=probabilities predicted=pd_ttc_time;
run;

/*Logistic PD PIT Regression with Probit Link*/
proc logistic data=probabilities descending;
	model 	default_time = fico_orig_time 
			ltv_time gdp_time uer_time hpi_time / link=probit;
	output out=probabilities2 predicted=pd_pit_time;
run;

/*Aggregating Predicted PDs for graphs	*/
proc sort data=probabilities2;
 by time;
run; 

proc means data=probabilities2;
	by time;
	output out=means 
	mean(default_time pd_ttc_time pd_pit_time)=default_time pd_ttc_time pd_pit_time;
run;

data means;
	set means;
	label pd_ttc_time="PD_TTC_time";
	label pd_pit_time="PD_PIT_time";
run;

ods graphics on;
	axis1 order=(0 to 60 by 5) label=('Time');
	axis2 order=(0 to 0.06 by 0.01) label=('DR and PD');
	symbol1 interpol=spline width=2 value=triangle c=blue;
	symbol2 interpol=spline width=2 value=circle c=red;
	symbol3 interpol=spline width=2 value=square c=black;
	legend1 label=none shape=symbol(4,2) position=(bottom outside);

	proc gplot data=means;
		plot (default_time pd_ttc_time pd_pit_time)*time
		/ overlay haxis=axis1 vaxis=axis2 legend=legend1;
	run;
ods graphics off;

/*Creating a rating scale using FICO scores*/
data work.mortgage;
 set work.mort_sort;
 if fico_orig_time>350 and fico_orig_time<=500 then rating=1;
 if fico_orig_time>500 and fico_orig_time<=650 then rating=2;
 if fico_orig_time>650 and fico_orig_time<=850 then rating=3;
 lagid=lag(id);
 lagrating=lag(rating);
run;

/*Cleaning loan observations that are not observable in the previous time period (balanced panel)*/
data work.mortgage;
 set work.mortgage;
 if id ne lagid then lagrating=.;
 if default_time=1 then rating=4;
run;

/*Outputing the empirical ratings cross-tabulation (migration matrix)*/
proc freq data=work.mortgage(where=(rating ne . and lagrating ne .));
 tables lagrating*rating / NOCOL NOPERCENT NOCUM;
run;

/*Estimating a discrete-time cumulative probit model conditioning on lagrating*/
proc logistic data=mortgage;
 class lagrating(ref='3');
 model rating = lagrating / link=probit;
/* model rating = lagrating gdp_time / link=probit;*/
 output out=probabilities predicted=prob_cum;
run;

/*Preparing data for migration matrix creation*/
data rating4;
 input lagrating _LEVEL_;
 datalines;
 1 4
 2 4
 3 4
 ;
run;

data probabilities2;
 set probabilities rating4;
run;

proc sort data=probabilities2 out=probabilities3(where=(lagrating ne .))
 NODUPKEY;
 by lagrating _Level_;
run;

/*Calculating the cumulative PDs for the migration matrix*/
data probabilities3(keep= lagrating rating probability);
 set probabilities3;
 lagprob_cum=lag(prob_cum);
 if _level_=1 then probability=prob_cum;
 if _level_=2 then probability=prob_cum-lagprob_cum;
 if _level_=3 then probability=prob_cum-lagprob_cum;
 if _level_=4 then probability=1-lagprob_cum;
 rating=_level_;
run;

proc transpose data=probabilities3 out=probabilities4(drop=_name_)
 prefix=rating;
 by lagrating;
 ID rating;
run;

title "Estimated Rating Migration Matrix";
proc print data=probabilities4;
run; title;

/*Calculating marginal PDs from the cumulative PD matrix*/
data marginal_pd(keep= lagrating rating4);
 set probabilities4;
 rating4=rating4*1/3;
run;

proc print data=marginal_pd;
run;

/*Importing Sample HMEQ dataset*/
libname data "/opt/sas/sasdata/sasuser/ejohn07/cecl";

/*Replacing missing values with sample means*/
proc standard 
	data=data.hmeq 
	replace out=mysamplenomissing;
run;

title "HMEQ Data with Missing Replaced by Means";
proc means data=mysamplenomissing
	NMISS N;
run; title;

title "Original HMEQ Data";
proc means data=data.hmeq
	NMISS N;
run; title;

/*Standardizing HMEQ data to z-scores*/
proc standard 
	data=data.hmeq 
	mean=0 std=1 
	out=zscores;
	var clage clno debtinc delinq derog 
		loan mortdue ninq value yoj;	
run;

/*Filtering outliers using z-scores */
data filteredsample;
	set zscores;
	where 	abs(clage) < 3 and abs(clno) < 3 and abs(debtinc) <3
			and abs(delinq) < 3 and abs(derog) < 3 and abs(loan) < 3
			and abs(mortdue) < 3 and abs(ninq) < 3 and abs(value) < 3
			and abs(yoj) < 3;
/*	Added code for output*/
	filter=1;
run;

/***Histograms of pre- and post-filter	***/
/*Merging filtered and non-filtered hmeq data */
data hmeq_merge;
	set zscores filteredsample;
	if filter ne 1 
	then filter=0;
run;

/*Exporting histograms using sgplot*/
ods listing gpath="<output_directory>";
proc sgplot data=hmeq_merge;
	histogram mortdue / group=filter transparency=0.5;
	density mortdue / type=kernel group=filter;
	xaxis label="Normalized Outstanding Mortgage Balance";
run;
ods listing close;

ods graphics on;
ods listing gpath="<output_directory>";
proc univariate data=work.mortgage noprint;
	qqplot FICO_orig_time LTV_orig_time
	/ normal(mu=est sigma=est color=ltgrey);
run;
ods listing close;
ods graphics off; 
