function maxTimeLag=GM_EstimateMaxTimeLag(metaDataA,metaDataB,metaDataC,metaDataD,varargin)
if isempty(varargin)
    temprature = mean([mean(metaDataA.TEMP_C_) mean(metaDataB.TEMP_C_) mean(metaDataC.TEMP_C_) mean(metaDataD.TEMP_C_)]);
else
    temprature = varargin{1,1};
end
SoundSpeed=331+(0.6*temprature);

Lat=[mean(metaDataA.LAT) mean(metaDataB.LAT) mean(metaDataC.LAT) mean(metaDataD.LAT)];
Long=[mean(-metaDataA.LON) mean(-metaDataB.LON) mean(-metaDataC.LON) mean(-metaDataD.LON)];

dist=zeros(1,6);
[D,~]=distance(Lat(1),Long(1),Lat(2),Long(2));
dist(1)=deg2km(D,'earth');
[D,~]=distance(Lat(1),Long(1),Lat(3),Long(3));
dist(2)=deg2km(D,'earth');
[D,~]=distance(Lat(1),Long(1),Lat(4),Long(4));
dist(3)=deg2km(D,'earth');

[D,~]=distance(Lat(2),Long(2),Lat(3),Long(3));
dist(4)=deg2km(D,'earth');
[D,~]=distance(Lat(2),Long(2),Lat(4),Long(4));
dist(5)=deg2km(D,'earth');

[D,~]=distance(Lat(3),Long(3),Lat(4),Long(4));
dist(6)=deg2km(D,'earth');

MaxDistance=max(dist)*1000;

maxTimeLag=MaxDistance/SoundSpeed;
end
