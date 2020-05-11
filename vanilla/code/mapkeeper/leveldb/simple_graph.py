#bar plot with errorbars
#colors http://www.sagenb.org/src/plot/colors.py
import matplotlib
matplotlib.use('Agg')  # Must be before importing matplotlib.pyplot or pylab
import numpy as np
import matplotlib.pyplot as plt
import matplotlib 
import itertools
import os

fname="randrdthrdslarge.out"

plot_margin = 0.25
params = {'legend.fontsize': 20,'legend.linewidth': 2}
font = {'family' : 'Times',
        'size'   : 20}
matplotlib.rc('font', **font)
lnwidth=2
mrkrsz=10
marker = itertools.cycle(('o', '^', 's', '+', '*')) 
legend = []


def extractdata():
  global  data, headers, xplotlist, xplot, xlabel, yplotlist, benchmarks
  data = np.genfromtxt(fname,delimiter='\t', dtype = float)
  headers = np.genfromtxt(fname,delimiter='\t', dtype = str)
  xplotlist = data[0:1,1:]
  xplot = list(xplotlist.flat)
  xlabel = str(headers[0][0])
  yplotlist = data[1:,1:]
  legendlist = headers[1:,:1]
  benchmarks = list(legendlist.flat)
  
#extractdata()

def sensitivity_graph_gen(xlabel, title, fname, num_benchmarks, benchmarks, xplotlist, yplotlist):

  #for yitem in zip(yplotlist):
  for yitem, xitem in zip(yplotlist, xplotlist):
    #ylist = list(itertools.chain.from_iterable(yitem)) 
    if len(yitem) and len(xitem) > 0:
      line, = plt.plot(xitem, yitem)
      plt.setp(line, marker = marker.next(), linestyle="--", linewidth=lnwidth, markersize=mrkrsz)
      legend.append(line)

  plt.xlabel(xlabel)
  plt.ylabel('Througput (MB/sec)')
  plt.rcParams.update(params)

  x0, x1, y0, y1 = plt.axis()
  plt.axis((x0 - plot_margin,x1 + plot_margin,y0 - plot_margin,y1 + plot_margin))
  plt.legend(legend, benchmarks, loc = 'best')
  output = os.path.splitext(fname)[0]+'.pdf'
  plt.savefig(output)
  #plt.show()















