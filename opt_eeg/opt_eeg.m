classdef opt_eeg < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure           matlab.ui.Figure
        start              matlab.ui.control.Button
        penalty_lambda     matlab.ui.control.NumericEditField
        Label_11           matlab.ui.control.Label
        target_strength    matlab.ui.control.NumericEditField
        VmEditFieldLabel   matlab.ui.control.Label
        W3                 matlab.ui.control.NumericEditField
        W3EditFieldLabel   matlab.ui.control.Label
        W2                 matlab.ui.control.NumericEditField
        W2EditFieldLabel   matlab.ui.control.Label
        W1                 matlab.ui.control.NumericEditField
        W1EditFieldLabel   matlab.ui.control.Label
        parallel_workers   matlab.ui.control.NumericEditField
        Label_10           matlab.ui.control.Label
        elite_size         matlab.ui.control.NumericEditField
        Label_9            matlab.ui.control.Label
        mutation_rate      matlab.ui.control.NumericEditField
        Label_8            matlab.ui.control.Label
        crossover_rate     matlab.ui.control.NumericEditField
        Label_7            matlab.ui.control.Label
        max_generations    matlab.ui.control.NumericEditField
        Label_6            matlab.ui.control.Label
        population_size    matlab.ui.control.NumericEditField
        Label_5            matlab.ui.control.Label
        electrode_pool     matlab.ui.control.EditField
        Label_4            matlab.ui.control.Label
        thickness          matlab.ui.control.NumericEditField
        mmLabel_2          matlab.ui.control.Label
        dimensions_short   matlab.ui.control.NumericEditField
        mmLabel            matlab.ui.control.Label
        dimensions_long    matlab.ui.control.NumericEditField
        mmEditFieldLabel   matlab.ui.control.Label
        shape              matlab.ui.control.DropDown
        Label_3            matlab.ui.control.Label
        currents           matlab.ui.control.NumericEditField
        ALabel             matlab.ui.control.Label
        roi_radius         matlab.ui.control.NumericEditField
        Label_2            matlab.ui.control.Label
        mni_targetZ        matlab.ui.control.EditField
        ZEditFieldLabel    matlab.ui.control.Label
        mni_targetY        matlab.ui.control.EditField
        YEditFieldLabel    matlab.ui.control.Label
        mni_targetX        matlab.ui.control.EditField
        XEditFieldLabel    matlab.ui.control.Label
        output_root        matlab.ui.control.EditField
        Label              matlab.ui.control.Label
        output_rootbutton  matlab.ui.control.Button
        m2m_folderbutton   matlab.ui.control.Button
        m2m_folder         matlab.ui.control.EditField
        m2mEditFieldLabel  matlab.ui.control.Label
        formulaLabel     matlab.ui.control.Label
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            screenSize = get(groot, 'ScreenSize');
            figWidth = 431;   
            figHeight = 480;
            xPos = (screenSize(3) - figWidth) / 2;
            yPos = (screenSize(4) - figHeight) / 2;
            app.UIFigure.Position = [xPos, yPos, figWidth, figHeight];
            app.UIFigure.Name = 'TI 电极优化';

            % Create m2mEditFieldLabel
            app.m2mEditFieldLabel = uilabel(app.UIFigure);
            app.m2mEditFieldLabel.HorizontalAlignment = 'right';
            app.m2mEditFieldLabel.Position = [11 439 70 22];
            app.m2mEditFieldLabel.Text = 'm2m文件夹';

            % Create m2m_folder
            app.m2m_folder = uieditfield(app.UIFigure, 'text');
            app.m2m_folder.Position = [101 439 270 22];

            % Create m2m_folderbutton
            app.m2m_folderbutton = uibutton(app.UIFigure, 'push');
            app.m2m_folderbutton.Position = [381 438 30 23];
            app.m2m_folderbutton.Text = '...';
            app.m2m_folderbutton.ButtonPushedFcn = @app.m2mFolderButtonPushed;

            % Create output_rootbutton
            app.output_rootbutton = uibutton(app.UIFigure, 'push');
            app.output_rootbutton.Position = [381 398 30 23];
            app.output_rootbutton.Text = '...';
            app.output_rootbutton.ButtonPushedFcn = @app.outputRootButtonPushed;

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [11 399 77 22];
            app.Label.Text = '结果输出位置';

            % Create output_root
            app.output_root = uieditfield(app.UIFigure, 'text');
            app.output_root.Position = [101 399 270 22];

            % Create XEditFieldLabel
            app.XEditFieldLabel = uilabel(app.UIFigure);
            app.XEditFieldLabel.HorizontalAlignment = 'right';
            app.XEditFieldLabel.Position = [11 359 77 22];
            app.XEditFieldLabel.Text = '靶区坐标     X';

            % Create mni_targetX
            app.mni_targetX = uieditfield(app.UIFigure, 'text');
            app.mni_targetX.Position = [91 359 30 22];

            % Create YEditFieldLabel
            app.YEditFieldLabel = uilabel(app.UIFigure);
            app.YEditFieldLabel.HorizontalAlignment = 'right';
            app.YEditFieldLabel.Position = [121 359 15 22];
            app.YEditFieldLabel.Text = 'Y';

            % Create mni_targetY
            app.mni_targetY = uieditfield(app.UIFigure, 'text');
            app.mni_targetY.Position = [141 359 30 22];

            % Create ZEditFieldLabel
            app.ZEditFieldLabel = uilabel(app.UIFigure);
            app.ZEditFieldLabel.HorizontalAlignment = 'right';
            app.ZEditFieldLabel.Position = [171 359 15 22];
            app.ZEditFieldLabel.Text = 'Z';

            % Create mni_targetZ
            app.mni_targetZ = uieditfield(app.UIFigure, 'text');
            app.mni_targetZ.Position = [191 359 30 22];

            % Create Label_2
            app.Label_2 = uilabel(app.UIFigure);
            app.Label_2.HorizontalAlignment = 'right';
            app.Label_2.Position = [227 359 49 22];
            app.Label_2.Text = 'ROI半径';

            % Create roi_radius
            app.roi_radius = uieditfield(app.UIFigure, 'numeric');
            app.roi_radius.Position = [281 359 30 22];
            app.roi_radius.Value = 10;

            % Create ALabel
            app.ALabel = uilabel(app.UIFigure);
            app.ALabel.HorizontalAlignment = 'right';
            app.ALabel.Position = [316 359 50 22];
            app.ALabel.Text = '电流±(A)';

            % Create currents
            app.currents = uieditfield(app.UIFigure, 'numeric');
            app.currents.Position = [371 359 40 22];
            app.currents.Value = 0.002;

            % Create Label_3
            app.Label_3 = uilabel(app.UIFigure);
            app.Label_3.HorizontalAlignment = 'right';
            app.Label_3.Position = [11 319 53 22];
            app.Label_3.Text = '电极形状';

            % Create shape
            app.shape = uidropdown(app.UIFigure);
            app.shape.Items = {'椭圆', '矩形'};               
            app.shape.ItemsData = {'ellipse', 'rect'}; 
            app.shape.Position = [71 319 70 22];
            app.shape.Value = 'ellipse';
            app.shape.ValueChangedFcn = @app.shapeValueChanged;

            % Create mmEditFieldLabel
            app.mmEditFieldLabel = uilabel(app.UIFigure);
            app.mmEditFieldLabel.HorizontalAlignment = 'right';
            app.mmEditFieldLabel.Position = [140 319 56 22];
            app.mmEditFieldLabel.Text = '长轴(mm)';

            % Create dimensions_long
            app.dimensions_long = uieditfield(app.UIFigure, 'numeric');
            app.dimensions_long.Position = [201 319 30 22];
            app.dimensions_long.Value = 15;

            % Create mmLabel
            app.mmLabel = uilabel(app.UIFigure);
            app.mmLabel.HorizontalAlignment = 'right';
            app.mmLabel.Position = [231 319 56 22];
            app.mmLabel.Text = '短轴(mm)';

            % Create dimensions_short
            app.dimensions_short = uieditfield(app.UIFigure, 'numeric');
            app.dimensions_short.Position = [292 319 30 22];
            app.dimensions_short.Value = 15;

            % Create mmLabel_2
            app.mmLabel_2 = uilabel(app.UIFigure);
            app.mmLabel_2.HorizontalAlignment = 'right';
            app.mmLabel_2.Position = [321 319 56 22];
            app.mmLabel_2.Text = '厚度(mm)';

            % Create thickness
            app.thickness = uieditfield(app.UIFigure, 'numeric');
            app.thickness.Position = [382 319 30 22];
            app.thickness.Value = 2;

            % Create Label_4
            app.Label_4 = uilabel(app.UIFigure);
            app.Label_4.HorizontalAlignment = 'right';
            app.Label_4.Position = [11 279 53 22];
            app.Label_4.Text = '电极点位';

            % Create electrode_pool
            app.electrode_pool = uieditfield(app.UIFigure, 'text');
            app.electrode_pool.Position = [69 279 342 22];
            app.electrode_pool.Value = '''Fp1'',''Fp2'',''Fz'',''F3'',''F4'',''F7'',''F8'',''Cz'',''C3'',''C4'',''T7'',''T8'',''Pz'',''P3'',''P4'',''P7'',''P8'',''O1'',''O2'',''Fpz'',''AFz'',''AF3'',''AF4'',''AF7'',''AF8'',''F1'',''F2'',''F5'',''F6'',''FCz'',''FC1'',''FC2'',''FC3'',''FC4'',''FC5'',''FC6'',''FT7'',''FT8'',''C1'',''C2'',''C5'',''C6'', ''CPz'',''CP1'',''CP2'',''CP3'',''CP4'',''CP5'',''CP6'',''TP7'',''TP8'',''P1'',''P2'',''P5'',''P6'',''POz'',''PO3'',''PO4'',''PO7'',''PO8'',''Oz''';

            % Create Label_5
            app.Label_5 = uilabel(app.UIFigure);
            app.Label_5.HorizontalAlignment = 'right';
            app.Label_5.Position = [11 239 77 22];
            app.Label_5.Text = '每代种群数量';

            % Create population_size
            app.population_size = uieditfield(app.UIFigure, 'numeric');
            app.population_size.Position = [91 239 30 22];
            app.population_size.Value = 50;

            % Create Label_6
            app.Label_6 = uilabel(app.UIFigure);
            app.Label_6.HorizontalAlignment = 'right';
            app.Label_6.Position = [121 239 77 22];
            app.Label_6.Text = '最大迭代次数';

            % Create max_generations
            app.max_generations = uieditfield(app.UIFigure, 'numeric');
            app.max_generations.Position = [201 239 30 22];
            app.max_generations.Value = 200;

            % Create Label_7
            app.Label_7 = uilabel(app.UIFigure);
            app.Label_7.HorizontalAlignment = 'right';
            app.Label_7.Position = [241 239 41 22];
            app.Label_7.Text = '交叉率';

            % Create crossover_rate
            app.crossover_rate = uieditfield(app.UIFigure, 'numeric');
            app.crossover_rate.Position = [291 239 30 22];
            app.crossover_rate.Value = 0.8;

            % Create Label_8
            app.Label_8 = uilabel(app.UIFigure);
            app.Label_8.HorizontalAlignment = 'right';
            app.Label_8.Position = [325 239 41 22];
            app.Label_8.Text = '突变率';

            % Create mutation_rate
            app.mutation_rate = uieditfield(app.UIFigure, 'numeric');
            app.mutation_rate.Position = [381 239 30 22];
            app.mutation_rate.Value = 0.1;

            % Create Label_9
            app.Label_9 = uilabel(app.UIFigure);
            app.Label_9.HorizontalAlignment = 'right';
            app.Label_9.Position = [11 199 65 22];
            app.Label_9.Text = '精英留存数';

            % Create elite_size
            app.elite_size = uieditfield(app.UIFigure, 'numeric');
            app.elite_size.Position = [91 199 30 22];
            app.elite_size.Value = 3;

            % Create Label_10
            app.Label_10 = uilabel(app.UIFigure);
            app.Label_10.HorizontalAlignment = 'right';
            app.Label_10.Position = [123 199 53 22];
            app.Label_10.Text = '并行线程';

            % Create parallel_workers
            app.parallel_workers = uieditfield(app.UIFigure, 'numeric');
            app.parallel_workers.Position = [181 199 30 22];
            app.parallel_workers.Value = 50;

            % Create W1EditFieldLabel
            app.W1EditFieldLabel = uilabel(app.UIFigure);
            app.W1EditFieldLabel.HorizontalAlignment = 'right';
            app.W1EditFieldLabel.Position = [211 199 25 22];
            app.W1EditFieldLabel.Text = 'W1';

            % Create W1
            app.W1 = uieditfield(app.UIFigure, 'numeric');
            app.W1.Position = [241 199 30 22];
            app.W1.Value = 1;

            % Create W2EditFieldLabel
            app.W2EditFieldLabel = uilabel(app.UIFigure);
            app.W2EditFieldLabel.HorizontalAlignment = 'right';
            app.W2EditFieldLabel.Position = [281 199 25 22];
            app.W2EditFieldLabel.Text = 'W2';

            % Create W2
            app.W2 = uieditfield(app.UIFigure, 'numeric');
            app.W2.Position = [311 199 30 22];
            app.W2.Value = 100;

            % Create W3EditFieldLabel
            app.W3EditFieldLabel = uilabel(app.UIFigure);
            app.W3EditFieldLabel.HorizontalAlignment = 'right';
            app.W3EditFieldLabel.Position = [351 199 25 22];
            app.W3EditFieldLabel.Text = 'W3';

            % Create W3
            app.W3 = uieditfield(app.UIFigure, 'numeric');
            app.W3.Position = [381 199 30 22];
            app.W3.Value = 0.5;

            % Create VmEditFieldLabel
            app.VmEditFieldLabel = uilabel(app.UIFigure);
            app.VmEditFieldLabel.HorizontalAlignment = 'right';
            app.VmEditFieldLabel.Position = [11 159 81 22];
            app.VmEditFieldLabel.Text = '靶区场强(V/m)';

            % Create target_strength
            app.target_strength = uieditfield(app.UIFigure, 'numeric');
            app.target_strength.Position = [101 159 30 22];
            app.target_strength.Value = 0.7;

            % Create Label_11
            app.Label_11 = uilabel(app.UIFigure);
            app.Label_11.HorizontalAlignment = 'right';
            app.Label_11.Position = [131 159 113 22];
            app.Label_11.Text = '未达到场强惩罚系数';

            % Create penalty_lambda
            app.penalty_lambda = uieditfield(app.UIFigure, 'numeric');
            app.penalty_lambda.Position = [251 159 30 22];
            app.penalty_lambda.Value = 100;

            % Create start
            app.start = uibutton(app.UIFigure, 'push');
            app.start.Position = [311 158 100 23];
            app.start.Text = '开始优化';
            app.start.ButtonPushedFcn = @app.startButtonPushed;

            % ---- 适应度公式显示（LaTeX 渲染，含分数） ----
            app.formulaLabel = uilabel(app.UIFigure);
            app.formulaLabel.Position = [11 10 410 100];   
            app.formulaLabel.Interpreter = 'latex';
            app.formulaLabel.Text = {
                '$F = W_1\cdot\frac{\mathrm{ROI}_{\mathrm{avg}}}{\mathrm{Whole}_{\mathrm{avg}}} + W_2\cdot\frac{\mathrm{FocusRatio}}{100} - W_3\cdot\frac{\mathrm{FocusVol}}{\mathrm{Whole}_{\mathrm{vol}}}$',
                '$\mathrm{Penalty} = \lambda\cdot\max(0,\;\mathrm{Target}-\mathrm{ROI}_{\mathrm{avg}})^2$',
                '$\mathrm{Fitness} = F - \mathrm{Penalty}$'
            };
            app.formulaLabel.FontSize = 13;
            app.formulaLabel.VerticalAlignment = 'top';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = opt_eeg

            % Create UIFigure and components
            createComponents(app)

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

    % Callback methods
    methods (Access = private)

        % Button pushed function: m2m_folderbutton
        function m2mFolderButtonPushed(app, ~, ~)
            folder = uigetdir(pwd, '选择 m2m 文件夹');
            if folder ~= 0
                app.m2m_folder.Value = folder;
            end
            figure(app.UIFigure);
        end

        % Button pushed function: output_rootbutton
        function outputRootButtonPushed(app, ~, ~)
            folder = uigetdir(pwd, '选择优化结果输出文件夹');
            if folder ~= 0
                app.output_root.Value = folder;
            end
            figure(app.UIFigure);
        end

        function shapeValueChanged(app, ~, ~)
            if strcmp(app.shape.Value, 'ellipse')
                app.mmEditFieldLabel.Text = '长轴(mm)';
                app.mmLabel.Text = '短轴(mm)';
            else
                app.mmEditFieldLabel.Text = '长(mm)';
                app.mmLabel.Text = '宽(mm)';
            end
        end
        
        % Button pushed function: start
        function startButtonPushed(app, ~, ~)
            % 检查必要输入
            if isempty(app.m2m_folder.Value)
                uialert(app.UIFigure, '请选择 m2m 文件夹', '输入错误');
                return;
            end
            if isempty(app.output_root.Value)
                uialert(app.UIFigure, '请选择输出文件夹', '输入错误');
                return;
            end

            % 禁用按钮，防止重复点击
            app.start.Enable = 'off';
            drawnow;

            % 读取并整理参数
            m2m_folder = app.m2m_folder.Value;
            output_root = app.output_root.Value;
            mni_target = [str2double(app.mni_targetX.Value), ...
                          str2double(app.mni_targetY.Value), ...
                          str2double(app.mni_targetZ.Value)];
            if any(isnan(mni_target))
                uialert(app.UIFigure, '靶区坐标必须为有效数值', '输入错误');
                app.start.Enable = 'on';
                return;
            end

            roi_radius = app.roi_radius.Value;
            current_amp = app.currents.Value;
            currents = [current_amp, -current_amp];   % ±电流
            shape = app.shape.Value;
            dimensions = [app.dimensions_long.Value, app.dimensions_short.Value];
            thickness = app.thickness.Value;

            % 解析电极池（原为 'Fp1','Fp2',... 格式）
            try
                electrode_pool = eval(['{' app.electrode_pool.Value '}']);
            catch
                uialert(app.UIFigure, '电极点位格式错误，请保持单引号逗号分隔', '输入错误');
                app.start.Enable = 'on';
                return;
            end

            population_size = app.population_size.Value;
            max_generations = app.max_generations.Value;
            crossover_rate = app.crossover_rate.Value;
            mutation_rate = app.mutation_rate.Value;
            elite_size = app.elite_size.Value;
            parallel_workers = app.parallel_workers.Value;
            w1 = app.W1.Value;
            w2 = app.W2.Value;
            w3 = app.W3.Value;
            target_strength = app.target_strength.Value;
            penalty_lambda = app.penalty_lambda.Value;

            % 启动优化（异步）
            try
                run_TI_optimization(m2m_folder, output_root, mni_target, ...
                    roi_radius, currents, shape, dimensions, thickness, ...
                    electrode_pool, population_size, max_generations, ...
                    crossover_rate, mutation_rate, elite_size, ...
                    parallel_workers, w1, w2, w3, target_strength, penalty_lambda);
                uialert(app.UIFigure, '优化完成，请查看输出文件夹。', '完成');
            catch ME
                uialert(app.UIFigure, ['优化出错: ' ME.message], '错误');
            end

            % 恢复按钮
            app.start.Enable = 'on';
        end
    end
end