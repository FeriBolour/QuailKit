% Original Algorithm written by Golnaz Moallem - Modified by Farshad Bolouri to
%adjust to the software
function [CallA,CallB,CallC,CallD,Calls] = QCallDetection(app)
pos = cell(1,4);
%% Template Reading
value = app.QuailCallTemplateDropDown.Value;

if isempty(app.template) || strcmp(value,"Real Bird")
    template=mat2gray(double(imread('template_combined_real_bird_2.jpg')));
else
    template = app.template;
end

if strcmp(value,"Real Bird") || strcmp(value,"Import")
    ceil_x = 30;
    MinProm_x = 0.25;
    temp_length_x = 0.5;
else
    ceil_x = 10;
    MinProm_x = 0.5;
    temp_length_x = 2/3;
end

temp_width=size(template,1);
temp_length=size(template,2);
%figure;imshow(template,[])
%title('Template')
CallA = [];CallB = [];CallC = [];CallD = [];

% Channel Mode
Ch1 = 1;
Ch2 = 2;

if strcmp(app.channel,"Channel 1")
    Ch2 = 1;
elseif strcmp(app.channel,"Channel 2")
    Ch1 = 2;
end

%% Quail Call Detection
if (strcmp(app.ModeSwitch.Value,"Offline") && strcmp(app.BatchProcessingTypeSwitch.Value, "Parallel"))
    spec_duration = app.loadIntervalRate;
    curtime = app.curLoadInterval*app.loadIntervalRate;% + app.curSubInterval*app.loadSubIntervalRate;
    time = curtime:1:(curtime+app.loadIntervalRate);
    Calls = cell(1,4);
    S_Channels = app.S_Channels; %Parallel
    spec_seg_size= 42;  %Parallel
    Ch_Mode = app.channel;
    parfor i = 1:4
        for channel = Ch1:Ch2
            Ispec= S_Channels{channel,i};
            if ~isempty(Ispec)
                spec_len=size(Ispec,2);
                spec_width=size(Ispec,1);
                %figure();imshow(Ispec)
                if strcmp(value,"Real Bird") || strcmp(value,"Import")
                    band=round((spec_width-temp_width)/3);
                    spec_seg_x= band:size(Ispec,1)-band;
                else
                    spec_seg_x= 1:size(Ispec,1);
                end
                
                call_candidates=[];
                %call_locations=[];
                no_seg=ceil(spec_len/spec_seg_size)*2-1;
                for s=1:no_seg
                    spec_seg=Ispec(spec_seg_x,(s-1)*ceil(spec_seg_size/2)+1:min((s-1)*ceil(spec_seg_size/2)+1+spec_seg_size,spec_len));
                    
                    cc=xcorr2(spec_seg,template);
                    cc_signal=mat2gray(max(cc));
                    cc_signal=cc_signal(round(temp_length/2)-1:end-round(temp_length/2));
                    
                    TF = islocalmax(cc_signal,'MinProminence',MinProm_x,'ProminenceWindow',temp_length/2);
                    locs=find(TF);
                    call=(((s-1)*ceil(spec_seg_size/2)+1)+locs)';
                    call_candidates=[call_candidates;call];
                    
                    %         figure;imshow(spec_seg)
                    %         x=1:length(cc_signal);
                    %         figure;plot(x,cc_signal,x(TF),cc_signal(TF),'r*')
                    %         waitforbuttonpress;
                end
                if ~isempty(call_candidates)
                    if length(call_candidates)>1
                        [L,n]=bwlabel(squareform(pdist(call_candidates))<temp_length*temp_length_x,4);
                        for k=1:n
                            [rows,~]=find(L==k);
                            rows=unique(rows);
                            spec_seg=Ispec(spec_seg_x,max(call_candidates(min(rows))-...
                                round(temp_length/2),1):min(call_candidates(min(rows))+round(temp_length/2),spec_len));
                            
                            cc=xcorr2(spec_seg,template);
                            cc_signal=mat2gray(max(cc));
                            cc_signal=cc_signal(round(temp_length/2)-1:end-round(temp_length/2));
                            
                            TF = islocalmax(cc_signal,'MinProminence',MinProm_x,'ProminenceWindow',temp_length/2);
                            location=find(TF);
                            
                            if call_candidates(min(rows)) <round(temp_length/2)
                                call=(time(1)+(spec_duration/spec_len)*location);
                                Calls{i}=[Calls{i};call'];
                                %call_locations=[call_locations;location'];
                            else
                                call=(time(1)+(spec_duration/spec_len)*(call_candidates(min(rows))+location-round(temp_length/2)));
                                Calls{i}=[Calls{i};call'];
                                %call_locations=[call_locations;call_candidates(min(rows))+location'-round(temp_length/2)];
                            end
                            
                            %                 figure;imshow(spec_seg)
                            %                 x=1:length(cc_signal);
                            %                 figure;plot(x,cc_signal,x(TF),cc_signal(TF),'r*')
                            %                 waitforbuttonpress;
                        end
                    else
                        spec_seg=Ispec(spec_seg_x,max(call_candidates(1)-round(temp_length/2),1):min(call_candidates(1)+round(temp_length/2),spec_len));
                        
                        cc=xcorr2(spec_seg,template);
                        cc_signal=mat2gray(max(cc));
                        cc_signal=cc_signal(round(temp_length/2)-1:end-round(temp_length/2));
                        
                        
                        TF = islocalmax(cc_signal,'MinProminence',MinProm_x,'ProminenceWindow',temp_length/2);
                        location=find(TF);
                        
                        if call_candidates(1) <round(temp_length/2)
                            call=(time(1)+(spec_duration/spec_len)*location)';
                            Calls{i}=[Calls{i};call'];
                            %call_locations=[call_locations;location'];
                        else
                            call=(time(1)+(spec_duration/spec_len)*(call_candidates(1)+location-round(temp_length/2)));
                            Calls{i}=[Calls{i};call'];
                            %call_locations=[call_locations;max(call_candidates(1)+location'-round(temp_length/2),1)];
                        end
                        
                        %             figure;imshow(spec_seg)
                        %             x=1:length(cc_signal);
                        %             figure;plot(x,cc_signal,x(TF),cc_signal(TF),'r*')
                        %             waitforbuttonpress;
                    end
                end
            end
        end
        
        Calls{i} = sort(Calls{i});
        
        if strcmp(Ch_Mode,"Both")
            j=1;
            while j < length(Calls{i})
                if abs(Calls{i}(j) - Calls{i}(j+1)) < 0.15
                    Calls{i}(j) = (Calls{i}(j) + Calls{i}(j+1))/2;
                    Calls{i}(j+1) = [];
                end
                j = j+1;
            end
        end
    end
else
    spec_duration = 10;
    curtime = app.curLoadInterval*app.loadIntervalRate + app.curSubInterval*app.loadSubIntervalRate;
    time = curtime:1:(curtime+10);
    Calls = cell(1,4);
    for i = 1:4
        for channel = Ch1:Ch2
            Ispec= app.S_Channels{channel,i};
            if ~isempty(Ispec)
                spec_len=size(Ispec,2);
                spec_width=size(Ispec,1);
                %figure();imshow(Ispec)
                if strcmp(value,"Real Bird") || strcmp(value,"Import")
                    band=round((spec_width-temp_width)/3);
                    spec_seg_x= band:size(Ispec,1)-band;
                else
                    spec_seg_x= 1:size(Ispec,1);
                end
                
                spec_seg_size=ceil(spec_len/ceil_x);
                
                call_candidates=[];
                %call_locations=[];
                no_seg=ceil(spec_len/spec_seg_size)*2-1;
                for s=1:no_seg
                    spec_seg=Ispec(spec_seg_x,(s-1)*ceil(spec_seg_size/2)+1:min((s-1)*ceil(spec_seg_size/2)+1+spec_seg_size,spec_len));
                    
                    cc=xcorr2(spec_seg,template);
                    cc_signal=mat2gray(max(cc));
                    cc_signal=cc_signal(round(temp_length/2)-1:end-round(temp_length/2));
                    
                    TF = islocalmax(cc_signal,'MinProminence',MinProm_x,'ProminenceWindow',temp_length/2);
                    locs=find(TF);
                    call=(((s-1)*ceil(spec_seg_size/2)+1)+locs)';
                    call_candidates=[call_candidates;call];
                    
                    %         figure;imshow(spec_seg)
                    %         x=1:length(cc_signal);
                    %         figure;plot(x,cc_signal,x(TF),cc_signal(TF),'r*')
                    %         waitforbuttonpress;
                end
                if ~isempty(call_candidates)
                    if length(call_candidates)>1
                        [L,n]=bwlabel(squareform(pdist(call_candidates))<temp_length*temp_length_x,4);
                        for k=1:n
                            [rows,~]=find(L==k);
                            rows=unique(rows);
                            spec_seg=Ispec(spec_seg_x,max(call_candidates(min(rows))-...
                                round(temp_length/2),1):min(call_candidates(min(rows))+round(temp_length/2),spec_len));
                            
                            cc=xcorr2(spec_seg,template);
                            cc_signal=mat2gray(max(cc));
                            cc_signal=cc_signal(round(temp_length/2)-1:end-round(temp_length/2));
                            
                            TF = islocalmax(cc_signal,'MinProminence',MinProm_x,'ProminenceWindow',temp_length/2);
                            location=find(TF);
                            
                            if call_candidates(min(rows)) <round(temp_length/2)
                                call=(time(1)+(spec_duration/spec_len)*location);
                                Calls{i}=[Calls{i};call'];
                                %call_locations=[call_locations;location'];
                            else
                                call=(time(1)+(spec_duration/spec_len)*(call_candidates(min(rows))+location-round(temp_length/2)));
                                Calls{i}=[Calls{i};call'];
                                %call_locations=[call_locations;call_candidates(min(rows))+location'-round(temp_length/2)];
                            end
                            
                            %                 figure;imshow(spec_seg)
                            %                 x=1:length(cc_signal);
                            %                 figure;plot(x,cc_signal,x(TF),cc_signal(TF),'r*')
                            %                 waitforbuttonpress;
                        end
                    else
                        spec_seg=Ispec(spec_seg_x,max(call_candidates(1)-round(temp_length/2),1):min(call_candidates(1)+round(temp_length/2),spec_len));
                        
                        cc=xcorr2(spec_seg,template);
                        cc_signal=mat2gray(max(cc));
                        cc_signal=cc_signal(round(temp_length/2)-1:end-round(temp_length/2));
                        
                        
                        TF = islocalmax(cc_signal,'MinProminence',MinProm_x,'ProminenceWindow',temp_length/2);
                        location=find(TF);
                        
                        if call_candidates(1) <round(temp_length/2)
                            call=(time(1)+(spec_duration/spec_len)*location)';
                            Calls{i}=[Calls{i};call'];
                            %call_locations=[call_locations;location'];
                        else
                            call=(time(1)+(spec_duration/spec_len)*(call_candidates(1)+location-round(temp_length/2)));
                            Calls{i}=[Calls{i};call'];
                            %call_locations=[call_locations;max(call_candidates(1)+location'-round(temp_length/2),1)];
                        end
                        
                        %             figure;imshow(spec_seg)
                        %             x=1:length(cc_signal);
                        %             figure;plot(x,cc_signal,x(TF),cc_signal(TF),'r*')
                        %             waitforbuttonpress;
                    end
                end
                
                % For Drawing Bounding Boxes
                %pos{i} = [Calls{i} 1200*ones(length(Calls{i}),1) ...
                %    0.5*ones(length(Calls{i}),1) 1900*ones(length(Calls{i}),1)];
            end
        end
        
        Calls{i} = sort(Calls{i});
        if strcmp(app.channel,"Both")
            j=1;
            while j < length(Calls{i})
                if abs(Calls{i}(j) - Calls{i}(j+1)) < 0.15
                    Calls{i}(j) = (Calls{i}(j) + Calls{i}(j+1))/2;
                    Calls{i}(j+1) = [];
                end
                j = j+1;
            end
        end
    end
end
%% Place Call Times into corresponding variables
CallA = Calls{1};
CallA(find(CallA==0)) = [];
CallB = Calls{2};
CallB(find(CallB==0)) = [];
CallC = Calls{3};
CallC(find(CallC==0)) = [];
CallD = Calls{4};
CallD(find(CallD==0)) = [];
%% Drawing Lines on Calls
if app.OffButton.Value == 1 && strcmp(app.ModeSwitch.Value,"Online")
    for row = 1:size(Calls{1},1)
        line(app.UIAxes,Calls{1}(row,:)*ones(1,length(app.F)),app.F,'Color','red','LineWidth',1.5);
    end
    for row = 1:size(Calls{2},1)
        line(app.UIAxes_2,Calls{2}(row,:)*ones(1,length(app.F)),app.F,'Color','red','LineWidth',1.5);
    end
    for row = 1:size(Calls{3},1)
        line(app.UIAxes_3,Calls{3}(row,:)*ones(1,length(app.F)),app.F,'Color','red','LineWidth',1.5);
    end
    for row = 1:size(Calls{4},1)
        line(app.UIAxes_4,Calls{4}(row,:)*ones(1,length(app.F)),app.F,'Color','red','LineWidth',1.5);
    end
end
end

%% Drawing Bounding Boxes
% for row = 1:size(pos{1},1)
%     rectangle(app.UIAxes,'Position',pos{1}(row,:),'EdgeColor','red')
% end
% for row = 1:size(pos{2},1)
%     rectangle(app.UIAxes_2,'Position',pos{2}(row,:),'EdgeColor','red')
% end
% for row = 1:size(pos{3},1)
%     rectangle(app.UIAxes_3,'Position',pos{3}(row,:),'EdgeColor','red')
% end
% for row = 1:size(pos{4},1)
%     rectangle(app.UIAxes_4,'Position',pos{4}(row,:),'EdgeColor','red')
% end
%
% end

