/*SAS Weekly Problem 21/08/2019 */
%let user_dir=<user directory>;
/*Load text file BLOOD.txt I found on github into WORK */
data blood;
   infile "&user_dir/blood.txt" truncover;
   length Gender $ 6 BloodType $ 2 AgeGroup $ 5;
   input Subject 
         Gender 
         BloodType 
         AgeGroup
         WBC 
         RBC 
         Chol;
   label Gender = "Gender"
         BloodType = "Blood Type"
         AgeGroup = "Age Group"
         Chol = "Cholesterol";
run;

/*Reading in Blood Pressure Dataset I found on github (presumably the one intended for the Challenge)*/
data bloodpressure;
   input Gender : $1. 
         Age
         SBP
         DBP;
datalines;
M 23 144 90
F 68 110 62
M 55 130 80
F 28 120 70
M 35 142 82
M 45 150 96
F 48 138 88
F 78 132 76
;

/*Question 1 Frequencies */
proc freq data= blood;
	title Height=12pt font="Helvetica" color=White bcolor=LightBlue justify=center "One-Way Frequencies of Gender, Blood-Type, and Age Group";
	tables gender bloodtype agegroup / nocum nopercent;
run;
title;

/*Question 2 Frequencies */
proc format;
	value age_grps
	low - 40 = '<= 40'
	41 - 60 = '41-60'
	61 - high = '>= 61'
	;
run;

proc freq data= bloodpressure;
	title Height=12pt font="Helvetica" color=White bcolor=LightBlue justify=center "One-Way Frequencies of Age from a Blood Pressure dataset";
	tables age / nocum nopercent;
	format age age_grps.;
run;
title;

/*Question 3 Frequencies */
proc format;
	value chol_grps
	low - 200 = 'Normal'
	201-high = 'High'
	. = 'Missing'
	;
run;

ods output OneWayFreqs=q3_output_pt1;
proc freq data= blood;
	tables chol / nocum nopercent;
	format chol chol_grps.;
run;

ods output OneWayFreqs=q3_output_pt2;
proc freq data= blood;
	tables chol / nocum nopercent missing;
	format chol chol_grps.;
run;

proc sql;
create table q3_output_final as
	select 	put(coalesce(a.Chol,b.Chol),chol_grps.) as Chol,
			coalesce(a.Frequency,b.Frequency) as Frequency,
			sum(b.Frequency) as Total_with_missing,
			sum(a.Frequency) as Total_no_missing,
			calculated Total_with_missing - calculated Total_no_missing as Proc_freq_diff
	from q3_output_pt2 as b left join q3_output_pt1 as a
	on a.Chol=b.Chol
	;
quit;

proc print data=q3_output_final noobs;
title Height=12pt font="Helvetica" color=White bcolor=LightBlue justify=center "Comparing the results of Proc Freq using User Formats and the Missing Option";
run;
title;
