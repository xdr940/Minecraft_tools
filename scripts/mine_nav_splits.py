
#generate texte.file
'''
    root#
        |--traj0  #status  [motion_pattern][roation-offset][location-offset]
            |--world0_shader0  #inception



'''
from path import Path
from random import random
import argparse

import random



def writelines(list,path):
    lenth = len(list)
    with open(path,'w') as f:
        for i in range(lenth):
            if i == lenth-1:
                f.writelines(str(list[i]))
            else:
                f.writelines(str(list[i])+'\n')

def readlines(filename):
    """Read all the lines in a text file and return as a list
    """
    with open(filename, 'r') as f:
        lines = f.read().splitlines()
    return lines

def sence_fileter(sences):
    #sences=[]
    return sences
def shader_fileter(shaders):
    ret = []
    for shader in shaders:
        if shader.stem in ['sildurs']:
            ret . append(shader)
    return ret
def file_fileter(files):
    ret=[]
    for file in files:
        if int(file.stem)>=2 and int(file.stem)<=len(files)-2:
            ret.append(file)
    return ret



def parse_args():
    parser = argparse.ArgumentParser(
        description='MineNav dataset split for training ,validation and test')

    parser.add_argument('--dataset_path', type=str,default='/home/roit/datasets/mcv3',help='path to a test image or folder of images')
    parser.add_argument("--num",
                        default=500,
                        #default=None
                        )
    parser.add_argument("--proportion",default=[0.9,0.05,0.05],help="train, val, test")
    parser.add_argument("--rand_seed",default=12345)
    parser.add_argument("--out_dir",default='../splits/mcv3-sildurs-12345-lite')

    return parser.parse_args()
def main(args):
    '''

    :param args:
    :return:none , output is  a dir includes 3 .txt files
    '''
    [train_,val_,test_] = args.proportion
    out_num = args.num
    if train_+val_+test_-1.>0.01:#delta
        print('erro')
        return



    out_dir = Path(args.out_dir)
    out_dir.mkdir_p()
    train_txt_p = out_dir/'train.txt'
    val_txt_p = out_dir/'val.txt'
    test_txt_p = out_dir/'test.txt'


    dataset_path = Path(args.dataset_path)
    trajs = dataset_path

    item_list=[]#


    # filtering and combination
    sences = trajs.dirs()
    sences.sort()#blocks
    sences = sence_fileter(sences)
    for sence in sences:
        shaders = sence.dirs()
        shaders.sort()
        shaders = shader_fileter(shaders)
        for shader in shaders:
            files = shader.files()
            files.sort()
            files = file_fileter(files)
            item_list+=files
    random.seed(args.rand_seed)
    random.shuffle(item_list)
    if out_num and out_num<len(item_list):
        item_list=item_list[:out_num]

    for i in range(len(item_list)):
        item_list[i] = item_list[i].relpath(dataset_path)

    length = len(item_list)
    train_bound = int(length * args.proportion[0])
    val_bound = int(length * args.proportion[1]) + train_bound
    test_bound = int(length * args.proportion[2]) + val_bound


    writelines(item_list[:train_bound],train_txt_p)
    writelines(item_list[train_bound:val_bound],val_txt_p)
    writelines(item_list[val_bound:test_bound],test_txt_p)













if  __name__ == '__main__':
    options = parse_args()
    main(options)