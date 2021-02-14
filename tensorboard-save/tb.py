import tensorboardX as tb
import pandas as pd
from matplotlib import pyplot as plt
import seaborn as sns
from scipy import stats
from packaging import version



experiment_id = "c1KCv3X3QvGwaXfgX1c4tg"
experiment = tb.data.experimental.ExperimentFromDev(experiment_id)
df = experiment.get_scalars()
df