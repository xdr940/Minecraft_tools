__author__ = 'xdr940'

'''
input a video with long time frames, split it to several dirs with same frames, and named as sorting
'''

# Python
import argparse
import matplotlib.pyplot as plt
from path import Path
from tqdm import tqdm
import os
parser = argparse.ArgumentParser(description="Video2Frames converter")
parser.add_argument('--input_dir', default='/home/roit/bluep2/datasets/mcvideo1024768/dolly/300x_sildurs-h', help="Input video file")
parser.add_argument('--shader',default=None)
parser.add_argument('--output_dir', default="/home/roit/bluep2/datasets/mcvideo1024768/dolly/splits", help="Output folder. If exists it will be removed")
parser.add_argument('--videos2frames_log',
                    #default='./videos2frames_log.txt',
                    default=None
                    )
parser.add_argument('--offset',default=50,help='frames num of the first dir')
parser.add_argument('--framesPerDir',default=50,help='frames num of the other dirs')
parser.add_argument('--base_name',default='')

parser.add_argument('--resize',default=False)

def idx2sub_dir(idx,basename='depth',offset=50):
    num = int(idx/offset)
    return basename+"{:04d}".format(num)

def main(args):

    input_dir = Path(args.input_dir)
    src_files = input_dir.files()
    src_files.sort()
    output_dir = Path(args.output_dir)
    output_dir.mkdir_p()

    if args.shader:
        shader = args.shader
    else:
        shader = input_dir.stem

    print("--> {} frames".format(len(src_files)))

    for idx, file in tqdm(enumerate(src_files)):
        sub_dir = idx2sub_dir(idx,basename=shader)
        sub_name = idx%args.framesPerDir
        dst_dir = output_dir/sub_dir
        dst_dir.mkdir_p()
        dst_name = dst_dir/"{:04d}.png".format(sub_name)
        command = "mv {} {}".format(file,dst_name)
        os.system(command)


    pass


if __name__ == "__main__":
    args = parser.parse_args()
    print("Start splits frames ...")
    ret = main(args)
    exit(ret)

