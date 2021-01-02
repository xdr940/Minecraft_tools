

from __future__ import absolute_import, division, print_function

import os
import skimage.transform
import numpy as np
import PIL.Image as pil
from path import Path
import matplotlib.pyplot as plt
from .mono_dataset import MonoDataset



class MCDataset(MonoDataset):
    def __init__(self,*args,**kwargs):
        super(MCDataset,self).__init__(*args,**kwargs)

        self.full_res_shape = [1920,1080]#

        #
        # FOV = 35d
        # 960 = 1920/2
        # 960/fx = tan 35 =0.7-> fx = 1371
        #
        # 1920 * k[0] = 1371-> k0 = 0.714
        # 1080 * k[1 ]= 1371 -> k1 = 1.27
        self.K=np.array([[0.714, 0, 0.5, 0],
                          [0, 1.27, 0.5, 0],
                          [0, 0, 1, 0],
                          [0, 0, 0, 1]], dtype=np.float32)




        # self.full_res_shape = [800,600]
        #
        # #400/ fx = tan 35 =0.7 --> fx =571.428
        # #800 * k[0] = 571.428 ->> k0 = 0.714
        # #600* k1 = 571.428, k1 =0.952
        # self.K = np.array([[0.714, 0, 0.5, 0],
        #                    [0, 0.952, 0.5, 0],
        #                    [0, 0, 1, 0],
        #                    [0, 0, 0, 1]], dtype=np.float32)

        self.img_ext='.png'
        self.depth_ext = '.png'

        self.MaxDis = 255
        self.MinDis = 0


    def check_depth(self):

        traj_name,shader,frame = self.relpath_split(self.filenames[0])

        depth_filename =Path(self.data_path)/traj_name/"depth"/"{:05d}.jpg".format(int(frame))

        return depth_filename.exists()

    def get_color(self, folder, side, do_flip):
        path =self.__get_image_path__(folder, side)
        color = self.loader(path)

        if do_flip:
            color = color.transpose(pil.FLIP_LEFT_RIGHT)

        return color

    def __get_image_path__(self, folder, side):
        traj,shader,frame = self.relpath_split(folder)
        reframe = "{:05d}".format(int(frame)+side)
        folder=folder.replace(frame,reframe)
        image_path = Path(self.data_path)/ folder
        return image_path



    def get_depth(self, folder, side,  do_flip):
        path = self.__get_depth_path__(folder, side)
        depth_gt = plt.imread(path)
        depth_gt = skimage.transform.resize(depth_gt, self.full_res_shape[::-1], order=0, preserve_range=True, mode='constant')

        if do_flip:
            depth_gt = np.fliplr(depth_gt)
        return depth_gt#[0~1]

    def __get_depth_path__(self, folder, side):

        traj, shader, frame = self.relpath_split(folder)
        reframe = "{:05d}".format(int(frame) + side)
        folder = folder.replace(frame, reframe)
        folder = folder.replace(shader,'depth')
        depth_path = Path(self.data_path) / folder
        return depth_path


    def relpath_split(self,relpath):
        relpath = relpath.split('/')
        traj_name=relpath[0]
        shader = relpath[1]
        frame = relpath[2]
        frame=frame.replace('.jpg','')
        return traj_name, shader, frame
