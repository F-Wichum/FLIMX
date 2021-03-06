classdef StatsDescriptive < handle
    %=============================================================================================================
    %
    % @file     StatsDescriptive.m
    % @author   Matthias Klemm <Matthias_Klemm@gmx.net>
    % @version  1.0
    % @date     July, 2015
    %
    % @section  LICENSE
    %
    % Copyright (C) 2015, Matthias Klemm. All rights reserved.
    %
    % Redistribution and use in source and binary forms, with or without modification, are permitted provided that
    % the following conditions are met:
    %     * Redistributions of source code must retain the above copyright notice, this list of conditions and the
    %       following disclaimer.
    %     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
    %       the following disclaimer in the documentation and/or other materials provided with the distribution.
    %     * Neither the name of FLIMX authors nor the names of its contributors may be used
    %       to endorse or promote products derived from this software without specific prior written permission.
    %
    % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
    % WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
    % PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
    % INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
    % PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
    % HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
    % NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    % POSSIBILITY OF SUCH DAMAGE.
    %
    %
    % @brief    A class to compute descriptive statistical of all subjects in a study
    %
    properties(GetAccess = public, SetAccess = protected)
        visHandles = []; %structure to handles in GUI
        visObj = []; %handle to FLIMXVis
        subjectStats = cell(0,0);        
        statsDesc = cell(0,0);
        subjectDesc = cell(0,0);
        statHist = [];
        statCenters = [];
        normDistTests = [];
        normDistTestsLegend = cell(0,0);
    end
    properties (Dependent = true)
        study = '';
        condition = '';
        ch = 1;
        dType = '';
        totalDTypes = 0;
        statType = '';
        statPos = 1;
        totalStatTypes = 0;
        groupStats = cell(0,0);
        id = 0;
        classWidth = 1;
        exportModeFLIM = 1;
        exportModeROI = 1;
        exportModeStat = 0;
        exportModeCh = 1;
        exportModeCondition = 1;
        exportNormDistTests = 0;
        exportSubjectRawData = 0;
        currentSheetName = '';
        ROIType = 1;
        ROISubType = 1;
        ROIInvertFlag = 0;
        alpha = 5;
    end
    
    methods
        function this = StatsDescriptive(visObj)
            %constructor for StatsDescriptive
            this.visObj = visObj;
        end
        
        function createVisWnd(this)
            %make a new window
            this.visHandles = StatsDescriptiveFigure();
            set(this.visHandles.StatsDescriptiveFigure,'CloseRequestFcn',@this.menuExit_Callback);
            %set callbacks
            set(this.visHandles.popupSelStudy,'Callback',@this.GUI_SelStudyPop_Callback);
            set(this.visHandles.popupSelCondition,'Callback',@this.GUI_SelConditionPop_Callback);
            set(this.visHandles.popupSelCh,'Callback',@this.GUI_SelChPop_Callback);
            set(this.visHandles.popupSelFLIMParam,'Callback',@this.GUI_SelFLIMParamPop_Callback);
            set(this.visHandles.popupSelROIType,'Callback',@this.GUI_SelROITypePop_Callback);
            set(this.visHandles.popupSelROISubType,'Callback',@this.GUI_SelROITypePop_Callback);
            set(this.visHandles.popupSelStatParam,'Callback',@this.GUI_SelStatParamPop_Callback);
            %export
            set(this.visHandles.buttonExportExcel,'Callback',@this.GUI_buttonExcelExport_Callback);
            set(this.visHandles.checkSNFLIM,'Callback',@this.GUI_checkExcelExport_Callback);
            set(this.visHandles.checkSNROI,'Callback',@this.GUI_checkExcelExport_Callback);
            set(this.visHandles.checkSNCh,'Callback',@this.GUI_checkExcelExport_Callback);
            set(this.visHandles.checkSNCondition,'Callback',@this.GUI_checkExcelExport_Callback);
            set(this.visHandles.popupSelExportFLIM,'Callback',@this.GUI_popupSelExportFLIM_Callback);
            set(this.visHandles.popupSelExportROI,'Callback',@this.GUI_popupSelExportROI_Callback);
            set(this.visHandles.popupSelExportCh,'Callback',@this.GUI_popupSelExportCh_Callback);
            set(this.visHandles.popupSelExportCondition,'Callback',@this.GUI_popupSelExportCondition_Callback);
            %display
            set(this.visHandles.buttonUpdateGUI,'Callback',@this.GUI_buttonUpdateGUI_Callback);
            %table main
            axis(this.visHandles.axesBar,'off');
            axis(this.visHandles.axesBoxplot,'off');
            set(this.visHandles.popupSelStatParam,'String',FData.getDescriptiveStatisticsDescription(),'Value',3);
            %normal distribution tests
            set(this.visHandles.editAlpha,'Callback',@this.GUI_editAlpha_Callback);
            %progress bar
            xpatch = [0 0 0 0];
            ypatch = [0 0 1 1];
            axis(this.visHandles.axesProgress ,'off');            
            xlim(this.visHandles.axesProgress,[0 100]);
            ylim(this.visHandles.axesProgress,[0 1]);
            this.visHandles.patchProgress = patch(xpatch,ypatch,'r','EdgeColor','r','Parent',this.visHandles.axesProgress);
            this.visHandles.textProgress = text(1,1,'','Parent',this.visHandles.axesProgress,'Fontsize',8);%,'HorizontalAlignment','right','Units','pixels');
        end
        
        function out = isOpenVisWnd(this)
            %check if figure is still open
            out = ~(isempty(this.visHandles) || ~isfield(this.visHandles,'StatsDescriptiveFigure') || ~ishandle(this.visHandles.StatsDescriptiveFigure) || ~strcmp(get(this.visHandles.StatsDescriptiveFigure,'Tag'),'StatsDescriptiveFigure'));
        end
        
        function checkVisWnd(this)
            %check if my window is open, if not: create it
            if(~this.isOpenVisWnd())
                %no window - open one
                this.createVisWnd();
            end
            this.GUI_SelFLIMParamPop_Callback(this.visHandles.popupSelFLIMParam,[]); %will call setupGUI
            figure(this.visHandles.StatsDescriptiveFigure);
        end
        
        function setCurrentStudy(this,studyName,condition)
            %set the GUI to a certain study and condition
            if(~this.isOpenVisWnd())
                %no window 
                return
            end
            %find study
            idx = find(strcmp(get(this.visHandles.popupSelStudy,'String'),studyName),1);
            if(isempty(idx))
                return
            end
            set(this.visHandles.popupSelStudy,'Value',idx);
            this.setupGUI();
            %find condition
            idx = find(strcmp(get(this.visHandles.popupSelCondition,'String'),condition),1);
            if(isempty(idx))
                return
            end
            set(this.visHandles.popupSelCondition,'Value',idx);
        end 
        
        %% GUI callbacks
        function GUI_SelStudyPop_Callback(this,hObject,eventdata)
            %
            this.setupGUI();
        end
        
        function GUI_SelConditionPop_Callback(this,hObject,eventdata)
            %
            this.setupGUI();
        end
        
        function GUI_SelChPop_Callback(this,hObject,eventdata)
            %
            this.setupGUI();
        end
        
        function GUI_SelFLIMParamPop_Callback(this,hObject,eventdata)
            %
            this.setupGUI();
            [cw, ~, ~, ~] = getHistParams(this.visObj.getStatsParams(),this.ch,this.dType,this.id);
            set(this.visHandles.editClassWidth,'String',cw);            
        end
        
        function GUI_SelROITypePop_Callback(this,hObject,eventdata)
            %
            this.setupGUI();
        end
        
        function GUI_SelStatParamPop_Callback(this,hObject,eventdata)
            %
            %set class width on statistics parameter change
            this.setupGUI();
        end
        
        function GUI_buttonUpdateGUI_Callback(this,hObject,eventdata)
            %
            try
                set(hObject,'String',sprintf('<html><img src="file:/%s"/> Update</html>',FLIMX.getAnimationPath()));
                drawnow;
            end
            this.clearResults();
            this.updateGUI();
            set(hObject,'String','Update');
        end
        
        function GUI_DispGrpPop_Callback(this,hObject,eventdata)
            %
            this.updateGUI();
        end
        
        function GUI_editAlpha_Callback(this,hObject,eventdata)
            %alpha value changed
            set(hObject,'String',num2str(abs(max(0.1,min(10,abs(str2double(get(hObject,'string'))))))));
            this.clearResults();
            this.updateGUI();
        end
        
        function GUI_popupSelExportFLIM_Callback(this,hObject,eventdata)
            %
            if(get(hObject,'Value') == 1)
                set(this.visHandles.checkSNFLIM,'Enable','on')
            else
                set(this.visHandles.checkSNFLIM,'Enable','off','Value',1)
            end
            
            GUI_checkExcelExport_Callback(this,this.visHandles.checkSNFLIM,eventdata);
        end
        
        function GUI_popupSelExportROI_Callback(this,hObject,eventdata)
            %
            if(get(hObject,'Value') == 1)
                set(this.visHandles.checkSNROI,'Enable','on')
            else
                set(this.visHandles.checkSNROI,'Enable','off','Value',1)
            end
            
            GUI_checkExcelExport_Callback(this,this.visHandles.checkSNROI,eventdata);
        end
        
        function GUI_popupSelExportCh_Callback(this,hObject,eventdata)
            %
            if(get(hObject,'Value') == 1)
                set(this.visHandles.checkSNCh,'Enable','on')
            else
                set(this.visHandles.checkSNCh,'Enable','off','Value',1)
            end
            GUI_checkExcelExport_Callback(this,this.visHandles.checkSNCh,eventdata);
        end
        
        function GUI_popupSelExportCondition_Callback(this,hObject,eventdata)
            %
            if(get(hObject,'Value') == 1)
                set(this.visHandles.checkSNCondition,'Enable','on')
            else
                set(this.visHandles.checkSNCondition,'Enable','off','Value',1)
            end
            GUI_checkExcelExport_Callback(this,this.visHandles.checkSNCondition,eventdata);
        end
        
        function GUI_checkExcelExport_Callback(this,hObject,eventdata)
            %
            set(this.visHandles.editSNPreview,'String',this.currentSheetName);
        end
        
        function GUI_buttonExcelExport_Callback(this,hObject,eventdata)
            %
            [file,path] = uiputfile('*.xls','Export Data in Excel Fileformat...');
            if ~file ; return ; end
            try
                set(hObject,'String',sprintf('<html><img src="file:/%s"/></html>',FLIMX.getAnimationPath()));
                drawnow;
            end
            fn = fullfile(path,file);
            switch this.exportModeFLIM
                case 1 %single (current) result
                    if(isempty(this.subjectStats))
                        this.makeStats();
                        if(isempty(this.subjectStats))
                            this.clearPlots();
                        end
                    end
                    FLIMIds = get(this.visHandles.popupSelFLIMParam,'Value');
                case 2 %all FLIM parameters
                    FLIMIds = 1:this.totalDTypes;
                    this.clearResults();
            end
            switch this.exportModeROI
                case 1 %current ROI
                    ROIIds = 1;
                case 2 %all ETDRS grid ROIs
                    set(this.visHandles.popupSelROIType,'Value',2); %switch to ETDRS grid
                    this.setupGUI();
                    this.clearResults();
                    ROIIds = 1:length(get(this.visHandles.popupSelROISubType,'String'));
                case 3 %all major ROIs except for the ETDRS grid
                    this.clearResults();
                    ROIIds = 3:8;
            end
            switch this.exportModeCh
                case 1 %current channel
                    chIds = this.ch;
                case 2 % all channels
                    chIds = 1:length(get(this.visHandles.popupSelCh,'String'));
                    this.clearResults();
            end
            switch this.exportModeCondition
                case 1 %current condition
                    condIds = get(this.visHandles.popupSelCondition,'Value');
                case 2 % all conditions
                    condIds = 1:length(get(this.visHandles.popupSelCondition,'String'));
                    this.clearResults();
            end
            %loop over all export paramters
            totalIter = length(condIds)*length(FLIMIds)*length(ROIIds)*length(chIds);
            curIter = 0;
            for v = 1:length(condIds)
                if(length(condIds) > 1)
                    set(this.visHandles.popupSelCondition,'Value',v);
                    this.clearResults();
                    this.GUI_SelConditionPop_Callback(this.visHandles.popupSelCondition,[]); %will call setupGUI
                end
                for f = 1:length(FLIMIds)
                    if(length(FLIMIds) > 1)
                        set(this.visHandles.popupSelFLIMParam,'Value',f);
                        this.clearResults();
                        this.GUI_SelFLIMParamPop_Callback(this.visHandles.popupSelFLIMParam,[]); %will call setupGUI
                    end
                    for r = 1:length(ROIIds)
                        if(length(ROIIds) > 1)
                            switch this.exportModeROI
                                case 2 %all ETDRS grid ROIs
                                    set(this.visHandles.popupSelROIType,'Value',2); %switch to ETDRS grid
                                    set(this.visHandles.popupSelROISubType,'Value',ROIIds(r));
                                    this.clearResults();
                                    this.GUI_SelROITypePop_Callback(this.visHandles.popupSelROIType,[]); %will call setupGUI
                                case 3 %all major ROIs except for the ETDRS grid
                                    set(this.visHandles.popupSelROIType,'Value',ROIIds(r));
                                    this.clearResults();
                                    this.GUI_SelROITypePop_Callback(this.visHandles.popupSelROIType,[]); %will call setupGUI
                            end
                        end
                        for c = 1:length(chIds)
                            if(length(chIds) > 1)
                                set(this.visHandles.popupSelCh,'Value',c);
                                this.clearResults();
                                this.GUI_SelChPop_Callback(this.visHandles.popupSelCh,[]);
                            end
                            this.updateGUI();
                            if(isempty(this.subjectStats))
                                this.makeStats();
                                if(isempty(this.subjectStats))
                                    continue;
                                end
                            end
                            exportExcel(fn,this.subjectStats,this.statsDesc,this.subjectDesc,this.currentSheetName,sprintf('%s%d',this.dType,this.id));
                            if(this.exportModeStat)
                                data = cell(0,0);
                                str = get(this.visHandles.popupSelStatParam,'String');
                                for i = 1:this.totalStatTypes
                                    [statHist, statCenters] = makeHistogram(this,i);
                                    if(~isempty(statHist))
                                        data(end+1,1) = str(i);
                                        data(end,2:1+length(statCenters)) = num2cell(statCenters);
                                        data(end+1,2:1+length(statHist)) = num2cell(statHist);
                                        data(end+1,1) = cell(1,1);
                                    end
                                end
                                exportExcel(fn,data,'',num2cell(this.statCenters),['Hist-' this.currentSheetName],sprintf('%s%d',this.dType,this.id));
                            end
                            if(this.exportNormDistTests)
                                data = this.normDistTestsLegend;
                                data(:,2) = sprintfc('%1.4f',this.normDistTests(:,1));
                                data(:,3) = num2cell(logical(this.normDistTests(:,2)));
                                exportExcel(fn,data,{'Test','p','Significance'},'',[this.statType '-' this.currentSheetName],'');
                            end
                            if(this.exportSubjectRawData)
                                subjects = this.visObj.fdt.getSubjectsNames(this.study,this.condition);
                                for s = 1:length(subjects)
                                    fdt = this.visObj.fdt.getFDataObj(this.study,subjects{s},this.ch,this.dType,this.id,1);
                                    rc = fdt.getROICoordinates(this.ROIType);
                                    data = fdt.getROIImage(rc,this.ROIType,this.ROISubType,this.ROIInvertFlag);
                                    if(this.ROIType == 1)
                                        txt = {'C','IS','IN','II','IT','OS','ON','OI','OT','IR','OR','FC'}';
                                        rStr = txt{this.ROISubType};
                                    else
                                        txt = {'Rect1','Rect2','Circ1','Circ2','Poly1','Poly2'};
                                        rStr = txt{this.ROIType-1};
                                    end                                        
                                    exportExcel(fn,data,{''},'',sprintf('%s_%s_%d_%s%d',subjects{s},rStr,this.ch,this.dType,this.id),'');
                                end
                            end
                            curIter = curIter+1;
                            this.updateProgressbar(curIter/totalIter,sprintf('%d%%',round(curIter/totalIter*100)));
                        end
                    end
                end
            end
            set(hObject,'String','Go');
            this.updateProgressbar(0,'');
        end
        
        function clearResults(this)
            %clear all current results
            this.subjectStats = cell(0,0);
            this.statsDesc = cell(0,0);
            this.subjectDesc = cell(0,0);
            this.statHist = [];
            this.statCenters = [];
            this.normDistTests = [];
            this.normDistTestsLegend = cell(0,0);
        end
        
        function clearPlots(this)
            %clear 3D plot and table
            if(~this.isOpenVisWnd())
                cla(this.visHandles.axesBar);
                cla(this.visHandles.axesBoxplot);
                set(this.visHandles.tableSubjectStats,'ColumnName','','RowName','','Data',[],'ColumnEditable',[]);
                set(this.visHandles.tableNormalTests,'Data',[]);
            end
        end
        
        function setupGUI(this)
            %setup GUI control
            if(~this.isOpenVisWnd())
                %no window
                return
            end
            this.clearResults();
            %update studies and views
            sStr = this.visObj.fdt.getStudyNames();
            set(this.visHandles.popupSelStudy,'String',sStr,'Value',min(length(sStr),get(this.visHandles.popupSelStudy,'Value')));
            %get views for the selected studies
            vStr = this.visObj.fdt.getStudyViewsStr(this.study);
            set(this.visHandles.popupSelCondition,'String',vStr,'Value',min(length(vStr),get(this.visHandles.popupSelCondition,'Value')));
            %update channels and parameters
            ds1 = this.visObj.fdt.getSubjectsNames(this.study,this.condition);
            if(~isempty(ds1))
                chStr = this.visObj.fdt.getChStr(this.study,ds1{1});
                coStr = this.visObj.fdt.getChObjStr(this.study,ds1{1},this.ch);
                coStr = sort(coStr);
            else
                chStr = [];
                coStr = 'param';
            end
            if(isempty(chStr))
                chStr = 'Ch 1';
            end
            set(this.visHandles.popupSelCh,'String',chStr,'Value',min(length(chStr),get(this.visHandles.popupSelCh,'Value')));
            %ROI
            if(this.ROIType ~= 1)
                flag = 'off';
            else
                flag = 'on';
            end
            set(this.visHandles.popupSelROISubType,'Visible',flag);
            %params
            oldPStr = get(this.visHandles.popupSelFLIMParam,'String');
            if(iscell(oldPStr))
                oldPStr = oldPStr(get(this.visHandles.popupSelFLIMParam,'Value'));
            end
            %try to find oldPStr in new pstr
            idx = find(strcmp(oldPStr,coStr),1);
            if(isempty(idx))
                idx = min(get(this.visHandles.popupSelFLIMParam,'Value'),length(coStr));
            end            
            set(this.visHandles.popupSelFLIMParam,'String',coStr,'Value',idx);
            this.clearPlots();
            %excel export sheet name preview
            set(this.visHandles.editSNPreview,'String',this.currentSheetName);
        end
        
        function updateGUI(this)
            %update tables and axes
            if(isempty(this.subjectStats))
                this.makeStats();
                if(isempty(this.subjectStats))
                    this.clearPlots();
                end
            end
            set(this.visHandles.tableSubjectStats,'ColumnName',this.statsDesc,'RowName',this.subjectDesc,'Data',FLIMXFitGUI.num4disp(this.subjectStats));
            set(this.visHandles.tableGroupStats,'ColumnName',this.statsDesc,'RowName','','Data',FLIMXFitGUI.num4disp(this.groupStats));
            %axes
            if(~isempty(this.statHist))
                bar(this.visHandles.axesBar,this.statCenters,this.statHist);
                boxplot(this.visHandles.axesBoxplot,this.subjectStats(:,this.statPos),'labels',this.statsDesc(this.statPos));
                if(~isempty(this.normDistTests))
                    tmp = this.normDistTestsLegend;
                    tmp(:,2) = sprintfc('%1.4f',this.normDistTests(:,1));
                    tmp(:,3) = num2cell(logical(this.normDistTests(:,2)));
                    set(this.visHandles.tableNormalTests,'Data',tmp);
                end
            end
        end
        
        function updateProgressbar(this,x,text)
            %update progress bar; inputs: progress x: 0..1, text on progressbar
            if(this.isOpenVisWnd())
                x = max(0,min(100*x,100));
                xpatch = [0 x x 0];
                set(this.visHandles.patchProgress,'XData',xpatch,'Parent',this.visHandles.axesProgress)
                yl = ylim(this.visHandles.axesProgress);
                set(this.visHandles.textProgress,'Position',[1,yl(2)/2,0],'String',text,'Parent',this.visHandles.axesProgress);
                drawnow;
            end
        end
                
        function makeStats(this)
            %collect stats info from FDTree
            [this.subjectStats, this.statsDesc, this.subjectDesc] = this.visObj.fdt.getStudyStatistics(this.study,this.condition,this.ch,this.dType,this.id,this.ROIType,this.ROISubType,this.ROIInvertFlag,true);
            [this.statHist, this.statCenters] = this.makeHistogram(this.statPos);
            [this.normDistTests, this.normDistTestsLegend]= this.makeNormalDistributionTests(this.statPos);
        end
        
        function [result, legend] = makeNormalDistributionTests(this,statsID)
            %test statsID for normal distribution
            result = []; legend = cell(0,0);
            if(isempty(this.subjectStats) || statsID > length(this.subjectStats))
                return
            end
            legend = {'Lilliefors';'Shapiro-Wilk';'Kolmogorov-Smirnov'};
            ci = this.subjectStats(:,statsID);
            if(~any(ci(:)))
                return
            end
            [result(1,2),result(1,1)] = StatsDescriptive.test4NormalDist('li',ci,this.alpha);
            [result(2,2),result(2,1)] = StatsDescriptive.test4NormalDist('sw',ci,this.alpha);
            [result(3,2),result(3,1)] = StatsDescriptive.test4NormalDist('ks',ci,this.alpha);
        end
        
        function [statHist, statCenters] = makeHistogram(this,statsID)
            %make histogram for statsID
            statHist = []; statCenters = [];
            if(isempty(this.subjectStats) || statsID > length(this.subjectStats))
                return
            end
            ci = this.subjectStats(:,statsID);
            cw = this.classWidth;
            c_min = round((min(ci(:)))/cw)*cw;%min(ci(:));
            c_max = round((max(ci(:)))/cw)*cw;%max(ci(:));
            if(c_max - c_min < eps)
                %flat data -> max = min, just leave it in one class
                statHist = numel(ci);
                statCenters = c_min;
                return
            end
            %make centers vector
            statCenters = c_min : cw : c_max;
            while length(statCenters) > 100
                cw = cw*10;
                statCenters = c_min : cw : c_max;
            end
            if(~all(isnan(ci(:))) && ~all(isinf(ci(:))))
                statHist = hist(ci,statCenters);
            end
        end
        
        function menuExit_Callback(this,hObject,eventdata)
            %executes on figure close
            if(~isempty(this.visHandles) && ishandle(this.visHandles.StatsDescriptiveFigure))
                delete(this.visHandles.StatsDescriptiveFigure);
            end
        end
        
        %% dependend properties
        function out = get.study(this)
            out = get(this.visHandles.popupSelStudy,'String');
            if(~ischar(out) && ~isempty(out))
                gNr = get(this.visHandles.popupSelStudy,'Value');
                out = out{min(gNr,length(out))};
            end
        end
        
        function out = get.condition(this)
            out = get(this.visHandles.popupSelCondition,'String');
            if(~ischar(out) && ~isempty(out))
                gNr = get(this.visHandles.popupSelCondition,'Value');
                out = out{min(gNr,length(out))};
            end
        end
        
        function out = get.ch(this)
            out = get(this.visHandles.popupSelCh,'String');
            if(~ischar(out))
                out = out{get(this.visHandles.popupSelCh,'Value')};
            end
            out = str2double(out(isstrprop(out, 'digit')));
        end
        
        function dType = get.dType(this) 
            dType = [];
            out = get(this.visHandles.popupSelFLIMParam,'String');
            if(~ischar(out))
                [dType, dTypeNr] = FLIMXVisGUI.FLIMItem2TypeAndID(out{get(this.visHandles.popupSelFLIMParam,'Value')});
                dType = dType{1};
            end
        end
        
        function out = get.totalDTypes(this)
            tmp = get(this.visHandles.popupSelFLIMParam,'String');
            if(isempty(tmp))
                out = 0;
                return
            end
            if(~ischar(tmp))
                out = length(tmp);
            else
                out = 1;
            end
        end
        
        function str = get.statType(this)
            str = get(this.visHandles.popupSelStatParam,'String');
            if(~ischar(str))
                str = str{get(this.visHandles.popupSelStatParam,'Value')};
            end
            %[dType, dTypeNr] = FLIMXVisGUI.FLIMItem2TypeAndID(str);
        end
        
        function out = get.totalStatTypes(this)
            tmp = get(this.visHandles.popupSelStatParam,'String');
            if(isempty(tmp))
                out = 0;
                return
            end
            if(~ischar(tmp))
                out = length(tmp);
            else
                out = 1;
            end
        end
        
        function out = get.groupStats(this)
            %return group mean of subject statistics (average of each parameter)
            if(isempty(this.subjectStats))
                out = [];
            else
                out = mean(this.subjectStats,1);
            end
        end
        
        function out = get.statPos(this)
            out = get(this.visHandles.popupSelStatParam,'Value');
        end
        
        function out = get.classWidth(this)
            out = abs(str2double(get(this.visHandles.editClassWidth,'String')));
        end
        
        function dTypeNr = get.id(this)
            dTypeNr = [];
            out = get(this.visHandles.popupSelFLIMParam,'String');
            if(~ischar(out))
                [~, dTypeNr] = FLIMXVisGUI.FLIMItem2TypeAndID(out{get(this.visHandles.popupSelFLIMParam,'Value')});
                dTypeNr = dTypeNr(1);
            end 
        end
        
        function out = get.exportModeFLIM(this)
            out = get(this.visHandles.popupSelExportFLIM,'Value');
        end
        
        function out = get.exportModeStat(this)
            out = get(this.visHandles.checkExportStatsHist,'Value');
        end  
        
        function out = get.exportNormDistTests(this)
            out = get(this.visHandles.checkExportNormalTests,'Value');
        end
        
        function out = get.exportSubjectRawData(this)
            out = get(this.visHandles.checkExportSubjectData,'Value');
        end
        
        function out = get.exportModeROI(this)
            out = get(this.visHandles.popupSelExportROI,'Value');
        end
        
        function out = get.exportModeCh(this)
            out = get(this.visHandles.popupSelExportCh,'Value');
        end
        
        function out = get.exportModeCondition(this)
            out = get(this.visHandles.popupSelExportCondition,'Value');
        end
                
        function out = get.currentSheetName(this)
            %build current sheet name
            out = '';      
            if(get(this.visHandles.checkSNCondition,'Value'))
                out = this.condition;
                if(strcmp(out,FDTree.defaultConditionName()))
                    out = '';
                else
                    out = [out '_'];
                end
            end
            if(get(this.visHandles.checkSNROI,'Value'))
                if(this.ROIType == 1)
                    str = get(this.visHandles.popupSelROISubType,'String');
                    out = [out 'ETDRS ' str{this.ROISubType} '_'];
                else
                    str = get(this.visHandles.popupSelROIType,'String');
                    out = [out str{this.ROIType+1} '_'];
                end
            end
            if(get(this.visHandles.checkSNCh,'Value'))
                out = [out sprintf('ch%d_',this.ch)];
            end
            if(get(this.visHandles.checkSNFLIM,'Value'))
                out = [out sprintf('%s%d_',this.dType,this.id)];
            end
            if(isempty(out))
                out = 'sheetName';
            else
                out(end) = ''; %remove trailing '_'
                out = out(1:min(length(out),31)); %sheet name is limited to 31 characters
            end
        end
        
        function out = get.ROIType(this)
            out = get(this.visHandles.popupSelROIType,'Value')-1;
        end
        
        function out = get.ROISubType(this)
            out = get(this.visHandles.popupSelROISubType,'Value');
        end
        
        function out = get.ROIInvertFlag(this)
            out = 0; %get(this.visHandles.popupSelROISubType,'Value');
        end
        
        function out = get.alpha(this)
            %get current alpha value
            out = abs(str2double(get(this.visHandles.editAlpha,'string')))/100;
        end
    end %methods
    
    methods(Static)
        function [h,p] = test4NormalDist(test,data,alpha)
            %test group data for normal distribution
            h = []; p = [];
            data = data(~isnan(data));
            data = data(~isinf(data));
            if(~any(data(:)) || length(data) < 4)
                return
            end
            switch test
                case 'li' %Lilliefors test
                    [h,p] = lillietest(data,'Alpha',alpha);
                case 'ks' %kolmogorov smirnov test
                    %center data for ks test
                    if(var(data(:)) < eps)
                        h = 1; p = 0;
                    else
                        tmp = data(:);
                        tmp = (tmp-mean(tmp(:)))/std(tmp);
                        [h,p] = kstest(tmp,'Alpha',alpha);
                    end
                case 'sw' %shapiro-wilk test
                    if(var(data(:)) < eps)
                        h = 1; p = 0;
                    else
                        [h,p] = swtest(data,alpha);
                    end
            end
        end
        
    end %static
end %class