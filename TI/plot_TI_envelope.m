function plot_TI_envelope(result_folder)
% plot_TI_envelope - 绘制TI包络电场在灰质表面的分布（基于SimNIBS网格）
%
% 输入：
%   result_folder - 字符串，存放仿真结果的文件夹路径（如 '/path/to/TI'）
%
% 功能：
%   1. 在指定文件夹中查找以 '_TIenvelope_only.msh' 结尾的网格文件
%   2. 加载网格，提取灰质区域（区域编号1002）的三角形面数据
%   3. 将电场幅值映射为面透明度（电场越强越不透明）
%   4. 绘制彩色三维表面，带颜色条和可交互光照

    %% 1. 检查输入文件夹
    if nargin < 1 || isempty(result_folder)
        error('请提供结果文件夹路径，例如：plot_TI_envelope(''/Users/langqin/software/simnibs-matlab/TI'')');
    end
    if ~isfolder(result_folder)
        error('文件夹不存在：%s', result_folder);
    end

    %% 2. 查找目标网格文件
    file_pattern = '*_TIenvelope_only.msh';
    files = dir(fullfile(result_folder, file_pattern));
    if isempty(files)
        error('在 %s 中未找到任何以 ''_TIenvelope_only.msh'' 结尾的文件', result_folder);
    end
    if length(files) > 1
        warning('找到多个匹配文件，将使用第一个：%s', files(1).name);
    end
    msh_file = fullfile(result_folder, files(1).name);
    fprintf('使用网格文件：%s\n', msh_file);

    %% 3. 加载网格
    fprintf('加载网格...\n');
    m = mesh_load_gmsh4(msh_file);

    %% 4. 提取灰质区域（triangle faces）
    region_idx = 1002;
    m_show = mesh_extract_regions(m, 'elemtype', 'tri', 'region_idx', region_idx);

    %% 5. 提取TI包络的三角形面数据（电场幅值）
    if isempty(m_show.element_data)
        error('网格中未找到元素数据（电场值）');
    end
    elem_data_struct = m_show.element_data{1};
    data = elem_data_struct.tridata(:);          % 每个三角形的电场值
    if length(data) ~= size(m_show.triangles, 1)
        error('数据长度 (%d) 与三角形面数 (%d) 不匹配', length(data), size(m_show.triangles,1));
    end

    %% 6. 透明度映射（电场零值→几乎透明，最大值→不透明）
    base_alpha = 0.01;      % 最小透明度（电场≈0）
    strong_alpha = 1.0;     % 最大透明度（电场取最大值时）
    data_max = max(data);    % 也可用 prctile(data,99.9) 压制极值影响
    if data_max <= 0
        error('电场最大值非正，无法进行透明度映射');
    end
    alpha_data = base_alpha + (strong_alpha - base_alpha) * (data / data_max);
    alpha_data = max(base_alpha, min(strong_alpha, alpha_data));  % 裁剪到 [base_alpha, strong_alpha]

    %% 7. 绘制表面
    figure;
    hp = patch('Faces', m_show.triangles, ...
               'Vertices', m_show.nodes, ...
               'FaceVertexCData', data, ...
               'FaceColor', 'flat', ...
               'EdgeColor', 'none', ...
               'FaceAlpha', 'flat', ...
               'FaceVertexAlphaData', alpha_data, ...
               'CDataMapping', 'scaled');

    %% 8. 颜色图、光照与交互设置
    colormap('jet');
    caxis([0, data_max]);
    colorbar;
    title(sprintf('TI envelope (max amplitude: %.3f V/m)', data_max), 'Interpreter', 'none');

    material(hp, 'dull');
    lighting gouraud;
    hlight = camlight('headlight');
    set(gca, 'UserData', hlight);

    % 旋转时更新光源方向，保持正面照明
    hrot = rotate3d;
    set(hrot, 'ActionPostCallback', @(~,~) camlight(get(gca,'UserData'), 'headlight'));

    axis equal;
    axis off;
    view(3);   % 设置三维视角

    fprintf('绘图完成。\n');
end