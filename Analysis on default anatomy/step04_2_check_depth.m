%% 检查坐标点是否递增
file_id = fopen('D:\SLEEP_PROJECT\MR_CT\Analysis_Code\contact_depth_from_cortex.csv');
depth_csv = textscan(file_id,'%s%f', 'Delimiter', ',', 'HeaderLines', 1 );

depth_this = [];
for i=1:size(depth_csv{1,1},1)
    if depth_csv{1,1}{i,1}(end) == '1' && ~isstrprop(depth_csv{1,1}{i,1}(end-1), 'digit')
        if ~isempty(depth_this)
            if max(diff(depth_this)) > 0
                disp(depth_csv{1,1}{i,1});
                disp(depth_this);
            end
            depth_this = [];
        end
    end
    depth_this = [depth_this, depth_csv{1,2}(i)];
end

disp('End')

%% 可视化头模坐标，删除面部的点
pial_file    = 'D:\SLEEP_PROJECT\MR_CT\Recons_Imaging\scalp_iEEG\anat\@default_subject\tess_head.mat';   % pial surface (cortex)
Pi = load(pial_file);        % -> Pi.Vertices
% 提取结构体中的顶点和面
vertices = Pi.Vertices;
faces = Pi.Faces;

figure;
patch('Vertices', vertices, 'Faces', faces, ...
      'FaceColor', [0.8 0.8 0.8], ...   % 灰色
      'EdgeColor', [0.8 0.8 0.8], ...
      'FaceAlpha', 0.3);                 % 不透明
axis equal;          % 等比 & 关闭坐标轴
view(3);                 % 三维视角
% 设定 x 平面的高度
% x_threshold = 0.105;
% ylim = get(gca, 'XLim');
% zlim = get(gca, 'ZLim');
% y_plane = [ylim(1), ylim(2), ylim(2), ylim(1)];
% z_plane = [zlim(1), zlim(1), zlim(2), zlim(2)];
% x_plane = x_threshold * ones(1, 4);  
% 绘制平面
% hold on;
% fill3(x_plane, y_plane, z_plane, [1 0 0], 'FaceAlpha', 0.3, 'EdgeColor', 'none');  % 红色半透明平面

% 已知两点定义斜率
x1 = 0.1;   z1 = 0.05;
x2 = 0.06;  z2 = -0.1;
% 获取 Y 方向边界范围（平面将在 Y 方向延伸）
ymin = ylim(1);
ymax = ylim(2);
% 构造平面四个角点
% 上面两个点：Y = ymin
P1 = [x1, ymin, z1];
P2 = [x2, ymin, z2];
% 下面两个点：Y = ymax
P3 = [x2, ymax, z2];
P4 = [x1, ymax, z1];
% 合并坐标
X = [P1(1), P2(1), P3(1), P4(1)];
Y = [P1(2), P2(2), P3(2), P4(2)];
Z = [P1(3), P2(3), P3(3), P4(3)];

% 绘制倾斜平面
hold on;
fill3(X, Y, Z, [1 0 0], 'FaceAlpha', 0.3, 'EdgeColor', 'none');  % 红色半透明倾斜平面
