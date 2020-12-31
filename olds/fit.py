import numpy as np
import matplotlib.pyplot as plt
from sklearn import  linear_model

data_full = [[  0.,  10.,  20.,  30.,  40.,  50.,  60.,  70.,  80.,  90., 100., 110., 120., 130.,
              140., 150., 160., 170., 180., 190., 200., 210., 220., 230., 240., 250., 260., 270.,
              280., 290., 300., 310., 320., 330., 340., 350., 360., 370., 380., 390., 400., 410.,
              420., 430., 440., 450., 460., 470., 480., 490., 500., 510., 520., 530., 540., 550.,
              560., 570., 580., 590., 600., 610., 620., 630., 640., 650., 660., 670., 680., 690.,
              700., 710., 720., 730., 740., 750., 760., 770., 780., 790., 800.],
        [  0.,   3.,   7.,  10.,  13.,  16.,  19.,  23.,  26.,  29.,  32.,  35.,  38.,  41.,
          43.,  46.,  49.,  52.,  55.,  58.,  60.,  63.,  66.,  68.,  71.,  74.,  76.,  79.,
          81.,  84.,  86.,  89.,  91.,  94.,  96.,  99., 101., 103., 106., 108., 110., 112.,
         115., 117., 119., 121., 124., 126., 128., 130., 132., 134., 136., 138., 140., 142.,
         144., 146., 148., 150., 152., 154., 156., 158., 160., 162., 164., 165., 167., 169.,
         171., 173., 174., 176., 178., 180., 181., 255., 255., 255., 255.]]

data = np.array(data_full)
limt = 76
def linear_reg(arr):

       x = np.expand_dims(arr[0,:],axis=1)# 81,1
       #x = x@np.ones([1,2])

       y= np.expand_dims(arr[1,:],axis=1)
       linreg = linear_model.Lasso()
       model = linreg.fit(x,y)


       y_ = model.predict(x)
       MSE = np.abs(y[:,0]-y_).mean()
       print('MSE = {}'.format(MSE))
       print(model.coef_)
       print(linreg.intercept_)

       plt.plot(x[:,0],y,'r*')
       plt.plot(x[:,0],y_,'b-')
       plt.show()

def linear_reg2(arr):

       x0 = np.expand_dims(arr[0,:],axis=1)# 81,1
       x1 = x0*x0
       #x2 = x1*x0
       x = np.concatenate([x0,x1],axis=1)
       #x = x@np.ones([1,2])

       y= np.expand_dims(arr[1,:],axis=1)
       linreg = linear_model.Lasso()
       model = linreg.fit(x,y)


       y_ = model.predict(x)
       y_2 = x@model.coef_.T + model.intercept_
       MSE = np.abs(y[:,0]-y_)
       print(y_ )
       print(y_2)
       print('MSE = {}'.format(MSE.mean()))
       print(model.coef_)
       print(linreg.intercept_)
       plt.plot(data[0, :], data[1, :], 'b+',label = 'control points')

       plt.plot(x[:,0],y_,'r-',label = 'fitted')
       plt.ylabel('gray(1)')
       plt.xlabel('distances(m)')
       plt.legend()

if __name__ == '__main__':
    linear_reg2(data[:,:limt])
    plt.show()
