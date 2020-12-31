from path import Path
import cv2
from tqdm import tqdm
import numpy as np
import matplotlib.pyplot as plt
root =Path('/home/roit/aws/aprojects/xdr94_mono2/mc_test_gt')
out_p = Path('./plasma_gt')
out_p.mkdir_p()
files = root.files()


def main():
    cnt=0
    for item in tqdm(files):

        img = cv2.imread(item)
        img =255- cv2.cvtColor(img,cv2.COLOR_RGB2GRAY)
        img = img/np.mean(img)
        plt.imsave(out_p/item.stem+'.png',img,cmap='plasma')
        cnt+=1


    pass

if __name__ == '__main__':
    main()