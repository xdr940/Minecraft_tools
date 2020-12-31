

from datasets.mc_dataset import MCDataset
from scripts.options import MCOptions
from torch.utils.data import DataLoader
from utils.official import *
from path import Path

options = MCOptions()
opts = options.parse()




def main():
    fpath =Path('../mc')
    train_filenames = readlines(fpath/'train.txt')
    val_filenames = readlines(fpath/'val.txt')
    img_ext = '.png'

    train_dataset = MCDataset(
        data_path=opts.data_path,
        filenames=train_filenames,
        height=opts.height,
        width=opts.width,
        frame_idxs=opts.frame_idxs,
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


if __name__=="__main__":
    main()