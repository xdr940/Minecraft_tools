
#generate texte.file
'''
    root#
        |--traj0  #status  [motion_pattern][roation-offset][location-offset]
            |--world0_shader0  #inception



'''
from path import Path
from random import random
import argparse
import pandas as pd
import random

def relpath_split(relpath):
    relpath = relpath.split('/')
    traj_name=relpath[0]
    shader = relpath[1]
    frame = relpath[2]
    frame=frame.replace('.png','')
    return traj_name, shader, frame

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
        if shader.stem in ['sildurs-e']:
            ret . append(shader)
    return ret
def file_fileter(dataset_path,files,ref_df=None):
    ret=[]
    for file in files:
        if int(file.stem)>=4 and int(file.stem)<=len(files)-4:
            if type(ref_df)==type(None):
                ret.append(file)

            else:
                scene, shader, frame = relpath_split(file.relpath(dataset_path))
                if ref_df.loc[scene + '_' + shader][int(frame)] == 1:
                    ret.append(file)
    return ret

def table_fileter(files):
    pass



def parse_args():
    parser = argparse.ArgumentParser(
        description='MineNav dataset split for training ,validation and test')

    parser.add_argument('--dataset_path', type=str,default='/home/roit/datasets/mcv5',help='path to a test image or folder of images')
    parser.add_argument("--num",
                        default=2000,
                        #default=None
                        )
    parser.add_argument('--reference',
                        # default=None,
                        default='./selection.csv',
                        help='selection table for filtering')
    parser.add_argument("--proportion",default=[0.85,0.1,0.05],help="train, val, test")
    parser.add_argument("--rand_seed",default=12345)
    parser.add_argument("--out_dir",default='../splits/mcv5-sildurs-e-2k-12345-s')

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

    if args.reference:
        ref_df = pd.read_csv(args.reference,index_col='scences')
        print('load refs ok')
    else:
        ref_df=None




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
            files = file_fileter(args.dataset_path,files,ref_df)
            item_list+=files



    #list constructed
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

    print(" train items:{}\n val items:{}\n test items:{}".format(len(item_list[:train_bound]), len(item_list[train_bound:val_bound]), len(item_list[val_bound:test_bound])))
    writelines(item_list[:train_bound],train_txt_p)
    writelines(item_list[train_bound:val_bound],val_txt_p)
    writelines(item_list[val_bound:test_bound],test_txt_p)













if  __name__ == '__main__':
    options = parse_args()
    main(options)