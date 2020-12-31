

import numpy as np
import cv2
import matplotlib.pyplot as plt

import matplotlib.pyplot as plt
from path import Path

#path = Path('C:\\Users\\Administrator\\Desktop\\aa')
path = Path('C:\\Users\\Administrator\\AppData\\Roaming\\.minecraft\\screenshots')
files = path.files()
normals = []

for f in files:
    #img = plt.imread(f)
    img = cv2.imread(f)
    img= cv2.cvtColor(img,cv2.COLOR_RGB2BGR)
    normals.append(img)

plt.imshow(normals[-1])
plt.show()
