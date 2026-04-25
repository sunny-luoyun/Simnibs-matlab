classdef TI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        watch_result         matlab.ui.control.Button
        watch_efield         matlab.ui.control.Button
        radius               matlab.ui.control.EditField
        rEditFieldLabel      matlab.ui.control.Label
        MNI_coordsZ          matlab.ui.control.EditField
        ZEditFieldLabel      matlab.ui.control.Label
        MNI_coordsY          matlab.ui.control.EditField
        YEditFieldLabel      matlab.ui.control.Label
        MNI_coordsX          matlab.ui.control.EditField
        ROIXLabel            matlab.ui.control.Label
        Label_7              matlab.ui.control.Label
        TILabel              matlab.ui.control.Label
        start_stimulate      matlab.ui.control.Button
        thickness            matlab.ui.control.NumericEditField
        mmLabel_3            matlab.ui.control.Label
        dimensions_short     matlab.ui.control.NumericEditField
        mmLabel_2            matlab.ui.control.Label
        dimensions_long      matlab.ui.control.NumericEditField
        mmLabel              matlab.ui.control.Label
        shape                matlab.ui.control.DropDown
        Label_5              matlab.ui.control.Label
        Label_4              matlab.ui.control.Label
        electrode_centres22  matlab.ui.control.DropDown
        Label_3              matlab.ui.control.Label
        electrode_centres21  matlab.ui.control.DropDown
        Label_2              matlab.ui.control.Label
        electrode_centres12  matlab.ui.control.DropDown
        Button_4             matlab.ui.control.Button
        Button_3             matlab.ui.control.Button
        electrode_centres11  matlab.ui.control.DropDown
        Label                matlab.ui.control.Label
        currents             matlab.ui.control.NumericEditField
        AEditFieldLabel      matlab.ui.control.Label
        output_folder        matlab.ui.control.EditField
        Label_6              matlab.ui.control.Label
        subpath              matlab.ui.control.EditField
        m2mEditFieldLabel    matlab.ui.control.Label
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            screenSize = get(groot, 'ScreenSize');
            figWidth = 525;   
            figHeight = 280;
            xPos = (screenSize(3) - figWidth) / 2;
            yPos = (screenSize(4) - figHeight) / 2;
            app.UIFigure.Position = [xPos, yPos, figWidth, figHeight];
            app.UIFigure.Name = 'TI模拟';

            % Create m2mEditFieldLabel
            app.m2mEditFieldLabel = uilabel(app.UIFigure);
            app.m2mEditFieldLabel.HorizontalAlignment = 'right';
            app.m2mEditFieldLabel.Position = [31 219 80 22];
            app.m2mEditFieldLabel.Text = 'm2m文件路径';

            % Create subpath
            app.subpath = uieditfield(app.UIFigure, 'text');
            app.subpath.Position = [151 219 301 22];
            app.subpath.ValueChangedFcn = createCallbackFcn(app, @subpathChangedCallback, true);

            % Create Label_6
            app.Label_6 = uilabel(app.UIFigure);
            app.Label_6.HorizontalAlignment = 'right';
            app.Label_6.Position = [30 189 101 22];
            app.Label_6.Text = '模拟文件输出路径';

            % Create output_folder
            app.output_folder = uieditfield(app.UIFigure, 'text');
            app.output_folder.Position = [150 189 302 22];

            % Create AEditFieldLabel
            app.AEditFieldLabel = uilabel(app.UIFigure);
            app.AEditFieldLabel.HorizontalAlignment = 'right';
            app.AEditFieldLabel.Position = [30 159 67 22];
            app.AEditFieldLabel.Text = '电流大小(A)';

            % Create currents
            app.currents = uieditfield(app.UIFigure, 'numeric');
            app.currents.Position = [99 159 40 22];
            app.currents.Value = 0.002;

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [30 129 66 22];
            app.Label.Text = '通道1电极1';

            % Create electrode_centres11
            app.electrode_centres11 = uidropdown(app.UIFigure);
            app.electrode_centres11.Items = {'Fp1', 'Fp2', 'Fz', 'F3', 'F4', 'F7', 'F8', 'Cz', 'C3', 'C4', 'T7', 'T8', 'Pz', 'P3', 'P4', 'P7', 'P8', 'O1', 'O2', 'Fpz', 'AFz', 'AF3', 'AF4', 'AF7', 'AF8', 'F1', 'F2', 'F5', 'F6', 'FCz', 'FC1', 'FC2', 'FC3', 'FC4', 'FC5', 'FC6', 'FT7', 'FT8', 'C1', 'C2', 'C5', 'C6', 'CPz', 'CP1', 'CP2', 'CP3', 'CP4', 'CP5', 'CP6', 'TP7', 'TP8', 'P1', 'P2', 'P5', 'P6', 'POz', 'PO3', 'PO4', 'PO7', 'PO8', 'Oz'};
            app.electrode_centres11.Position = [100 129 60 22];
            app.electrode_centres11.Value = 'Fp1';

            % Create Button_3
            app.Button_3 = uibutton(app.UIFigure, 'push');
            app.Button_3.Position = [460 218 30 23];
            app.Button_3.Text = '...';

            % Create Button_4
            app.Button_4 = uibutton(app.UIFigure, 'push');
            app.Button_4.Position = [460 188 30 23];
            app.Button_4.Text = '...';

            % Create electrode_centres12
            app.electrode_centres12 = uidropdown(app.UIFigure);
            app.electrode_centres12.Items = {'Fp1', 'Fp2', 'Fz', 'F3', 'F4', 'F7', 'F8', 'Cz', 'C3', 'C4', 'T7', 'T8', 'Pz', 'P3', 'P4', 'P7', 'P8', 'O1', 'O2', 'Fpz', 'AFz', 'AF3', 'AF4', 'AF7', 'AF8', 'F1', 'F2', 'F5', 'F6', 'FCz', 'FC1', 'FC2', 'FC3', 'FC4', 'FC5', 'FC6', 'FT7', 'FT8', 'C1', 'C2', 'C5', 'C6', 'CPz', 'CP1', 'CP2', 'CP3', 'CP4', 'CP5', 'CP6', 'TP7', 'TP8', 'P1', 'P2', 'P5', 'P6', 'POz', 'PO3', 'PO4', 'PO7', 'PO8', 'Oz'};
            app.electrode_centres12.Position = [240 129 60 22];
            app.electrode_centres12.Value = 'Fp1';

            % Create Label_2
            app.Label_2 = uilabel(app.UIFigure);
            app.Label_2.HorizontalAlignment = 'right';
            app.Label_2.Position = [170 129 66 22];
            app.Label_2.Text = '通道1电极2';

            % Create electrode_centres21
            app.electrode_centres21 = uidropdown(app.UIFigure);
            app.electrode_centres21.Items = {'Fp1', 'Fp2', 'Fz', 'F3', 'F4', 'F7', 'F8', 'Cz', 'C3', 'C4', 'T7', 'T8', 'Pz', 'P3', 'P4', 'P7', 'P8', 'O1', 'O2', 'Fpz', 'AFz', 'AF3', 'AF4', 'AF7', 'AF8', 'F1', 'F2', 'F5', 'F6', 'FCz', 'FC1', 'FC2', 'FC3', 'FC4', 'FC5', 'FC6', 'FT7', 'FT8', 'C1', 'C2', 'C5', 'C6', 'CPz', 'CP1', 'CP2', 'CP3', 'CP4', 'CP5', 'CP6', 'TP7', 'TP8', 'P1', 'P2', 'P5', 'P6', 'POz', 'PO3', 'PO4', 'PO7', 'PO8', 'Oz'};
            app.electrode_centres21.Position = [100 99 60 22];
            app.electrode_centres21.Value = 'Fp1';

            % Create Label_3
            app.Label_3 = uilabel(app.UIFigure);
            app.Label_3.HorizontalAlignment = 'right';
            app.Label_3.Position = [30 99 66 22];
            app.Label_3.Text = '通道2电极1';

            % Create electrode_centres22
            app.electrode_centres22 = uidropdown(app.UIFigure);
            app.electrode_centres22.Items = {'Fp1', 'Fp2', 'Fz', 'F3', 'F4', 'F7', 'F8', 'Cz', 'C3', 'C4', 'T7', 'T8', 'Pz', 'P3', 'P4', 'P7', 'P8', 'O1', 'O2', 'Fpz', 'AFz', 'AF3', 'AF4', 'AF7', 'AF8', 'F1', 'F2', 'F5', 'F6', 'FCz', 'FC1', 'FC2', 'FC3', 'FC4', 'FC5', 'FC6', 'FT7', 'FT8', 'C1', 'C2', 'C5', 'C6', 'CPz', 'CP1', 'CP2', 'CP3', 'CP4', 'CP5', 'CP6', 'TP7', 'TP8', 'P1', 'P2', 'P5', 'P6', 'POz', 'PO3', 'PO4', 'PO7', 'PO8', 'Oz'};
            app.electrode_centres22.Position = [240 99 60 22];
            app.electrode_centres22.Value = 'Fp1';

            % Create Label_4
            app.Label_4 = uilabel(app.UIFigure);
            app.Label_4.HorizontalAlignment = 'right';
            app.Label_4.Position = [170 99 66 22];
            app.Label_4.Text = '通道2电极2';

            % Create Label_5
            app.Label_5 = uilabel(app.UIFigure);
            app.Label_5.HorizontalAlignment = 'right';
            app.Label_5.Position = [170 159 53 22];
            app.Label_5.Text = '电极形状';

            % --- 修改开始：形状下拉选项改为中文，默认值“椭圆” ---
            app.shape = uidropdown(app.UIFigure);
            app.shape.Items = {'椭圆', '矩形'};          % 原为 {'ellipse', 'rect'}
            app.shape.Position = [238 159 69 22];
            app.shape.Value = '椭圆';                   % 原为 'ellipse'

            % 形状切换回调（动态更改标签文本）
            app.shape.ValueChangedFcn = createCallbackFcn(app, @shapeChangedCallback, true);
            % --- 修改结束 ---

            % 尺寸标签（宽度稍增大以容纳中文字符）
            app.mmLabel = uilabel(app.UIFigure);
            app.mmLabel.HorizontalAlignment = 'right';
            app.mmLabel.Position = [310 159 60 22];   % 原宽度56
            app.mmLabel.Text = '长轴(mm)';            % 初始显示椭圆的标签

            % Create dimensions_long
            app.dimensions_long = uieditfield(app.UIFigure, 'numeric');
            app.dimensions_long.Position = [370 159 30 22];
            app.dimensions_long.Value = 15;

            % Create mmLabel_2
            app.mmLabel_2 = uilabel(app.UIFigure);
            app.mmLabel_2.HorizontalAlignment = 'right';
            app.mmLabel_2.Position = [400 159 60 22];  % 原宽度56
            app.mmLabel_2.Text = '短轴(mm)';          % 初始显示椭圆的标签

            % Create dimensions_short
            app.dimensions_short = uieditfield(app.UIFigure, 'numeric');
            app.dimensions_short.Position = [460 159 30 22];
            app.dimensions_short.Value = 15;

            % Create mmLabel_3
            app.mmLabel_3 = uilabel(app.UIFigure);
            app.mmLabel_3.HorizontalAlignment = 'right';
            app.mmLabel_3.Position = [310 129 80 22];
            app.mmLabel_3.Text = '电极厚度(mm)';

            % Create thickness
            app.thickness = uieditfield(app.UIFigure, 'numeric');
            app.thickness.Position = [400 129 20 22];
            app.thickness.Value = 2;

            % Create start_stimulate
            app.start_stimulate = uibutton(app.UIFigure, 'push');
            app.start_stimulate.Position = [312 98 79 23];
            app.start_stimulate.Text = '开始模拟';

            % Create TILabel
            app.TILabel = uilabel(app.UIFigure);
            app.TILabel.Position = [21 249 111 22];
            app.TILabel.Text = '模拟TI刺激参数设置';

            % Create Label_7
            app.Label_7 = uilabel(app.UIFigure);
            app.Label_7.Position = [21 59 101 22];
            app.Label_7.Text = '模拟结果电场查询';

            % Create ROIXLabel
            app.ROIXLabel = uilabel(app.UIFigure);
            app.ROIXLabel.HorizontalAlignment = 'right';
            app.ROIXLabel.Position = [31 29 91 22];
            app.ROIXLabel.Text = '定义ROI坐标   X';

            % Create MNI_coordsX
            app.MNI_coordsX = uieditfield(app.UIFigure, 'text');
            app.MNI_coordsX.Position = [131 29 30 22];

            % Create YEditFieldLabel
            app.YEditFieldLabel = uilabel(app.UIFigure);
            app.YEditFieldLabel.HorizontalAlignment = 'right';
            app.YEditFieldLabel.Position = [171 29 10 22];
            app.YEditFieldLabel.Text = 'Y';

            % Create MNI_coordsY
            app.MNI_coordsY = uieditfield(app.UIFigure, 'text');
            app.MNI_coordsY.Position = [191 29 30 22];

            % Create ZEditFieldLabel
            app.ZEditFieldLabel = uilabel(app.UIFigure);
            app.ZEditFieldLabel.HorizontalAlignment = 'right';
            app.ZEditFieldLabel.Position = [216 29 25 22];
            app.ZEditFieldLabel.Text = 'Z';

            % Create MNI_coordsZ
            app.MNI_coordsZ = uieditfield(app.UIFigure, 'text');
            app.MNI_coordsZ.Position = [251 29 30 22];

            % Create rEditFieldLabel
            app.rEditFieldLabel = uilabel(app.UIFigure);
            app.rEditFieldLabel.HorizontalAlignment = 'right';
            app.rEditFieldLabel.Position = [291 29 91 22];
            app.rEditFieldLabel.Text = '定义小球大小   r';

            % Create radius
            app.radius = uieditfield(app.UIFigure, 'text');
            app.radius.Position = [391 29 30 22];

            % Create watch_efield
            app.watch_efield = uibutton(app.UIFigure, 'push');
            app.watch_efield.Position = [431 28 60 23];
            app.watch_efield.Text = '查询';

            % Create watch_result
            app.watch_result = uibutton(app.UIFigure, 'push');
            app.watch_result.Position = [401 98 90 23];
            app.watch_result.Text = '查看结果';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % Callback methods
    methods (Access = private)

        % --- 新增回调：根据形状切换尺寸标签 ---
        function shapeChangedCallback(app, ~, ~)
            switch app.shape.Value
                case '椭圆'
                    app.mmLabel.Text = '长轴(mm)';
                    app.mmLabel_2.Text = '短轴(mm)';
                case '矩形'
                    app.mmLabel.Text = '长(mm)';
                    app.mmLabel_2.Text = '宽(mm)';
            end
        end

        % Button_3 callback: browse for m2m folder
        function browseM2MCallback(app, ~, ~)
            folder = uigetdir('', '选择 m2m 文件夹');
            if ~isequal(folder, 0)
                app.subpath.Value = folder;
                subpathChangedCallback(app, [], []);
            end
            figure(app.UIFigure);
        end

        % Button_4 callback: browse for output folder
        function browseOutputCallback(app, ~, ~)
            folder = uigetdir('', '选择输出文件夹');
            if ~isequal(folder, 0)
                app.output_folder.Value = folder;
            end
            figure(app.UIFigure);
        end

        % start_stimulate callback: run TI simulation
        function startStimulateCallback(app, ~, ~)
            % Collect parameters
            subpath = app.subpath.Value;
            output_folder = app.output_folder.Value;
            current_val = app.currents.Value;
            currents = [current_val, -current_val];   % construct bipolar pair
            
            % Electrode centers: { {ch1_elec1, ch1_elec2}, {ch2_elec1, ch2_elec2} }
            electrode_centres = { {app.electrode_centres11.Value, app.electrode_centres12.Value}, ...
                                  {app.electrode_centres21.Value, app.electrode_centres22.Value} };
            
            % --- 修改开始：将中文形状映射为英文参数 ---
            if strcmp(app.shape.Value, '椭圆')
                shape_eng = 'ellipse';
            else
                shape_eng = 'rect';
            end
            % --- 修改结束 ---

            dimensions = [app.dimensions_long.Value, app.dimensions_short.Value];
            thickness = app.thickness.Value;
            
            % Input validation
            if isempty(subpath) || ~isfolder(subpath)
                uialert(app.UIFigure, '请选择有效的 m2m 文件夹路径。', '路径错误');
                return;
            end
            if isempty(output_folder)
                uialert(app.UIFigure, '请指定模拟文件输出路径。', '路径缺失');
                return;
            end
            if any(dimensions <= 0) || thickness <= 0
                uialert(app.UIFigure, '电极尺寸和厚度必须为正数。', '参数错误');
                return;
            end
            
            % Create output folder if not exist
            if ~isfolder(output_folder)
                mkdir(output_folder);
            end

            % --- 新增检查：输出文件夹是否非空 ---
            contents = dir(fullfile(output_folder, '*'));
            % 排除 '.' 和 '..'
            contents = contents(~ismember({contents.name}, {'.', '..'}));
            if ~isempty(contents)
                uialert(app.UIFigure, '输出文件夹非空，请删除现有内容或选择其他文件夹。', '文件夹不为空');
                return;   % 直接退出，不执行模拟
            end
            % --- 检查结束 ---
            
            % Disable button during simulation to prevent multiple clicks
            app.start_stimulate.Enable = 'off';
            drawnow;
            
            % Run TIS simulation (使用转换后的英文形状参数)
            try
                TIS(subpath, output_folder, currents, electrode_centres, ...
                    shape_eng, dimensions, thickness);
                uialert(app.UIFigure, '模拟完成！', '成功');
            catch ME
                uialert(app.UIFigure, ['模拟出错：' ME.message], '错误');
            end
            
            % Re-enable button
            app.start_stimulate.Enable = 'on';
        end

        % watch_result callback: plot TI envelope
        function watchResultCallback(app, ~, ~)
            output_folder = app.output_folder.Value;
            if isempty(output_folder) || ~isfolder(output_folder)
                uialert(app.UIFigure, '请先指定输出文件夹，或确保模拟已运行。', '文件夹无效');
                return;
            end
            figure(app.UIFigure);
            try
                plot_TI_envelope(output_folder);
            catch ME
                uialert(app.UIFigure, ['无法显示结果：' ME.message], '错误');
            end
            figure(app.UIFigure);
        end

        % watch_efield callback: query average field in ROI
        function watchEfieldCallback(app, ~, ~)
            % 获取 ROI 坐标
            x_str = app.MNI_coordsX.Value;
            y_str = app.MNI_coordsY.Value;
            z_str = app.MNI_coordsZ.Value;
            if isempty(x_str) || isempty(y_str) || isempty(z_str)
                uialert(app.UIFigure, '请输入完整的 MNI 坐标 (X, Y, Z)。', '坐标缺失');
                return;
            end
            MNI_coords = [str2double(x_str), str2double(y_str), str2double(z_str)];
            if any(isnan(MNI_coords))
                uialert(app.UIFigure, 'MNI 坐标必须为数值。', '格式错误');
                return;
            end
        
            radius_str = app.radius.Value;
            if isempty(radius_str)
                uialert(app.UIFigure, '请输入 ROI 半径 (r)。', '半径缺失');
                return;
            end
            radius = str2double(radius_str);
            if isnan(radius) || radius <= 0
                uialert(app.UIFigure, '半径必须为正数。', '参数错误');
                return;
            end
        
            output_folder = app.output_folder.Value;
            subpath = app.subpath.Value;
            if isempty(output_folder) || ~isfolder(output_folder)
                uialert(app.UIFigure, '输出文件夹无效，请先运行模拟。', '文件夹错误');
                return;
            end
            if isempty(subpath) || ~isfolder(subpath)
                uialert(app.UIFigure, 'm2m 文件夹无效，无法查询电场。', '路径错误');
                return;
            end
        
            try
                % ----- 调用增强后的 look_efield，返回完整结果结构体 -----
                result = look_efield(output_folder, subpath, MNI_coords, radius);
        
                % ----- 将所有信息打印到命令行窗口 -----
                fprintf('\n========== TI 包络电场查询结果 ==========\n');
                fprintf('被试: %s\n', result.info.subject);
                fprintf('MNI 坐标: [%.1f, %.1f, %.1f]\n', result.info.MNI_coords);
                fprintf('被试空间坐标: [%.2f, %.2f, %.2f]\n', result.info.subject_coords);
                fprintf('ROI 半径: %.0f mm\n', result.info.radius_mm);
                fprintf('场值名称: %s\n', result.info.field_name);
                fprintf('----------------------------------------\n');
        
                % --- ROI 内统计 ---
                if ~isnan(result.roi.avg)
                    fprintf('ROI 内灰质单元数: %d\n', result.roi.num_elements);
                    fprintf('ROI 体积: %.2f mm³\n', result.roi.volume);
                    fprintf('ROI 内电场平均值 (体积加权): %.4f V/m\n', result.roi.avg);
                    fprintf('ROI 内标准差 (体积加权): %.4f V/m\n', result.roi.std);
                    fprintf('ROI 内中位数: %.4f V/m\n', result.roi.median);
                    fprintf('ROI 内最小值: %.4f V/m\n', result.roi.min);
                    fprintf('ROI 内最大值: %.4f V/m\n', result.roi.max);
                else
                    fprintf('ROI 内无有效单元，请检查坐标或半径。\n');
                end
        
                % --- ROI 外（灰质其余部分）统计 ---
                if ~isnan(result.non_roi.avg)
                    fprintf('\n--- ROI 外（灰质其余部分） ---\n');
                    fprintf('单元数: %d\n', result.non_roi.num_elements);
                    fprintf('体积: %.2f mm³\n', result.non_roi.volume);
                    fprintf('平均值 (体积加权): %.4f V/m\n', result.non_roi.avg);
                    fprintf('标准差 (体积加权): %.4f V/m\n', result.non_roi.std);
                    fprintf('中位数: %.4f V/m\n', result.non_roi.median);
                    fprintf('最小值: %.4f V/m\n', result.non_roi.min);
                    fprintf('最大值: %.4f V/m\n', result.non_roi.max);
                else
                    fprintf('ROI 外无灰质单元（ROI 覆盖整个灰质？）\n');
                end
        
                % --- 全脑灰质统计 ---
                fprintf('\n--- 全脑灰质 ---\n');
                fprintf('总单元数: %d\n', length(result.gm_field));
                fprintf('总体积: %.2f mm³\n', result.whole_gm.volume);
                fprintf('平均值 (体积加权): %.4f V/m\n', result.whole_gm.avg);
                fprintf('标准差 (体积加权): %.4f V/m\n', result.whole_gm.std);
                fprintf('中位数: %.4f V/m\n', result.whole_gm.median);
                fprintf('最小值: %.4f V/m\n', result.whole_gm.min);
                fprintf('最大值: %.4f V/m\n', result.whole_gm.max);
        
                % --- 新增：峰值电场信息 ---
                fprintf('\n--- 全脑灰质峰值电场 ---\n');
                fprintf('峰值强度: %.4f V/m\n', result.peak.value);
                fprintf('峰值空间坐标 (被试空间): [%.2f, %.2f, %.2f] mm\n', ...
                        result.peak.subject_coord(1), result.peak.subject_coord(2), result.peak.subject_coord(3));
                fprintf('峰值 MNI 坐标: [%.2f, %.2f, %.2f] mm\n', ...
                        result.peak.mni_coord(1), result.peak.mni_coord(2), result.peak.mni_coord(3));
        
                % --- 新增：调制深度与半峰全宽聚焦体积 ---
                fprintf('\n--- 调制深度与聚焦评价指标 ---\n');
                if ~isnan(result.modulation.depth)
                    fprintf('调制深度 (ROI内最大-最小)/平均: %.4f\n', result.modulation.depth);
                else
                    fprintf('调制深度: 无法计算 (ROI 内平均电场为0或无效)\n');
                end
                fprintf('半峰全宽 (FWHM) 阈值: %.4f V/m\n', result.modulation.fwhm_threshold);
                fprintf('超阈值聚焦总体积 (全脑灰质): %.2f mm³\n', result.modulation.focus_volume_total_mm3);
                fprintf('其中位于 ROI 内的聚焦体积: %.2f mm³\n', result.modulation.focus_volume_roi_mm3);
                if ~isnan(result.modulation.focus_ratio)
                    fprintf('靶区聚焦占比 (ROI内聚焦体积/总体积): %.2f %%\n', result.modulation.focus_ratio * 100);
                else
                    fprintf('靶区聚焦占比: 无法计算\n');
                end
                if ~isnan(result.modulation.depth_over_focus_volume)
                    fprintf('综合指标 (调制深度 / 聚焦总体积): %.6f\n', result.modulation.depth_over_focus_volume);
                else
                    fprintf('综合指标: 无法计算\n');
                end
        
                % --- 可选增强比 ---
                if ~isnan(result.roi.avg) && ~isnan(result.whole_gm.avg) && result.whole_gm.avg ~= 0
                    enhancement = result.roi.avg / result.whole_gm.avg;
                    fprintf('\n>>> ROI 增强比 (ROI_avg / 全脑灰质_avg): %.2f\n', enhancement);
                end
        
                fprintf('========================================\n\n');
        
            catch ME
                uialert(app.UIFigure, ['查询失败：' ME.message], '错误');
            end
        end

        function subpathChangedCallback(app, ~, ~)
            m2mPath = app.subpath.Value;
            % 仅当 m2m 路径存在时执行
            if ~isempty(m2mPath) && isfolder(m2mPath)
                TIS_folder = fullfile(m2mPath, 'TIS');
                app.output_folder.Value = TIS_folder;
                % 如果希望同步创建该文件夹（可选）
                if ~isfolder(TIS_folder)
                    mkdir(TIS_folder);
                end
            end
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = TI

            % Create UIFigure and components
            createComponents(app)

            % Assign callbacks
            app.Button_3.ButtonPushedFcn = createCallbackFcn(app, @browseM2MCallback, true);
            app.Button_4.ButtonPushedFcn = createCallbackFcn(app, @browseOutputCallback, true);
            app.start_stimulate.ButtonPushedFcn = createCallbackFcn(app, @startStimulateCallback, true);
            app.watch_result.ButtonPushedFcn = createCallbackFcn(app, @watchResultCallback, true);
            app.watch_efield.ButtonPushedFcn = createCallbackFcn(app, @watchEfieldCallback, true);

            % --- 确保标签根据默认形状初始化 ---
            shapeChangedCallback(app, [], []);

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end