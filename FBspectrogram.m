function [Ave, Channels]  = FBspectrogram(app)
Ave = cell(1,4);% t= cell(1,4);
Channels = cell(2,4);
%column= [1,3,5,7];
window = app.Fs*app.window_size;
noverlap = round(app.noverlap_size*window);
if (strcmp(app.ModeSwitch.Value,"Offline") && strcmp(app.BatchProcessingTypeSwitch.Value, "Parallel"))
    %---------------Parallel Variables----------------
    Audio = app.AudioChannel;
    F = app.F;
    Fs = app.Fs;
    Audio_1 = Audio{1};
    Audio_2 = Audio{2};
    %-------------------------------------------------
    
    parfor i = 1:size(Audio_1,2)
        
        for j = 1:2
            if j == 1
                if window <= length(Audio_1(:,i))
                    Channels{j,i} = spectrogram(Audio_1(:,i),window,noverlap,F,Fs);
                    
                    Channels{j,i}= mat2gray(abs(Channels{j,i}));
                else
                    Channels{j,i} = [];
                end
            else
                if window <= length(Audio_2(:,i))
                    Channels{j,i} = spectrogram(Audio_2(:,i),window,noverlap,F,Fs);
                    
                    Channels{j,i}= mat2gray(abs(Channels{j,i}));
                else
                    Channels{j,i} = [];
                end
            end
        end
        
    end
    
else
    for i = 1:size(app.AudioChannel{1},2)
        %x = (app.audioSamples(app.subInterval(1):app.subInterval(2),column(i)) + ...
        %   app.audioSamples(app.subInterval(1):app.subInterval(2),column(i)+1))/2;
        
        for j = 1:2
            try
                x = app.AudioChannel{j}(app.subInterval(1):app.subInterval(2),i);
            catch e
                x = app.AudioChannel{j}(app.subInterval(1):end,i);
            end
            
            if window <= length(x)
                Channels{j,i} = spectrogram(x,window,noverlap,app.F,app.Fs);
                
                Channels{j,i}= mat2gray(abs(Channels{j,i}));
            else
                Channels{j,i} = [];
            end
        end
        
        if strcmp(app.ModeSwitch.Value,"Online") && strcmp(app.channel,"Both")
            Ave{i} = (Channels{1,i} + Channels{2,i}) / 2;
        elseif strcmp(app.ModeSwitch.Value,"Online") && strcmp(app.channel,"Channel 1")
            Ave{i} = Channels{1,i};
        elseif strcmp(app.ModeSwitch.Value,"Online") && strcmp(app.channel,"Channel 2")
            Ave{i} = Channels{2,i};
        end
        
    end
end

if strcmp(app.ModeSwitch.Value,"Online")
    curtime = app.curLoadInterval*app.loadIntervalRate + app.curSubInterval*app.loadSubIntervalRate;
    time = curtime:1:(curtime+10);
    timestr = app.convertToRealTime(time);
    
    imagesc(app.UIAxes,time,app.F,Ave{1})
    imagesc(app.UIAxes_2,time,app.F,Ave{2})
    imagesc(app.UIAxes_3,time,app.F,Ave{3})
    imagesc(app.UIAxes_4,time,app.F,Ave{4})
    
    app.UIAxes.YDir = 'normal'; app.UIAxes.XLim = [time(1),time(end)];
    app.UIAxes_2.YDir = 'normal'; app.UIAxes_2.XLim = [time(1),time(end)];
    app.UIAxes_3.YDir = 'normal'; app.UIAxes_3.XLim = [time(1),time(end)];
    app.UIAxes_4.YDir = 'normal'; app.UIAxes_4.XLim = [time(1),time(end)];
    app.UIAxes.YLim = [app.F(1),app.F(end)]; app.UIAxes.XTickLabel = timestr;
    app.UIAxes_2.YLim = [app.F(1),app.F(end)]; app.UIAxes_2.XTickLabel = timestr;
    app.UIAxes_3.YLim = [app.F(1),app.F(end)]; app.UIAxes_3.XTickLabel = timestr;
    app.UIAxes_4.YLim = [app.F(1),app.F(end)]; app.UIAxes_4.XTickLabel = timestr;
end
end