from path import Path
import os

def main():
    in_dir = Path('/home/roit/datasets/mcrandom/0005')
    files = in_dir.files()
    files.sort()
    for file in files:
        stem = file.stem
        dst_name = file.replace(stem,'tmp_{}'.format(stem))
        cmd = "mv {} {}".format(file,dst_name)
        os.system(cmd)
    files = in_dir.files()
    files.sort()
    for idx,file in enumerate(files):
        stem = file.stem
        dst_name = file.replace(stem, '{:04d}'.format(idx))
        cmd = "mv {} {}".format(file, dst_name)
        os.system(cmd)

    pass


if __name__ == '__main__':
    main()