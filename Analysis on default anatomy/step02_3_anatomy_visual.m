%% === 参数 ===
csvPath = 'D:\SLEEP_PROJECT\MR_CT\Analysis_Code\channel_lobes.csv';   % <--- 改成你的 csv 文件
allowedPatients = [2 4 8 10 11 13 33 40];

%% === 读取 CSV ===
T = readtable(csvPath, 'TextType','string');

% 保证字段名（兼容大小写/空格等）
varnames = lower(string(T.Properties.VariableNames));
getVar = @(name) T{:, find(varnames == lower(string(name)), 1, 'first')};

contact   = T{:, find(varnames == "contact", 1, 'first')};
xmm       = double(getVar("xmm"));
ymm       = double(getVar("ymm"));
zmm       = double(getVar("zmm"));
lobeFinal = string(getVar("lobe_final"));

%% === 从 Contact 解析患者编号（英文数字单词-电极名+触点编号） ===
% Contact 形如 'Two-Fifteen1'、'Two-Thirteen3' 等
% 先按 '-' 切分，第一段是患者编号的英文数字词
firstToken = arrayfun(@(s) split(string(s), "-"), contact, 'uni', 0);
firstToken = string(cellfun(@(c) c(1), firstToken));  % 患者英文数字词

% 英文数字词 -> 数字
patientNum = arrayfun(@numword2num, firstToken);

% 只保留允许的患者编号
keep = ismember(patientNum, allowedPatients);
contact   = contact(keep);
xmm       = xmm(keep);
ymm       = ymm(keep);
zmm       = zmm(keep);
lobeFinal = lobeFinal(keep);
patientNum= patientNum(keep);

%% === 颜色：每个 Lobe_Final 一种颜色 ===
lobes = unique(lobeFinal);
nL = numel(lobes);
C = lines(max(nL,7));  % 至少给些颜色
C = C(1:nL, :);

% 为每个点分配颜色
[~, lobeIdx] = ismember(lobeFinal, lobes);
ptColor = C(lobeIdx, :);

%% === 绘图 ===
figure; clf;
hold on;
% 可视化头模型
pial_file    = 'D:\SLEEP_PROJECT\MR_CT\Recons_Imaging\scalp_iEEG\anat\@default_subject\tess_cortex_pial_high.mat';   % pial surface (cortex)
Pi = load(pial_file);        % -> Pi.Vertices
% 提取结构体中的顶点和面
vertices = Pi.Vertices;
faces = Pi.Faces;

patch('Vertices', vertices, 'Faces', faces, ...
      'FaceColor', 'none', ...        % 不填充面
      'EdgeColor', [0.5 0.5 0.5], ... % 灰色边
      'EdgeAlpha', 0.1);              % 边线透明度 (0=完全透明, 1=不透明)     

% 绘制电极点
legH = gobjects(nL,1);
for i = 1:nL
    mask = (lobeIdx == i);
    % 虚拟散点（透明），只用于图例
    legH(i) = scatter3(xmm(mask), ymm(mask), zmm(mask), 36, C(i,:), 'filled', ...
                       'MarkerFaceAlpha', 0.01, 'MarkerEdgeAlpha', 0.01, ...
                       'DisplayName', lobes(i));
    % 在坐标处写"患者编号"文本，颜色按 Lobe_Final
    text(xmm(mask), ymm(mask), zmm(mask), string(patientNum(mask)), ...
        'Color', C(i,:), 'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', 'FontWeight','bold');
end

axis equal; grid on; view(3);
xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
title('Contacts colored by Lobe\_Final, marker = patient number');
% legend(legH, 'Location','bestoutside');
% hold off;

%% === 工具函数：英文数字词 -> 数字（0~40，含复合如 TwentyOne/ThirtyThree） ===
function n = numword2num(s)
    % 去掉空格和非字母
    s = regexprep(char(s), '\s+', '');
    s = regexprep(s, '[^A-Za-z]', '');
    s = lower(string(s));   % 全部转成小写，统一格式

    % 基本 0~19
    base = containers.Map( ...
        lower(["Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine", ...
         "Ten","Eleven","Twelve","Thirteen","Fourteen","Fifteen","Sixteen","Seventeen","Eighteen","Nineteen"]), ...
        num2cell(0:19));

    tens  = containers.Map( ...
        lower(["Twenty","Thirty","Forty"]), ...
        num2cell([20 30 40]));

    n = NaN;

    % 直接命中 0~19
    if base.isKey(s), n = base(s); return; end
    % 直接命中整十
    if tens.isKey(s), n = tens(s); return; end

    % 复合：twentyone, twentytwo, ... thirtythree 等
    keysT = tens.keys;
    for k = 1:numel(keysT)
        tword = string(keysT{k});
        if startsWith(s, tword)
            rest = extractAfter(s, strlength(tword));
            if rest == ""
                n = tens(tword);
                return;
            end
            if base.isKey(rest)
                n = tens(tword) + base(rest);
                return;
            end
        end
    end

    % 如果没匹配，给个警告，返回 NaN
    if isnan(n)
        warning('无法解析英文数字词：%s', s);
    end
end
