/* Rugby Union Hierarchical Model using PROC MCMC

This script creates a hierarchical model for the Six Nations in order to estimate the win-rate of each side using a hierarchical bayesian model

Here we want to model the home win rate and compare it to the away win rate to assess which sides have the strongest home advantage
 */

/* import csv */

PROC IMPORT replace DATAFILE='<your_path>/six_nations.csv'
	DBMS=CSV
	OUT=WORK.Six_Nations;
	GETNAMES=YES ;
RUN;

proc print data=six_nations;title 'Six Nations Results 2023-2020';run;

/* prepare data */

data six_nations_rates;
set six_nations;
games = 1;
if HomeScore gt AwayScore then home_win = 1;
if HomeScore lt AwayScore then home_win = 0;
if AwayScore gt HomeScore then away_win = 1;
if AwayScore lt HomeScore then away_win = 0;
drop venue year homescore awayscore;
run;

proc sql; create table six_nations_model as
select home, away, sum(home_win) as HomeWins, sum(away_win) as AwayWins,sum(games) as GamesPlayed
from six_nations_rates group by home, away;quit;


/* MCMC Model - Home Win Rate */
proc sort data=six_nations_model; by home away;run;

proc mcmc data=six_nations_model outpost=home_win_rate nbi=2000 nmc=5000 ntu=1000  alg=nuts ;
by home;
parms  a b win_rate;
hyperprior a ~ gamma(shape=4, iscale=1);
hyperprior b ~ gamma(shape=4, iscale=1);
prior win_rate ~ beta(a,b);
random wr_team ~  beta(a,b) subject=home;
model HomeWins ~ binomial(n=GamesPlayed,p=win_rate);
run;

/* MCMC Model - Away Win Rate */
proc sort data=six_nations_model; by away home;run;

proc mcmc data=six_nations_model outpost=away_win_rate nbi=2000 nmc=5000 ntu=1000  alg=nuts;
by away;
parms  a b win_rate;
hyperprior a ~ gamma(shape=4, iscale=1);
hyperprior b ~ gamma(shape=4, iscale=1);
prior win_rate ~ beta(a,b);
random wr_team ~  beta(a,b) subject=away;
model AwayWins ~ binomial(n=GamesPlayed,p=win_rate);
run;

/* merge datasets */

data home_est;
set home_win_rate;
rename wr_team_England = "England_Home"n 
wr_team_France = "France_Home"n 
wr_team_Ireland = "Ireland_Home"n 
wr_team_Italy = "Italy_Home"n 
wr_team_Scotland = "Scotland_Home"n 
wr_team_Wales = "Wales_Home"n;
drop home iteration win_rate a b logprior loghyper logreff loglike logpost;
run;

data away_est;
set away_win_rate;
rename wr_team_England = "England_Away"n 
wr_team_France = "France_Away"n 
wr_team_Ireland = "Ireland_Away"n 
wr_team_Italy = "Italy_Away"n 
wr_team_Scotland = "Scotland_Away"n 
wr_team_Wales = "Wales_Away"n;
drop away iteration win_rate a b logprior loghyper logreff loglike logpost;
run;

data est_win_rates;
set home_est away_est;
run;
ods graphics / noborder;
proc template;
define statgraph Stat.MCMC.Graphics.Caterpillar;                                
   dynamic _OverallMean _VarName _VarMean _XLower _XUpper _byline_ _bytitle_    
      _byfootnote_;                                                             
   begingraph;                                                                  
      entrytitle "Six Nations Win Rates";                                            
      layout overlay / yaxisopts=(offsetmin=0.05 offsetmax=0.05 display=(line   
         ticks tickvalues)) xaxisopts=(display=(line ticks tickvalues));        
         referenceline x=_OVERALLMEAN / lineattrs=(color=                       
            GraphReference:ContrastColor);                                      
         HighLowPlot y=_VARNAME high=_XUPPER low=_XLOWER / lineattrs=           
            GRAPHCONFIDENCE;                                                    
         scatterplot y=_VARNAME x=_VARMEAN / markerattrs=(size=5 symbol=        
            circlefilled);                                                      
      endlayout;                                                                
      if (_BYTITLE_)                                                            
         entrytitle _BYLINE_ / textattrs=GRAPHVALUETEXT;                        
      else                                                                      
         if (_BYFOOTNOTE_)                                                      
            entryfootnote halign=left _BYLINE_;                                 
         endif;                                                                 
      endif;                                                                    
   endgraph;                                                                    
end;   
run;

/* Visualize Home Win Rate */
title 'Estimated Difference between Home and Away Win Rates by Team (2020-23)';
%CATER(data=est_win_rates,var=_ALL_); 


