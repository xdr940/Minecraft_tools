import cv2
import matplotlib.pyplot as plt
import numpy as np
if __name__ == '__main__':
    img = cv2.imread('./0011.png')
    img = cv2.cvtColor(img,cv2.COLOR_RGB2GRAY)

    mask = True^(img ==20)
    mask = mask.astype(np.float)


    print('ok')
