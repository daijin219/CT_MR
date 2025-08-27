# Dicom to nii

Reference: https://blog.csdn.net/qianyunzzz/article/details/129928414

使用SPM12将DICOM格式转为nii格式文件

1.  更改路径： D:\MATLAB\spm12
2.  addpath('D:\MATLAB\spm12')
3.  在命令行窗口直接输入spm
    ![alt text](image.png)
4.  打开后选择fMRI（选PET/VBM也行）
   ![alt text](image-1.png)
5.  Dicom import
   ![alt text](image-2.png)
6.  Run △

# MR and CT to electrode

Reference: https://neuroimage.usc.edu/brainstorm/Tutorials/IeegContactLocalization 

New Tutorial co-registration: https://neuroimage.usc.edu/brainstorm/seeg/ct2mri?action=show


1. MRI
   MNI normalization: segment
   ![alt text](image-3.png)
2. CT(里面的弹窗目前选择segment-smp12，yes-no的选项都yes)
   2.1   coregister效果不好的话，可以改用SPM
   ![alt text](image-4.png)
   ![alt text](image-5.png)
   
   2.2   如果CT整体颜色过浅会影响coregister结果
   下图颜色过浅
   
   ![alt text](image-9.png)

New Tutorials: https://neuroimage.usc.edu/brainstorm/seeg/SeegContactLocalization


4. Generate isoSurface
   ![alt text](image-7.png)
   ![alt text](image-8.png)
5. Electrode labelling and contact localization
   ![alt text](image-10.png)

   
# Plot electrodes in common template
1. 运行combine_channels合并所有患者的电极点位置
2. 在default anatomy中选择SEEG/ECoG implantation
3. 1
4. 

5. 显示电极
   ![alt text](image-6.png)
6. 修改背景画面颜色
   ![alt text](image-11.png)
7. 保存为图片
   ![alt text](image-12.png)

8. 



