classdef charm < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        NIFITniiIMAIMALabel     matlab.ui.control.Label
        T1T2Label               matlab.ui.control.Label
        Label                   matlab.ui.control.Label
        Button_3                matlab.ui.control.Button
        Button_2                matlab.ui.control.Button
        T2EditField             matlab.ui.control.EditField
        T2EditFieldLabel        matlab.ui.control.Label
        T2CheckBox              matlab.ui.control.CheckBox
        Button                  matlab.ui.control.Button
        T1EditField             matlab.ui.control.EditField
        T1EditFieldLabel        matlab.ui.control.Label
        % 新增控件
        OutputEditFieldLabel    matlab.ui.control.Label
        OutputEditField         matlab.ui.control.EditField
        OutputButton            matlab.ui.control.Button
        SubjectEditFieldLabel   matlab.ui.control.Label
        SubjectEditField        matlab.ui.control.EditField
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            screenSize = get(groot, 'ScreenSize');
            figWidth = 500;   
            figHeight = 340;
            xPos = (screenSize(3) - figWidth) / 2;
            yPos = (screenSize(4) - figHeight) / 2;
            app.UIFigure.Position = [xPos, yPos, figWidth, figHeight];
            app.UIFigure.Name = '结构项分割';

            % Create T1EditFieldLabel
            app.T1EditFieldLabel = uilabel(app.UIFigure);
            app.T1EditFieldLabel.HorizontalAlignment = 'right';
            app.T1EditFieldLabel.Position = [10 300 67 22];
            app.T1EditFieldLabel.Text = 'T1文件路径';

            % Create T1EditField
            app.T1EditField = uieditfield(app.UIFigure, 'text');
            app.T1EditField.Position = [90 300 330 22];

            % Create Button (T1 browse)
            app.Button = uibutton(app.UIFigure, 'push');
            app.Button.Position = [430 300 29 23];
            app.Button.Text = '...';
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @T1BrowseButtonPushed, true);

            % Create T2CheckBox
            app.T2CheckBox = uicheckbox(app.UIFigure);
            app.T2CheckBox.Text = '是否需要T2文件';
            app.T2CheckBox.Position = [15 260 108 22];
            app.T2CheckBox.ValueChangedFcn = createCallbackFcn(app, @T2CheckBoxValueChanged, true);

            % Create T2EditFieldLabel
            app.T2EditFieldLabel = uilabel(app.UIFigure);
            app.T2EditFieldLabel.HorizontalAlignment = 'right';
            app.T2EditFieldLabel.Position = [5 230 74 22];
            app.T2EditFieldLabel.Text = 'T2文件路径';

            % Create T2EditField
            app.T2EditField = uieditfield(app.UIFigure, 'text');
            app.T2EditField.Position = [90 230 330 22];
            app.T2EditField.Enable = 'off';   % 初始禁用

            % Create Button_2 (T2 browse)
            app.Button_2 = uibutton(app.UIFigure, 'push');
            app.Button_2.Position = [430 230 29 23];
            app.Button_2.Text = '...';
            app.Button_2.Enable = 'off';
            app.Button_2.ButtonPushedFcn = createCallbackFcn(app, @T2BrowseButtonPushed, true);

            % Create OutputEditFieldLabel
            app.OutputEditFieldLabel = uilabel(app.UIFigure);
            app.OutputEditFieldLabel.HorizontalAlignment = 'right';
            app.OutputEditFieldLabel.Position = [10 195 67 22];
            app.OutputEditFieldLabel.Text = '输出路径';

            % Create OutputEditField
            app.OutputEditField = uieditfield(app.UIFigure, 'text');
            app.OutputEditField.Position = [90 195 330 22];

            % Create OutputButton
            app.OutputButton = uibutton(app.UIFigure, 'push');
            app.OutputButton.Position = [430 195 29 23];
            app.OutputButton.Text = '...';
            app.OutputButton.ButtonPushedFcn = createCallbackFcn(app, @OutputBrowseButtonPushed, true);

            % Create SubjectEditFieldLabel
            app.SubjectEditFieldLabel = uilabel(app.UIFigure);
            app.SubjectEditFieldLabel.HorizontalAlignment = 'right';
            app.SubjectEditFieldLabel.Position = [10 160 67 22];
            app.SubjectEditFieldLabel.Text = '被试编号';

            % Create SubjectEditField
            app.SubjectEditField = uieditfield(app.UIFigure, 'text');
            app.SubjectEditField.Position = [90 160 100 22];
            app.SubjectEditField.Value = 'Sub001';

            % Create Button_3 (Run)
            app.Button_3 = uibutton(app.UIFigure, 'push');
            app.Button_3.Position = [380 110 100 23];
            app.Button_3.Text = '开始运行';
            app.Button_3.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.Position = [15 110 250 22];
            app.Label.Text = '该步骤为对结构项目进行组织切割';

            % Create T1T2Label
            app.T1T2Label = uilabel(app.UIFigure);
            app.T1T2Label.Position = [16 70 250 22];
            app.T1T2Label.Text = 'T1像为必须提供，T2像不做要求';

            % Create NIFITniiIMAIMALabel
            app.NIFITniiIMAIMALabel = uilabel(app.UIFigure);
            app.NIFITniiIMAIMALabel.Position = [17 30 303 22];
            app.NIFITniiIMAIMALabel.Text = '结构项可为NIFIT格式(.nii)或包含IMA文件(.IMA)的文件夹';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = charm
            createComponents(app)
            registerApp(app, app.UIFigure)
            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            delete(app.UIFigure)
        end
    end

    % Callbacks
    methods (Access = private)

        % T1 浏览按钮回调
        function T1BrowseButtonPushed(app, ~)
            % 弹出选择对话框，询问用户要选择什么类型
            choice = uiconfirm(app.UIFigure, ...
                '请选择输入类型：', ... 
                'T1 输入选择', ...
                'Options', {'选择文件 (.nii/.nii.gz)', '选择文件夹 (DICOM/IMA)', '取消'}, ...
                'DefaultOption', 1, ...
                'CancelOption', 3);
        
            switch choice
                case '选择文件 (.nii/.nii.gz)'
                    [file, path] = uigetfile({'*.nii;*.nii.gz', 'NIfTI files (*.nii,*.nii.gz)'; ...
                                              '*.*', 'All Files (*.*)'}, ...
                                              '选择 T1 NIfTI 文件');
                    if isequal(file, 0)
                        return;
                    end
                    app.T1EditField.Value = fullfile(path, file);
        
                case '选择文件夹 (DICOM/IMA)'
                    selpath = uigetdir(pwd, '选择包含 DICOM/IMA 文件的文件夹');
                    if selpath ~= 0
                        app.T1EditField.Value = selpath;
                    end
        
                otherwise % 取消
                    return;
            end
            figure(app.UIFigure);
        end

        % T2 浏览按钮回调
        function T2BrowseButtonPushed(app, ~)
            % 弹出选择对话框，询问用户要选择什么类型
            choice = uiconfirm(app.UIFigure, ...
                '请选择输入类型：', ...
                'T1 输入选择', ...
                'Options', {'选择文件 (.nii/.nii.gz)', '选择文件夹 (DICOM/IMA)', '取消'}, ...
                'DefaultOption', 1, ...
                'CancelOption', 3);
        
            switch choice
                case '选择文件 (.nii/.nii.gz)'
                    [file, path] = uigetfile({'*.nii;*.nii.gz', 'NIfTI files (*.nii,*.nii.gz)'; ...
                                              '*.*', 'All Files (*.*)'}, ...
                                              '选择 T1 NIfTI 文件');
                    if isequal(file, 0)
                        return;
                    end
                    app.T1EditField.Value = fullfile(path, file);
        
                case '选择文件夹 (DICOM/IMA)'
                    selpath = uigetdir(pwd, '选择包含 DICOM/IMA 文件的文件夹');
                    if selpath ~= 0
                        app.T1EditField.Value = selpath;
                    end
        
                otherwise % 取消
                    return;
            end
            figure(app.UIFigure);
        end

        % 输出路径浏览按钮回调
        function OutputBrowseButtonPushed(app, ~)
            selpath = uigetdir(pwd, '选择输出文件夹');
            if selpath ~= 0
                app.OutputEditField.Value = selpath;
            end
            figure(app.UIFigure);
        end

        % T2 复选框值改变回调
        function T2CheckBoxValueChanged(app, ~)
            if app.T2CheckBox.Value
                app.T2EditField.Enable = 'on';
                app.Button_2.Enable = 'on';
            else
                app.T2EditField.Enable = 'off';
                app.Button_2.Enable = 'off';
                app.T2EditField.Value = '';
            end
        end

        % 开始运行按钮回调
        function RunButtonPushed(app, ~)
            % 输入验证
            t1Path = strtrim(app.T1EditField.Value);
            if isempty(t1Path)
                uialert(app.UIFigure, '请指定T1文件或文件夹路径。', '输入错误');
                return;
            end
            outputPath = strtrim(app.OutputEditField.Value);
            if isempty(outputPath)
                uialert(app.UIFigure, '请指定输出路径。', '输入错误');
                return;
            end
            if ~exist(outputPath, 'dir')
                uialert(app.UIFigure, '输出路径不存在，请先创建或选择有效文件夹。', '路径错误');
                return;
            end
            subjectID = strtrim(app.SubjectEditField.Value);
            if isempty(subjectID)
                subjectID = 'Sub001';
            end

            % 可选 T2 路径
            t2Path = '';
            if app.T2CheckBox.Value
                t2Path = strtrim(app.T2EditField.Value);
                % 这里可以后续扩展使用 T2
            end

            % 禁用运行按钮，防止重复点击
            app.Button_3.Enable = 'off';
            app.Button_3.Text = '运行中...';
            drawnow;

            try
                % 调用独立的功能函数
                run_charm_segmentation(t1Path, outputPath, subjectID, t2Path);
                uialert(app.UIFigure, 'CHARM 分割完成！', '成功', 'Icon','success');
            catch ME
                uialert(app.UIFigure, sprintf('运行出错：%s', ME.message), '错误');
            end

            % 恢复按钮
            app.Button_3.Enable = 'on';
            app.Button_3.Text = '开始运行';
        end
    end
end