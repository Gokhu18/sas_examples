/* Program to mimic functionality of PROC ARIMA Identify */
%let results_dir=<output_directory>;

/* Importing data into SAS/IML */
proc iml;
use sashelp.gulfoil;
	read all var {'date' 'oil'} where(protractionname=:"Viosca Knoll") into oil;
close sashelp.gulfoil;

/* Autocorrelation Module  */
start acf(A);
	autocorr=A/A[1,];
	return autocorr;
finish acf;

/* Autocovariance Module Matrix Math  */
start acov(y,nlag);
	mu=mean(y);
	n=nrow(y);
	lags=(0:nlag)`;
	lags_y=(lag(y,lags));
	do i = 0 to nrow(lags)-1;
		lags_y_i=(y[1+i:nrow(y)-i,]||lags_y[1+i:nrow(lags_y)-i,i+1]);
		lags_y_i=lags_y_i-mu;
		autocov_i=(lags_y_i`*lags_y_i)/n;
		if i=0 then autocov=autocov_i[1,1];
		else autocov=autocov // autocov_i[2,1];
	end;
	return autocov; /** Divide by 1/N to maintain PSD of COV Matrix**/
finish acov;

/* Autocovariance Module Summation Notation  */
start acov_sum(y,nlag);
	mu=mean(y);
	n=nrow(y);
	autocov=j(nrow(y)-nlag,1);
	do i = 1 to (nrow(y)-nlag);
		autocov[i,]=(y[i+nlag,]-mu)*(y[i,]-mu);
	end;
	return (1/(n))*(sum(autocov));
finish acov_sum;

/* Linear regression Module  */
start regress;
	beta=solve(x`*x,x`*y);
	yhat=x*beta;
	uhat=y-yhat;
	
	sse=ssq(uhat);
	n=nrow(x);
	dfe=nrow(x)-ncol(x);
	mse=sse/dfe;
	cssy=ssq(y-sum(y)/n);
	r2=(cssy-sse)/cssy;
	results = sse || dfe || mse || r2;
	print results[c={"SSE" "DFE" "MSE" "R-Square"} L={"Regression Results"}];
	
	se=sqrt(vecdiag(inv(x`*x)*mse));
	t=beta/se;
	prob=1-probf(t#t,1,dfe);
	paramest=beta || se || t || prob;
	print paramest[c={"Coefficient" "StdErr" "t" "Pr>|t|"} L="Parameter Estimates" f=best6.];
finish regress;

/*Calling results */

y=oil[,2];
y_cov=y;
/* create X matrix of lags  */
p=2;
pvec=(1:p)`;
X=(lag(y,pvec));

/*Building Yule-Walker style regression for PACF calculations*/
X_no_cons=X[nrow(pvec)+1:nrow(X),];
X=(j(nrow(X_no_cons),1,1)||X_no_cons);
y=y[nrow(pvec)+1:nrow(y),];

print y X_no_cons;


nlags=3;
acov=acov(y_cov,nlags);

/*Looping to construct ACF for 12 lags*/
acov_mat=j(13,1);
do m = 0 to 12;
	y_cov=oil[,2];
	nlags=m;
	acov_m=acov_sum(y_cov,nlags);
	acov_mat[m+1,]=acov_m;
end;

autocorr=acf(acov_mat);

y_cov=oil[,2];
nlags=2;
acov_2=acov_sum(y_cov,nlags);

y_cov=oil[,2];
sas_cov_1=covlag(y_cov,13)`;

print acov;
print acov_mat;
print autocorr;
print sas_cov_1;

run regress;

/*create iml_cov var {sas_cov_1};*/
/*append;*/
/*close iml_cov;*/

quit;

ods graphics off;
title "PROC ARIMA of raw time-series";
proc arima data=sashelp.gulfoil(where=(protractionname=:"Viosca Knoll")) plots=ALL;
	identify var=oil nlag=12 outcov=oil_acov;
run;

title;

/*Commented out because I verified the differences */
/*
data iml_cov;
set iml_cov;
lag=_n_-1;
run;

proc sql;
create table auto_cov_compare as
select
	a.lag,
	a.cov as proc_arima_acov,
	c.sas_cov_1 as covlag_acov,
	a.N as proc_arima_N
from oil_acov as a
inner join iml_cov as c on a.lag=c.lag
;
quit;


data oil(keep=date oil);
set sashelp.gulfoil(where=(protractionname=:"Viosca Knoll"));
run;

proc export data=oil
dbms=csv
outfile="&results_dir./sashelp_oil.csv"
replace
;
run;
*/
