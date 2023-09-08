# Estimating Win-Rate differences between Home and Away by Side in The Six Nations
This repository gives a brief overview of creating a hierarchical model using PROC MCMC. In particular, we use the random effects statement to model individualized home or away win-rate.

We then visualize this via the autocall macro %CATER to visually compare the win-rates by side for home and away

![](win_rate_differences.png?raw=true)

The analysis can be re-produced using either SAS Code (see "Compare Home and Away Win Rates.sas") or using a SAS Notebook (see "Estimating Win-Rate in the Six Nations.sasnb").

The SAS Notebook can be interacted with in Visual Studio Code and you can view the SAS outputs without having to re-run the code or load the data into your SAS environment.

![](sas_notebook.png?raw=true)
