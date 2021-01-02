# Copyright Niantic 2019. Patent Pending. All rights reserved.
#
# This software is licensed under the terms of the Monodepth2 licence
# which allows for non-commercial use only, the full terms of which are made
# available in the LICENSE file.

from __future__ import absolute_import, division, print_function

import os
import argparse
from path import Path
file_dir = os.path.dirname(__file__)  # the directory that options.py resides in



class MCOptions:

    def __init__(self):
        self.parser = argparse.ArgumentParser(description="Monodepthv2 options")

        # TEST MCDataset

        self.parser.add_argument("--data_path",
                                 default="/home/roit/datasets/MC")
        self.parser.add_argument("--height", default=600)
        self.parser.add_argument("--width", default=800)
        self.parser.add_argument("--frame_sides",default=[-1,0,1])
        self.parser.add_argument("--scales",default=[0,1,2,3])

        self.parser.add_argument("--batch_size",default=1)
        self.parser.add_argument("--num_workers",default=1)

        self.parser.add_argument("--splits",default='mc')

    def parse(self):
        self.options = self.parser.parse_args()
        return self.options
