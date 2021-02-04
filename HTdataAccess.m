function app=HTdataAccess(app,mode)
    mode = lower(mode);
    if strcmp(mode, "write")
        app = Write(app);
    elseif strcmp(mode, "read")
        app = Read(app);
    end
end

function Write(handles)
    handles.Path.Spectrograms = fullfile(handles.Path.Recordings, handles.RecordingSelected,"Spectrogram");
    mkdir(handles.Path.Spectrograms);
    Mics=handles.MicDataList{2,2};
    activeMics=find([Mics{:,2}]);
    for k=activeMics
        S=handles.Data.S(:,:,k);
        F=handles.Data.F;
        t=handles.Data.t(k,:);
        micName = split(string(Mics{k,3}),".");
        micName = micName(1);
        save(fullfile(handles.Path.Spectrograms,micName+".mat"),'S','F','t');
    end
end
%Returns TimeSeries of data from chosen directory.
%If 4 audio files couldn't be found, this will return NaN.
function val = Read(app)
    if isempty(app.micPaths)
        app.micPaths = dir(fullfile(app.dataPath,"Mics")+"/*.wav");
        
        if length(app.micPaths) >= 4
            
            info=audioinfo(fullfile(app.dataPath,'Mics',app.micPaths(1).name));
            minSamples = info.TotalSamples;
            fs=info.SampleRate;
            for k=2:size(app.micPaths,1)
                info=audioinfo(fullfile(app.dataPath,'Mics',app.micPaths(k).name));
                minSamples = min(minSamples,info.TotalSamples);
            end
            
            app.micpos = zeros(size(app.micPaths,2),4);
            app.metPaths = string(zeros(size(app.micPaths,1),1));
            
            for k = 1:size(app.micPaths,1)
                metfilename = string(split(app.micPaths(k).name,'_'));
                metfilename = fullfile(app.dataPath,'Mics',metfilename(1)+"_A_Summary.txt");
                micData = readtable(metfilename);
                temp = [];
                if char(micData{1,4}) == 'N'
                    app.micpos(k,1) = mean(micData{:,3});
                else
                    app.micpos(k,1) = - mean(micData{:,3});
                end
                if char(micData{1,6}) == 'E'
                    app.micpos(k,2) =  mean(micData{:,5});
                else
                    app.micpos(k,2) = - mean(micData{:,5});
                end
                app.micpos(k,3) = 0;
                app.micpos(k,4) =  mean(micData{:,9});
                app.metPaths(k) = metfilename;
            end
            
            app.Samples = minSamples;
            namespl = split(app.micPaths(1).name,["__","_","$","."]);
            app.Date = namespl(3)+" "+namespl(4);
            app.Date =datetime(app.Date,'InputFormat','yyyyMMdd HHmmss');

            app.Fs = fs;

            app.curLoadInterval = 0;
            app.curSubInterval = 0;

            initialLoadInterval = [1 app.Fs*app.loadIntervalRate];

            if initialLoadInterval(2) <= app.Samples
                app.loadInterval = initialLoadInterval;
            else
                app.loadInterval = [1 app.Samples];
            end
            app.subInterval = [1 app.Fs*app.loadSubIntervalRate];
        end
    end

    app.AudioFilePlay = [];
    app.AudioChannel = cell(1,2);
%         app.AudioSignal = [];
    for k=1:size(app.micPaths,1)
            [raw,~]=audioread(fullfile(app.dataPath,'Mics',app.micPaths(k).name),app.loadInterval);
            
    %             app.audioSamples(1:length(raw),2*k-1:2*k)= raw;

    %            handles.Data.TS.Data(1:size(raw,1),k)=zscore(raw(:,handles.AudioChannel)); 
    %             Fn = app.Fs/2;
    %             Wp = 1000/Fn;
    %             Ws = 3000/Fn;
    %             raw = bandpass(raw,[Wp,Ws]);
            app.AudioFilePlay(1:size(raw,1),k) = (raw(:,1) + raw(:,2))/2;
            app.AudioChannel{1}(1:size(raw,1),k) = raw(:,1);
            app.AudioChannel{2}(1:size(raw,1),k) = raw(:,2);
    end

    val = app;
end