

from datasets.mc_dataset import MCDataset
from scripts.options import MCOptions
from torch.utils.data import DataLoader
from utils.official import *
from path import Path
import argparse
import matplotlib.pyplot as plt

def args():
    parser = argparse.ArgumentParser(description="Monodepthv2 options")

    parser.add_argument("--data_path",
                             default="/home/roit/datasets/mc2")

    parser.add_argument("--split",default='../splits/mc')
    parser.add_argument("--height", default=384)
    parser.add_argument("--width", default=640)
    parser.add_argument("--frame_idxs", default=[-1, 0, 1])
    parser.add_argument("--scales", default=[0, 1, 2, 3])

    parser.add_argument("--batch_size", default=1)
    parser.add_argument("--num_workers", default=1)
    parser.add_argument("--splits", default='mc')

    return parser.parse_args()
def main(opts):
    fpath =Path(opts.split)
    train_filenames = readlines(fpath/'train.txt')
    val_filenames = readlines(fpath/'val.txt')
    img_ext = '.png'

    train_dataset = MCDataset(
        data_path=opts.data_path,
        filenames=train_filenames,
        height=opts.height,
        width=opts.width,
        frame_sides=[-1,0,1],
        num_scales=len(opts.scales)
    )

    dataloader = DataLoader(
        dataset=train_dataset,
        batch_size=opts.batch_size,
        shuffle=False,
        num_workers=opts.num_workers,
        pin_memory=True,
        drop_last=True
    )


    for batch_idx,inputs in enumerate(dataloader):

        print('ok')



def tensor2img(t):
    return t.detach().cpu().numpy().transpose([1,2,0])



if __name__=="__main__":
    options = args()
    main(options)