classdef simnibs < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure      matlab.ui.Figure
        TIopt_eeg     matlab.ui.control.Button
        TIopt_lf      matlab.ui.control.Button
        TIstimulate   matlab.ui.control.Button
        charmButton   matlab.ui.control.Button
        SimNIBSLabel  matlab.ui.control.Label
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: charmButton
        function charmButtonPushed(app, event)
            addpath(fullfile(fileparts(mfilename('fullpath')), 'charm'));
            rehash;
            charm();
        end

        % Button pushed function: TIstimulate
        function TIstimulatePushed(app, event)
            addpath(fullfile(fileparts(mfilename('fullpath')), 'TI'));
            rehash;
            TI();
        end

        % Button pushed function: TIopt_eeg
        function TIopt_eegPushed(app, event)
            addpath(fullfile(fileparts(mfilename('fullpath')), 'opt_eeg'));
            rehash;
            opt_eeg();
        end

        % Button pushed function: TIopt_lf
        function TIopt_lfPushed(app, event)
            addpath(fullfile(fileparts(mfilename('fullpath')), 'opt_ti_lf'));
            rehash;
            opt_ti_lf();
        end

    end

    % Update check
    methods (Access = private)

        function checkForUpdate(app)
            appDir = fileparts(mfilename('fullpath'));
            localSHA = getLocalVersion(app, appDir);
            if isempty(localSHA)
                return;
            end
            remoteSHA = getRemoteVersion(app);
            if isempty(remoteSHA)
                return;
            end
            if ~strcmp(localSHA, remoteSHA)
                showUpdateDialog(app, localSHA(1:7), remoteSHA(1:7), appDir);
            end
        end

        function localSHA = getLocalVersion(~, appDir)
            [status, result] = system(['git -C "', appDir, '" rev-parse HEAD 2>/dev/null']);
            if status == 0
                localSHA = strtrim(result);
                return;
            end
            try
                localSHA = strtrim(fileread(fullfile(appDir, 'version.txt')));
            catch
                localSHA = '';
            end
        end

        function remoteSHA = getRemoteVersion(~)
            try
                url = 'https://gitee.com/api/v5/repos/luoyun-weixi/simnibs-matlab/commits/main';
                opts = weboptions('Timeout', 5);
                data = webread(url, opts);
                remoteSHA = data.sha;
            catch
                remoteSHA = '';
            end
        end

        function showUpdateDialog(app, localVer, remoteVer, appDir)
            dlg = uifigure('Name', '检查更新');
            dlg.Position = [100 100 420 180];
            dlg.WindowStyle = 'modal';
            movegui(dlg, 'center');

            msg = sprintf('发现新版本！\n当前版本(commit): %s\n最新版本(commit): %s\n\n请选择操作:', localVer, remoteVer);
            uilabel(dlg, 'Text', msg, ...
                'Position', [20 80 380 80], 'FontSize', 12, ...
                'HorizontalAlignment', 'left');

            uibutton(dlg, 'push', 'Text', '忽略', ...
                'Position', [90 20 100 30], ...
                'ButtonPushedFcn', @(btn,~) delete(dlg));

            uibutton(dlg, 'push', 'Text', '更新', ...
                'Position', [230 20 100 30], ...
                'ButtonPushedFcn', @(btn,~) doUpdate(app, dlg, appDir));
        end

        function doUpdate(app, dlg, appDir)
            fprintf('正在检查更新...\n');
            if gitUpdate(app, appDir)
                fprintf('更新成功，重启应用...\n');
                restartApp(app, dlg);
            else
                fprintf('更新失败，请检查网络连接后重试。\n');
                uialert(dlg, '更新失败，请检查网络连接后重试。', '错误', 'Icon', 'error');
            end
        end

        function success = gitUpdate(~, appDir)
            try
                gitUrl = 'https://gitee.com/luoyun-weixi/simnibs-matlab.git';
                tempDir = tempname;
                fprintf('正在下载更新包...\n');
                [status, result] = system(['git clone --depth 1 "', gitUrl, '" "', tempDir, '" 2>&1']);
                if status ~= 0
                    error('git clone 失败: %s', strtrim(result));
                end
                fprintf('下载完成，正在复制文件...\n');
                copyfile(fullfile(tempDir, '*'), appDir, 'f');
                rmdir(tempDir, 's');
                success = true;
            catch ME
                fprintf('更新失败: %s\n', ME.message);
                success = false;
            end
        end

        function restartApp(app, dlg)
            delete(dlg);
            delete(app);
            clear simnibs;
            simnibs;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            % 获取屏幕尺寸（单位为像素）
            screenSize = get(groot, 'ScreenSize');
            figWidth = 230;   % 窗口宽度
            figHeight = 340;  % 窗口高度
            % 计算左上角坐标使窗口居中
            xPos = (screenSize(3) - figWidth) / 2;
            yPos = (screenSize(4) - figHeight) / 2;
            app.UIFigure.Position = [xPos, yPos, figWidth, figHeight];
            app.UIFigure.Name = 'SimNIBS';

            % Create SimNIBSLabel
            app.SimNIBSLabel = uilabel(app.UIFigure);
            app.SimNIBSLabel.BackgroundColor = [0.902 0.902 0.902];
            app.SimNIBSLabel.HorizontalAlignment = 'center';
            app.SimNIBSLabel.FontName = 'PingFang SC';
            app.SimNIBSLabel.FontSize = 24;
            app.SimNIBSLabel.FontWeight = 'bold';
            app.SimNIBSLabel.Position = [2 280 229 60];
            app.SimNIBSLabel.Text = 'SimNIBS';

            % Create charmButton
            app.charmButton = uibutton(app.UIFigure, 'push');
            app.charmButton.ButtonPushedFcn = createCallbackFcn(app, @charmButtonPushed, true);
            app.charmButton.FontSize = 14;
            app.charmButton.Position = [30 212 170 52];
            app.charmButton.Text = '结构像分割';

            % Create TIstimulate
            app.TIstimulate = uibutton(app.UIFigure, 'push');
            app.TIstimulate.ButtonPushedFcn = createCallbackFcn(app, @TIstimulatePushed, true);
            app.TIstimulate.FontSize = 14;
            app.TIstimulate.Position = [30 146 170 52];
            app.TIstimulate.Text = 'TI模拟';

            % Create TIopt_eeg
            app.TIopt_eeg = uibutton(app.UIFigure, 'push');
            app.TIopt_eeg.ButtonPushedFcn = createCallbackFcn(app, @TIopt_eegPushed, true);
            app.TIopt_eeg.FontSize = 14;
            app.TIopt_eeg.Position = [30 80 170 52];
            app.TIopt_eeg.Text = 'TI优化(电极点位)';

            % Create TIopt_lf
            app.TIopt_lf = uibutton(app.UIFigure, 'push');
            app.TIopt_lf.ButtonPushedFcn = createCallbackFcn(app, @TIopt_lfPushed, true);
            app.TIopt_lf.FontSize = 14;
            app.TIopt_lf.Position = [30 14 170 52];
            app.TIopt_lf.Text = 'TI优化(导联场)';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = simnibs

            % Setup paths
            setup_path();

            % Create UIFigure and components
            createComponents(app)

            % Check for updates
            try checkForUpdate(app); end

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