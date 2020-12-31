
import numpy as np
import matplotlib.pyplot as plt
data_normal = [[0,0,255],
                [10,43,251],
               [20,86,240],
               [30,127,221],
               [40,164,196],
               [45,180,180],
               [50,195,165],
               [60,220,128],
               [70,239,88],
               [80,251,45],
               [90,255,0]]

data_normal = np.array(data_normal)
delta = 1./256
x = data_normal[:,0]
b = data_normal[:,1]*delta
r = data_normal[:,2]*delta

plt.plot(x,r,'r')
plt.plot(x,b,'b')
plt.show()

