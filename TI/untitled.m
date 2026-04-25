subpath = '/Users/langqin/Desktop/test/m2m_Sub001';
output_folder = '/Users/langqin/Desktop/test/m2m_Sub001/TI';
currents = [0.002, -0.002];
electrode_centres = {{'F3','F4'}, {'TP7','TP8'}};
shape = 'ellipse';
dimensions = [10, 10];
thickness = 2;

TIS(subpath, output_folder, currents, electrode_centres, ...
                       shape, dimensions, thickness);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 定义参数
output_folder = '/Users/langqin/Desktop/test/m2m_Sub001/TI';
subpath = '/Users/langqin/Desktop/test/m2m_Sub001';
MNI_coords = [13.8, 1.3, 11.9];
radius = 10;

% 调用函数，获取数值结果
avg_TI = look_efield(output_folder, subpath, MNI_coords, radius);

% 在命令行输出所需信息（可自定义格式）
fprintf('MNI坐标: [%.1f, %.1f, %.1f] 内半径 %.0f mm 的ROI内平均电场大小为: %.4f V/m\n', MNI_coords(1), MNI_coords(2), MNI_coords(3),radius, avg_TI);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 查看模拟结果
% plot_TI_envelope(output_folder);