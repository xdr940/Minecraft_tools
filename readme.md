# Minecraft tools for computer vision


- video2frame_lite.py

将输入video按照帧率分成帧, 输出为video名字一样的文件夹


 - frames2dirs.py

将刚刚得到的长序列合并的total_frame_dir 按帧数量分割成子文件夹

例如

```
  |-0xdir
  	|-0000.png
  	|-0001.png
  	|-..
  	|-1399.png
  
  ==>
  
  |-split
  	|-0000
  	   |-0000.png
  	   |-0001.png
  	   |-...
  	   |-0049.png
  	|-0001
  	   |-0001.png
  	   |-...
  	|-0027
  	   |-0001.png
  	   |-..
```

 - files_restruct_*.sh
 
 这里通过sh文件进行restructuring, * \in (0,8)



```
mvdirs
	|-dirs
	  |-dir1
	    |-0000.png
	    |-000n.png
	  |-dir2
	    |-0000.png
	    |-0001.png
		
	==>
	
	|-mcvn
	  |-traj1
	    |-shader1
	      |-0000.png
	  |-traj2
	    |-shader2
			
			

```



### steps

 - step1 video 2 frames
 
 把shader名字 ctrl f 换了然后
 ```apex
bash split.sh
```
 
 - step2 frame 2 dirs
 类似的, 吧shader名字换了
 ```apex
bash frame2dirs.sh
```

- step3 dirs send

```apex
bash files_restruct_0*.sh

bash files_restruct_0*.sh
...


```

