function batchProcess(app,updateLoadInterval)
    %% Batch Process
    matchedMatrix = [];
    CallsA = [];CallsB = [];CallsC = [];CallsD = [];
    app.curLoadInterval = 0; app.curSubInterval = 0;
    app.UpdateAudio(0,updateLoadInterval);
    
    %Preallocate temps matrix
    i = 1;
    temps = avg10sTemp(app);
    while true && strcmp(app.ModeSwitch.Value,"Offline")
        if strcmp(app.BatchProcessingTypeSwitch.Value, "Parallel")
            totalSeconds = (app.curLoadInterval+1)*app.loadIntervalRate;
        else
            totalSeconds = (app.curLoadInterval*app.loadIntervalRate + app.curSubInterval*app.loadSubIntervalRate) + 10;
        end
        [CallA,CallB,CallC,CallD] = QCallDetection(app);
        CallsA = [CallsA; CallA];CallsB = [CallsB; CallB];CallsC = [CallsC; CallC];CallsD = [CallsD; CallD];
        if (~isempty(CallA) + ~isempty(CallB) + ~isempty(CallC) + ~isempty(CallD))/4  >= 3/4
            matchedMatrix = [matchedMatrix GM_MatchCalls(CallA,CallB,CallC,CallD,GM_EstimateMaxTimeLag(readtable(app.metPaths(1)),...
                readtable(app.metPaths(2)),readtable(app.metPaths(3)),readtable(app.metPaths(4)),...
                temps(i)))];
        end
        
        if totalSeconds*app.Fs < app.Samples && totalSeconds >= 0
            app.UpdateAudio(totalSeconds);
            app.NorecordingsloadedyetLabel.Text = "Batch Processing("+string(num2str(floor((totalSeconds*app.Fs/app.Samples)*10000)/100))+"/100%)";
            drawnow;
            i = i+1;
        else
            app.NorecordingsloadedyetLabel.Text = "Batch Processing("+string(num2str(floor((totalSeconds*app.Fs/app.Samples)*10000)/100))+"/100%)";
            drawnow;
            break;
        end
    end
    
    if strcmp(app.ModeSwitch.Value,"Offline")
        %Instantiations
        filename = fullfile(pwd,"S2 Sound Finder for Spreadsheets.xls");
        matchedMatrix(matchedMatrix == 0) = NaN;
        lagMatrix = getLagMatrix(matchedMatrix);
        app.localizations = zeros(size(matchedMatrix,2),3);
        
        %Write data into Excel file
    
        %Microphone locations
        micUTMpos = ll2utm(app.micpos(:,1),app.micpos(:,2));
        writematrix(micUTMpos,filename,'Sheet', 'mic', 'Range',"B3:C"+num2str(3+size(app.micpos,1)));

        %Write lagmatrix
        writematrix(lagMatrix',filename,'Sheet', 'sound','Range',"C4:F"+num2str(4+size(lagMatrix',1)));

        %Write Temperatures
        %Put in temps for 10s intervals.
        timeVals = mean(matchedMatrix,1,'omitnan');
        tempMat = getTempMatrix(temps,timeVals);
        writematrix(tempMat,filename,'Sheet', 'sound','Range',"B4:B"+num2str(4+size(lagMatrix',1)));
    
        c = 331.3*sqrt(1+temps/273.15);
    
    %% Record data   
        resultfile = fullfile(app.dataPath,"results.xlsx");
        
        T = {};
        T{1,2} = "Latitude"; 
        T{1,3} = "Longitude";
        for i = 2:size(app.micNames,2)+1
            T{i,1} = app.micNames(i-1);
            T{i,2} = app.micpos(i-1,1);
            T{i,3} = app.micpos(i-1,2);
        end
        writecell(T,resultfile,"Sheet","Microphone Positions(GPS)");
        
        T{1,2} = "Easting"; 
        T{1,3} = "Northing";
        micposUTM = ll2utm(app.micpos(:,1),app.micpos(:,2));
        for i = 2:size(app.micNames,2)+1
            T{i,2} = micposUTM(i-1,1);
            T{i,3} = micposUTM(i-1,2);
        end
        writecell(T,resultfile,"Sheet","Microphone Positions(UTM)");
        
        T = {};
        T{1,1} = "10s intervals"; 
        T{1,2} = "Speed of Sound ";
        for i = 2:size(c,1)+1
            T{i,1} = i-1;
            T{i,2} = c(i-1,1);
        end
        writecell(T,resultfile,"Sheet","Speed of Sounds");
        
        T = table(CallsA);
        T.Properties.VariableNames = "Time Detected";
        writetable(T,resultfile,"Sheet",app.micNames(1));
        T = table(CallsB);
        T.Properties.VariableNames = "Time Detected";
        writetable(T,resultfile,"Sheet",app.micNames(2));
        
        T = table(CallsC);
        T.Properties.VariableNames = "Time Detected";
        writetable(T,resultfile,"Sheet",app.micNames(3));
        
        T = table(CallsD);
        T.Properties.VariableNames = "Time Detected";
        writetable(T,resultfile,"Sheet",app.micNames(4));

        T = table((1:size(matchedMatrix,2))',matchedMatrix(1,:)',matchedMatrix(2,:)',matchedMatrix(3,:)',matchedMatrix(4,:)');
        T.Properties.VariableNames = ["Number Matched Call" {app.micNames(1);app.micNames(2);app.micNames(3);...
            app.micNames(4)}'];
        writetable(T,resultfile,"Sheet","matchedMatrix");
        
%         T = table(localizations(:,1),localizations(:,2),localizations(:,3));
%         T.Properties.VariableNames = ["Number Matched Call","Latitude", "Longitude"];
%         writetable(T,resultfile,"Sheet","Localizations");
        
        %% Confusion Matrix
        contents = dir(fullfile(app.dataPath,"GT"));
        if size(contents,1)-2 > 0
            [~,~,Annotated] = annotationsBBox(app);
            [TP,FP,FN] = confusionMat(Annotated,{CallsA,CallsB,CallsC,CallsD});
            T = table({app.micNames(1);app.micNames(2);app.micNames(3);...
                app.micNames(4)},TP',FP',FN','VariableNames',{'Microphones',...
                'TP','FP','FN'});
            writetable(T,resultfile,"Sheet","ConfusionMatrix");
        end
        
        app.FinishButton.BackgroundColor = [0.90,0.90,0.90];
        app.BatchprocessLabel.Text = "Finish up the processing in Excel for "+num2str(size(matchedMatrix,2))+ " calls. Press finish when done.";
        app.FinishButton.Visible = true;
    end
end
function avgTemp = avg10sTemp(app)
    %Preallocate the array
    avgTemp = zeros(app.Samples/(app.Fs*10),1);
    
    timeleft = app.Samples/app.Fs;
    time = zeros(1,3);
    for i = 2:-1:0
       time(i+1) = floor(timeleft/60^i);
       timeleft = mod(timeleft,60^i);
    end
    time = flip(time);
    
    tempsMat = {};
    times = {};
    metadata = {readtable(app.metPaths(1)) readtable(app.metPaths(2)) readtable(app.metPaths(3)) readtable(app.metPaths(4))};
    for i = 1:length(app.metPaths)
        timeindices = find(isbetween(metadata{1,i}.DATE + metadata{1,i}.TIME, app.Date, app.Date+duration(time(1),time(2),time(3))));
        
        if ~isempty(timeindices)
            tempsMat{1,i} = metadata{1,i}.TEMP_C_(timeindices);
            temptime = str2double(split(string(metadata{1,i}.TIME(timeindices)),":"));
            temptime = 60^2*(temptime(:,1)-temptime(1,1)) + 60*(temptime(:,2)-temptime(1,2)) + temptime(:,3)-temptime(1,3);
            times{1,i} = temptime;
        end
    end
    
    tempavgtemps = zeros(1,4);
    num = 1;
    for i = 0:10:app.Samples/app.Fs
        
        for j = 1:length(app.metPaths)
            timeVal = floor(times{1,j}(min(abs(times{1,j} - i)) == abs(times{1,j}-i))/10)*10;
            if length(timeVal) > 1
                timeVal = timeVal(1);
            end
            tempind = intersect(find(times{1,j} - timeVal >= 0), find(times{1,j} - timeVal <= 10));
            tempavgtemps(j) = mean(tempsMat{1,j}(tempind));
        end
        avgTemp(num) = mean(tempavgtemps);
        num = num + 1;
    end
end

function tempMat = getTempMatrix(temps,timeVals)
    %Preallocate tempMat
    tempMat = zeros(size(timeVals,1),1);
    %Iterate through the temperatures
    for i = 1:length(temps)
        %Find timeVal indices for tempMat.
        tempTimeVals = timeVals - i*10;
        indices = intersect(find(tempTimeVals >= 0),find(tempTimeVals < 10));
        
        tempMat(indices) = temps(i);
    end
    tempMat = tempMat';
end

