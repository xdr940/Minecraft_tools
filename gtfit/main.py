import numpy as np
import cv2

import matplotlib.pyplot as plt
from path import Path

path = Path('C:\\Users\\Administrator\\AppData\\Roaming\\.minecraft\\screenshots')
files = path.files()

img = cv2.imread(files[-1])
h,w,c =img.shape
if h%2!=0:
    center_h=h/2+1
else:
    center_h = h/2
if w%2!=0:
    center_w = w/2+1
else:
    center_w= w/2

print(img[int(center_h),int(center_w)])


plt.imshow(img)
plt.show()


