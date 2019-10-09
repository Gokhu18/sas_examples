/*Creating macro_vars for library and filename (had to change dataset name to be compliant)*/
%let lib_wk=<output_directory>;
%let grid_file=20190923-projects;

/* Reading in dataset  */
proc import
 datafile="&lib_wk./&grid_file..csv"
 out=work.grid
 dbms=csv
 replace
 ;

proc contents data=grid;
run;

proc sql;
select sortedby from dictionary.columns
where libname='WORK' and memname='GRID';
quit;
/*Data has not been sorted by proc sql or proc sort */
proc print data=grid noobs;
run;
/*The dataset appears to be sorted outside of SAS by projectID then userID*/

/*Sorting grid data by userID*/
proc sort data=grid;
by userID;
run;

/*Only a merged userID matched to projectID file was provided 20190923-projects.csv*/
/*Creating my own user datset*/
proc iml;
users=(1:1797)`;
varNames = {userID};
create users from users [colname=varNames];
append from users;
close users;
quit;

/*Create three datasets in the same data step*/
data users_grid_merge(drop=project_count) incomplete(drop=project_count) complete none(drop=project_count);
merge users grid;
output users_grid_merge;
by userID; 
if not missing(projectID) and not missing(startdate) and missing(enddate) then output incomplete;
else if not missing(projectID) and not missing(startdate) and not missing(enddate) 
then do;
	if first.userid then project_count=0;
	project_count+1;
	output complete;
	if last.userid then project_count=0;
end;
else output none;
run;

/*Summary the variables and observations in each */
proc sql;
select distinct 
		a.memname,
		count(*) as Number_of_Variables, b.nobs
		from dictionary.columns as a
		inner join dictionary.tables as b
		on a.memname=b.memname
where a.libname='WORK' and a.memname in ('USERS_GRID_MERGE','INCOMPLETE','COMPLETE','NONE')
group by a.memname
;
quit;

/*
work.complete has 5 variables and 4127 observations.
work.incomplete has 4 variables and 3139 observations.
work.none has 4 variables and 7 observations.
work.users_grid_merge has 4 variables and 7273 observations.
/*
