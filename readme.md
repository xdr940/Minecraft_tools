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

 - files_restruct.py

mvdirs
	
将刚刚得到的dirs按照偏置mv到mcdataset dir中, 并且每个sub dir名字一样, 为shader的名字


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



