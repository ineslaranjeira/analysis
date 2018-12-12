# -*- coding: utf-8 -*-
"""
Created on Tue Sep 11 18:39:52 2018

@author: Miles
"""

import psychofit as psy
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
import numpy as np
import scipy as sp
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import timedelta

#from matplotlib.dates import MONDAY
import psychofit as psy # https://github.com/cortex-lab/psychofit
import seaborn as sns 
import pandas as pd
from IPython import embed as shell

from mpl_toolkits.axes_grid1.inset_locator import inset_axes


def fit_psychfunc(df):
    choicedat = df.groupby('signedContrast').agg({'trial':'max', 'choice2':'mean'}).reset_index()
    pars, L = psy.mle_fit_psycho(choicedat.values.transpose(), P_model='erf_psycho_2gammas', 
        parstart=np.array([choicedat['signedContrast'].mean(), 20., 0.05, 0.05]), 
        parmin=np.array([choicedat['signedContrast'].min(), 0., 0., 0.]), 
        parmax=np.array([choicedat['signedContrast'].max(), 100., 1, 1]))
    df2 = {'bias':pars[0],'threshold':pars[1], 'lapselow':pars[2], 'lapsehigh':pars[3]}

    return pd.DataFrame(df2, index=[0])

def plot_psychometric(df, ax=None, color="black"):
    """
    Plots psychometric data for a given DataFrame of behavioural trials
    
    If the data contains more than six different contrasts (or > three per side)
    the data are fit with an erf function.  The x-axis is percent contrast and 
    the y-axis is the proportion of 'rightward choices', i.e. trials where the 
    subject turned the wheel clockwise to threshold.
    
    Example:
        df = alf.load_behaviour('2018-09-11_1_Mouse1', r'\\server\SubjectData')
        plot_psychometric(df)
        
    Args:
        df (DataFrame): DataFrame constructed from an ALF trials object.
        ax (Axes): Axes to plot to.  If None, a new figure is created.
        
    Returns:
        ax (Axes): The plot axes
    """
    
    if len(df['signedContrast'].unique()) > 4:
        df2 = df.groupby(['signedContrast']).agg({'choice':'count', 'choice2':'mean'}).reset_index()
        df2.rename(columns={"choice2": "fraction", "choice": "ntrials"}, inplace=True)

        pars, L = psy.mle_fit_psycho(df2.transpose().values, # extract the data from the df
                                     P_model='erf_psycho_2gammas',
                                     parstart=np.array([df2['signedContrast'].mean(), 20., 0.05, 0.05]),
                                     parmin=np.array([df2['signedContrast'].min(), 0., 0., 0.]), 
                                     parmax=np.array([df2['signedContrast'].max(), 100., 1, 1]))
        sns.lineplot(np.arange(-100,100), psy.erf_psycho_2gammas( pars, np.arange(-100,100)), color=color, ax=ax)

    # plot datapoints on top
    sns.lineplot(x='signedContrast', y='choice2', err_style="bars", linewidth=0, linestyle='None', mew=0.5,
        marker='.', ci=68, data=df, color=color, ax=ax)

    # Reduce the clutter
    ax.set_xticks([-100, -50, 0, 50, 100])
    ax.set_xticklabels(['-100', '-50', '0', '50', '100'])
    ax.set_yticks([0, .5, 1])
    # Set the limits
    ax.set_xlim([-110, 110])
    ax.set_ylim([-0.03, 1.03])
    ax.set_xlabel('Contrast (%)')

    return ax


def plot_chronometric(df, ax, color):

    sns.lineplot(x='signedContrast', y='rt', err_style="bars", mew=0.5,
        estimator=np.median, marker='.', ci=68, data=df, color=color, ax=ax)
    ax.set(xlabel="Contrast (%)", ylabel="RT (s)")
    ax.grid(True)
    ax.set_xticks([-100, -50, 0, 50, 100])
    ax.set_xticklabels(['-100', '-50', '0', '50', '100'])

def plot_water_weight_curve(weight_water, baseline, ax):

    xlims = [weight_water.date.min()-timedelta(days=2), weight_water.date.max()+timedelta(days=2)]

    # use pandas plot for a stacked bar - water types
    wa_unstacked = weight_water.pivot_table(index='days',
        columns='water_type', values='water_administered', aggfunc='sum').reset_index()

    # shorten names for legend
    wa_unstacked.columns = wa_unstacked.columns.str.replace("Water", "Wa")
    wa_unstacked.columns = wa_unstacked.columns.str.replace("Sucrose", "Sucr")
    wa_unstacked.columns = wa_unstacked.columns.str.replace("Citric Acid", "CA")
    wa_unstacked.columns = wa_unstacked.columns.str.replace("Hydrogel", "Hdrg")

    # mark the citric acid columns to indicate adlib amount
    for ic, c in enumerate(wa_unstacked.columns):
        if 'CA' in c:
            wa_unstacked[c].replace({0:2}, inplace=True)

    # https://stackoverflow.com/questions/44250445/pandas-bar-plot-with-continuous-x-axis
    plotvar       = wa_unstacked
    plotvar.index = plotvar.days
    plotvar.drop(columns='days', inplace=True)
    plotvar = plotvar.reindex(np.arange(weight_water.days.min()-2, weight_water.days.max()+2))

    # sort the columns by possible water types
    plotvar = plotvar[sorted(list(plotvar.columns.values), reverse=True)]
    plotvar.plot(kind='bar', style='.', stacked=True, ax=ax, edgecolor="none")
    l = ax.legend(loc='lower left', prop={'size': 'xx-small'},
        bbox_to_anchor=(0., 1.02, 1., .102),
        ncol=2, mode="expand", borderaxespad=0., frameon=False)
    l.set_title('')
    ax.set(ylabel="Water intake (mL)", xlabel='', xlim=xlims)
    ax.yaxis.label.set_color("#0072B2")

    # overlay the weight curve
    weight_water2 = weight_water.groupby('days').mean().reset_index()
    weight_water2 = weight_water2.dropna(subset=['weight'])
    righty = ax.twinx()

     # add a line for 85% of baseline weight
    righty.axhline(y=baseline.weight[0]*0.85, color='k', linestyle='--', linewidth=0.5)

    # plot weight curve
    sns.lineplot(x=weight_water2.days, y=weight_water2.weight, ax=righty, color='.15', marker='o')
    
    # also show the value that we're using as the baseline with a different marker
    try: # only if there is a baseline logged
        baseline['days'] = weight_water.loc[weight_water['date'] == baseline['date'][0], 'days'].iloc[0]
        sns.scatterplot(x='days', y='weight', data=baseline, ax=righty, marker='D', 
            facecolor='white', edgecolor='black', s=10, zorder=100, legend=False)
    except:
        pass
    
    righty.grid(False)
    righty.set(xlabel='', ylabel="Weight (g)",
        xlim=[weight_water.days.min()-2, weight_water.days.max()+2], ylim=[baseline.weight[0]*0.8, baseline.weight[0]*1.2])

    # correct the ticks to show dates, not days
    # also indicate Mondays by grid lines
    ax.set_xticks([weight_water.days[i] for i, dt in enumerate(weight_water.date) if dt.weekday() is 0])
    ax.set_xticklabels([weight_water.date[i].strftime('%b-%d') for i, dt in enumerate(weight_water.date) if dt.weekday() is 0])
    for item in ax.get_xticklabels():
        item.set_rotation(60)

def plot_trialcounts_sessionlength(behav, ax, xlims):

    trialcounts = behav.groupby(['date'])['trial'].max().reset_index()
    sns.lineplot(x="date", y="trial", marker='o', color=".15", data=trialcounts, ax=ax)
    ax.set(xlabel='', ylabel="Trial count", xlim=xlims)

    # compute the length of each session
    behav['sessionlength'] = (behav.end_time - behav.start_time)
    behav['sessionlength'] = behav.sessionlength.dt.total_seconds() / 60
    sessionlength = behav.groupby(['date'])['sessionlength'].mean().reset_index()

    righty = ax.twinx()
    sns.lineplot(x="date", y="sessionlength", marker='o', color="firebrick", data=sessionlength, ax=righty)
    righty.yaxis.label.set_color("firebrick")
    righty.tick_params(axis='y', colors='firebrick')
    righty.set(xlabel='', ylabel="Session (min)", ylim=[0,80], xlim=xlims)

    righty.grid(False)
    fix_date_axis(righty)
    fix_date_axis(ax)

def plot_performance_rt(behav, ax, xlims):

    behav['correct_easy'] = behav.correct
    behav.loc[np.abs(behav['signedContrast']) < 50, 'correct_easy'] = np.NaN
    correct_easy = behav.groupby(['date'])['correct_easy'].mean().reset_index()

    sns.lineplot(x="date", y="correct_easy", marker='o', color=".15", data=correct_easy, ax=ax)
    ax.set(xlabel='', ylabel="Performance (easy trials)",
        xlim=xlims, yticks=[0.5, 0.75, 1], ylim=[0.4, 1.01])
    # ax.yaxis.label.set_color("black")

    # RTs on right y-axis
    trialcounts = behav.groupby(['date'])['rt'].median().reset_index()
    righty = ax.twinx()
    sns.lineplot(x="date", y="rt", marker='o', color="firebrick", data=trialcounts, ax=righty)

    righty.yaxis.label.set_color("firebrick")
    righty.tick_params(axis='y', colors='firebrick')
    righty.set(xlabel='', ylabel="RT (s)", ylim=[0.1,10], xlim=xlims)
    righty.set_yscale("log")

    righty.yaxis.set_major_formatter(mpl.ticker.FuncFormatter(lambda y,pos: ('{{:.{:1d}f}}'.format(int(np.maximum(-np.log10(y),0)))).format(y)))
    righty.grid(False)
    fix_date_axis(righty)
    fix_date_axis(ax)

def plot_contrast_heatmap(behav, ax):

    import copy; cmap=copy.copy(plt.get_cmap('vlag'))
    cmap.set_bad(color="w") # remove those squares

    # TODO: only take the mean when there is more than 1 trial (to remove bug in early sessions)
    pp  = behav.groupby(['signedContrast', 'days']).agg({'choice2':'mean'}).reset_index()
    pp2 = pp.pivot("signedContrast", "days",  "choice2").sort_values(by='signedContrast', ascending=False)
    pp2 = pp2.reindex([-100, -50, -25, -12, -6, 0, 6, 12, 25, 50, 100])

    # inset axes for colorbar, to the right of plot
    axins1 = inset_axes(ax, width="5%", height="90%", loc='right',
    bbox_to_anchor=(0.15, 0., 1, 1), bbox_transform=ax.transAxes, borderpad=0,)
    # now heatmap
    sns.heatmap(pp2, linewidths=.5, ax=ax, vmin=0, vmax=1, cmap=cmap, cbar=True,
    cbar_ax=axins1,
    cbar_kws={'label': 'Choose right (%)', 'shrink': 0.8, 'ticks': []})
    ax.set(ylabel="Contrast (%)")

    # fix the date axis
    dates  = behav.date.unique()
    xpos   = np.arange(len(dates)) + 0.5 # the tick locations for each day
    xticks = [i for i, dt in enumerate(dates) if pd.to_datetime(dt).weekday() is 0]
    ax.set_xticks(np.array(xticks) + 0.5)

    xticklabels = [pd.to_datetime(dt).strftime('%b-%d') for i, dt in enumerate(dates) if pd.to_datetime(dt).weekday() is 0]
    ax.set_xticklabels(xticklabels)
    for item in ax.get_xticklabels():
        item.set_rotation(60)
    ax.set(xlabel='')

def fix_date_axis(ax):
    # deal with date axis and make nice looking 
    ax.xaxis_date()
    ax.xaxis.set_major_locator(mdates.WeekdayLocator(byweekday=mdates.MONDAY))
    ax.xaxis.set_major_formatter(mdates.DateFormatter('%b-%d'))
    for item in ax.get_xticklabels():
        item.set_rotation(60)

