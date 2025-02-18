%% load channel
root_dir = 'D:\SEEG_decode\SEEG_decode_analysis-main\PET_MR\brainstorm_database\MR_CT_Electrode\';
path_channel = '\data\Comman_template\Implantation\channel_240920_1632.mat';
path_anat = '\anat\Comman_template\tess_cortex_pial_low.mat';
% path_anat = '\anat\Comman_template\tess_innerskull_spm_2562V.mat';
% Load the channel file
channelData = load([root_dir, path_channel]);
% Access the Channel structure
Channels = channelData.Channel;

%% Extract Electrode Positions and Labels
% Initialize arrays for positions and labels
positions = [];
labels = {};
% Loop through each channel to extract information
for i = 1:length(Channels)

    positions = [positions; Channels(i).Loc'];
    labels{end+1} = Channels(i).Name;

end

%% Load the Normalized Cortex Surface
% Load the cortex surface
cortexData = load([root_dir, path_anat]);
% Access the vertices and faces
Vertices = cortexData.Vertices;
Faces = cortexData.Faces;

%% decide inside
addpath('D:\MATLAB\inpolyhedron');
% Check which electrodes are inside the cortex
inside = inpolyhedron(Faces, Vertices, positions);
% Filter positions to include only those inside the cortex
positions_inside = positions(inside, :);

%% plot
RGB_pool=[[125,216,206];[255,155,154];[71,108,134];[154,201,255];[254,223,148]; ...
    [88,97,172];[255,127,0];[165,194,226];[154,155,203];[232,68,69];[204,204,204];...
    [102,102,102];[165,118,28];[205,182,218];[212,230,161];[228,154,195]]/255;
% Create a new figure
x1 = 0;
y1 = 0;
width1 = 1000;
height1 = 1000;
figure('Position', [x1, y1, width1, height1]);
% Plot the cortex surface
patch('Vertices', Vertices, 'Faces', Faces, ...
      'FaceColor', [125,216,206]/255, 'EdgeColor', [0.5,0.5,0.5], ...
      'FaceAlpha', 0.1,'EdgeAlpha',0.1); % Semi-transparent cortex
hold on;
% Plot electrode positions
thr = [-0.1, -0.05, -0.04, -0.03, -0.02,-0.01, 0,0.01,0.02,0.03,0.04,0.05,0.1];
for i=1:(size(thr,2)-1)
    idx = find(positions(:,1) > thr(i) & positions(:,1) <= thr(i+1));
    % disp(idx);
    scatter3(positions(idx,1), positions(idx,2), positions(idx,3), 20, RGB_pool(i+1,:),'LineWidth', 1.5);
    hold on;
    disp(RGB_pool(i, :));
end


% Enhance plot aesthetics
xlabel('X');
ylabel('Y');
zlabel('Z');
% title('Electrode Positions on Normalized Cortex');
grid on;
axis equal;
view([0, 0, 1]); % 冠状图
% view([0, 1, 0]); % 横断面
% view([1, 0, 0]); % 矢状图 

% Turn off axes
axis off;

% Save as EPS file
print('D:\影像(1)\3_冠状图', '-depsc');