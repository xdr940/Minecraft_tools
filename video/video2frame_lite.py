
#
import argparse
import os, sys
import shutil
import subprocess
import json
from path import Path
import matplotlib.pyplot as plt
from tqdm import tqdm
# Opencv
import cv2
import numpy as np

parser = argparse.ArgumentParser(description="Video2Frames converter")
parser.add_argument('--input', default='/home/roit/bluep2/datasets/mcvideo1024768/dolly/m100x_sildurs-h.mp4', help="Input video file")
parser.add_argument('--output', default='/home/roit/bluep2/datasets/mcvideo1024768/dolly/m100x_sildurs-h', help="Output folder. If exists it will be removed")
parser.add_argument('--ext',default='png')

args = parser.parse_args()

def main():
    global args

    #io check
    root = Path(args.input)
    print(root)

    in_path = Path(args.input)
    if not in_path.exists():
        parser.error("Input video file is not found")
        return 1
    if args.output:
        out_path = Path(args.output)
    else:
        out_path = Path(in_path.stem)

    out_path.makedirs_p()  # without exception 'already exist'






    cap = cv2.VideoCapture()
    cap.open(args.input)
    if not cap.isOpened():
        parser.error("Failed to open input video")
        return 1

    frameCount = cap.get(cv2.CAP_PROP_FRAME_COUNT)#视频最大能切分几张


    #maxframes = args.maxframes
    #if args.maxframes and frameCount > maxframes:#跳帧决定
    #    skipDelta =int(frameCount / maxframes)#乡下取证
    #    if args.verbose:
    #        print("Video has {fc}, but maxframes is set to {mf}".format(fc=frameCount, mf=maxframes))
    #        print("Skip frames delta is {d}".format(d=skipDelta))
    #else:
    #    skipDelta = 1


    f_cnt = 1#output num of frames
    for  frameId in tqdm(range(int(frameCount))) :    #for frameId in tqdm(range(int(frameCount))):

        ret, frame = cap.read()
        # print frameId, ret, frame.shape
        if not ret:
            print("Failed to get the frame {f}".format(f=frameId))
            continue



        ofname = out_path/'{:04d}.{}'.format(frameId,args.ext)#补零操作
        ret = cv2.imwrite(ofname, frame)
        if not ret:
            print("Failed to write the frame {f}".format(f=frameId))
            continue

        cap.set(cv2.CAP_PROP_POS_FRAMES, frameId)




if __name__ == "__main__":
    print("Start Video2Frames script ...")
    ret = main()
