"""
PSYCHOMETRIC AND CHRONOMETRIC FUNCTIONS OF TRAINED ANIMALS
Anne Urai, CSHL, 2019
"""

import pandas as pd
import numpy as np
import sys, os, time
import matplotlib.pyplot as plt
from figure_style import seaborn_style
import datajoint as dj
from IPython import embed as shell # for debugging
from scipy.special import erf # for psychometric functions

# import wrappers etc
from ibl_pipeline import reference, subject, action, acquisition, data, behavior
from ibl_pipeline.utils import psychofit as psy
from ibl_pipeline.analyses import behavior as behavioral_analyses

sys.path.insert(0, '/Users/urai/Documents/code/analysis_IBL/python')
from dj_tools import *

## INITIALIZE A FEW THINGS
sns.set(style="ticks", context="paper", font_scale=1.2)
figpath  = os.path.join(os.path.expanduser('~'), 'Data/Figures_IBL')
cmap = sns.diverging_palette(20, 220, n=3, center="dark")
sns.set_palette("gist_gray")  # palette for water types

# ================================= #
# GET DATA FROM TRAINED ANIMALS
# ================================= #

#TODO: add a criterion for each mouse's project (only IBL-wide mice)

use_subjects = (subject.Subject() & 'subject_birth_date > "2018-09-01"' \
			   & 'subject_line IS NULL OR subject_line="C57BL/6J"') * subject.SubjectLab()
criterion = behavioral_analyses.SessionTrainingStatus()
sess = ((acquisition.Session & 'task_protocol LIKE "%trainingChoiceWorld%"') \
		* (criterion & 'training_status="trained"')) * use_subjects

b = (behavior.TrialSet.Trial & sess) * subject.Subject() * subject.SubjectLab()
bdat = pd.DataFrame(b.fetch(order_by='subject_nickname, session_start_time, trial_id'))
behav = dj2pandas(bdat)

lab_names = {'carandinilab':'Carandini & Harris lab', 'mainenlab':'Mainenlab', 'churchlandlab':'Churchland lab',
			 'wittenlab':'Witten lab',
			 'angelakilab':'Angelakilab', 'mrsicflogellab':'Mrsic-flogel lab', 'zadorlab':'Zador lab',
			 'danlab':'Dan lab'}

# ================================= #
# PSYCHOMETRIC FUNCTIONS
# ================================= #

fig = sns.FacetGrid(behav,
	col="lab_name", col_wrap=4, col_order=list(lab_names.keys()),
	sharex=True, sharey=True, aspect=1)
fig.map(plot_psychometric, "signed_contrast", "choice_right", "subject_nickname")
fig.set_axis_labels('Signed contrast (%)', 'Rightward choice (%)')
for ax, title in zip(fig.axes.flat, list(lab_names.values())):
    ax.set_title(title)
fig.despine(trim=True)
fig.savefig(os.path.join(figpath, "figure4a_psychfuncs_perlab.pdf"))
fig.savefig(os.path.join(figpath, "figure4a_psychfuncs_perlab.png"), dpi=600)
plt.close('all')

fig = sns.FacetGrid(behav,
	col="subject_nickname", col_wrap=8, hue="lab_name", palette="colorblind",
					sharex=True, sharey=True, aspect=1)
fig.map(plot_psychometric, "signed_contrast", "choice_right", "subject_nickname").add_legend()
fig.set_axis_labels('Signed contrast (%)', 'Rightward choice (%)')
fig.set_titles("{col_name}")
fig.despine(trim=True)
fig.savefig(os.path.join(figpath, "figure4a_psychfuncs_permouse.pdf"))
plt.close('all')

# ================================= #
# CHRONOMETRIC FUNCTIONS
# ================================= #

fig = sns.FacetGrid(behav,
	col="lab_name", col_wrap=4, col_order=list(lab_names.keys()),
	palette="gist_gray", sharex=True, sharey=True, aspect=1)
fig.map(plot_chronometric, "signed_contrast", "rt", "subject_nickname")
fig.set_axis_labels('Signed contrast (%)', 'Response time (s)')
for ax, title in zip(fig.axes.flat, list(lab_names.values())):
    ax.set_title(title)
fig.despine(trim=True)
fig.savefig(os.path.join(figpath, "figure4b_chronfuncs_perlab.pdf"))
fig.savefig(os.path.join(figpath, "figure4b_chronfuncs_perlab.png"), dpi=600)
plt.close('all')

fig = sns.FacetGrid(behav,
	col="subject_nickname", col_wrap=8, hue="lab_name", palette="colorblind",
					sharex=True, sharey=True, aspect=1)
fig.map(plot_chronometric, "signed_contrast", "rt", "subject_nickname").add_legend()
fig.set_axis_labels('Signed contrast (%)', 'Response time (s)')
fig.set_titles("{col_name}")
fig.despine(trim=True)
fig.savefig(os.path.join(figpath, "figure4b_chronfuncs_permouse.pdf"))
plt.close('all')