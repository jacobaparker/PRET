function output = blinkinterp(trial,samplerate,th1,th2,bwindow,betblink)
%Based on method described in Mathôt 2013
%https://www.researchgate.net/publication/236268543_A_simple_way_to_reconstruct_pupil_size_during_eye_blinks
%%%%% RD: Add full Mathôt citation %%%%%%
%
%blinkinterp detects blink regions in a pupil size timeseries, removes the
%regions, then interpolates through those regions using the surrounding
%data.
%
%This code only works if blinks are recorded as zeros preceded by a sharp
%drop in pupil size values and followed by a sharp rise in pupil size.
% 
% *DEVELOPED/OPTIMIZED FOR DATA COLLECTED WITH EYELINK WITH A SAMPLING 
%  RATE OF 1kHz*
%
%Blinks are detected by first finding the beginning and end location of
%each region of zeros in the trial. Zero regions that are sufficiently 
%close together are combined, making them a single blink. The code then
%looks bwindow datapoints away from the beginning/end of each zero region
%to find blink onset/blink offset. To determine onset/offset, the original
%time series is smoothed by convolving with a 11 ms Hanning window, and
%then a velocity profile is produced from the smoothed time series. The
%code finds blink onset for each blink by looking at the velocity profile
%in the bwindow period before the first zero and finding a value above a 
%set threshold. Blink offset is done the same on the bwindow period after 
%the last zero.
%
%The interpolation is accomplished by defining the blink onset point as t2 
%and the blink offset point as t3. A point in the data before blink
%onset and a point after blink offset are chosen (t1 and t4 respectively).
%The t1-t2 distance and t3-t4 distance are equal to the t2-t3 difference,
%unless the difference exceeds the value of betblink (an explanation of
%this can be found below). In this case, the t1-t2 and t3-t4 difference are
%set as equal to betblink (unless the data points at t1 or t4 equal 0 or
%nan, in which case t1/t4 is moved closer and closer to t2/t3 until a valid
%data point is found). Then, a cubic spline interpolation is performed using
%the four points. If t1=t2 and/or t3=t4, then the interpolation is only
%done with 3 or 2 points (the spline function can't handle repeat or out of
%order points).
%
%inputs: (values in parantheses relfect recommended values)
%   trial = vector time series of pupil size
%
%   samplerate = sample rate in Hz
%
%   th1 = (5) velocity threshold of pupil onset detection (set as a positive
%   number, but is really negative, i.e., the pupil area is decreasing) 
%
%   th2 = (3) velocity threshold of pupil offset detection (is positive in both
%   input and in script). Pupil offset is more gradual than
%   onset, so a more sensitive (i.e., lower) threshold is needed.
%
%   bwindow = (50) time in ms from zero region program looks for
%   blink onset, offset. This number should be restricted in general to
%   avoid points not associated with the blink from being chosen. It also
%   should be less than betblink to avoid interpolation using data from 
%   another blink region.
%
%   betblink = (75) the minimum duration in ms required
%   to form a valid region of data. This prevents small interblink
%   regions of fluctuating data from being included in the trial and
%   affecting the interpolations. betblink is also used to define the max
%   t1-t2 and t3-t4 distance. Restricting this distance allows the
%   interpolation to better reflect the data surrounding the blink. In
%   general, the smaller this number, the flatter the interpolation.
%
%output:
%   output = trial with blink regions removed and interpolated

sf = 1000/samplerate; % sampling factor
th1 = th1*sf;
th2 = th2*sf;
bwindow = bwindow/sf;
betblink = betblink/sf;

nhan = 11; % hanning window parameter
ncushion = 10; % size of cushion for convolution
intbound = 5; % minimum distance t2/t3 must be from beginning/end of trial

if all(trial) == 0  %check to see if blink regions (zeros) exist in trial
    
    duration = length(trial);
        
    trial = [(trial(1)*ones(1,ncushion)) trial];  %add cushion for convultion
    trial = [trial (trial(end)*ones(1,ncushion))];
    
    h = hanning(nhan); %function convolved with raw trial
    htrial = conv(trial,h/sum(h),'same'); %generate smoothed trial (easier to read velocity profile
    
    trial(1:ncushion) = []; %remove cushions from trial
    trial(duration+1:end) = [];
    
    htrial(1:ncushion) = []; %remove cushions from smoothed trial
    htrial(duration+1:end) = [];
    
    logtrial = trial ~= 0; %turn trial into a logical vector
    zstarts = find(diff(logtrial) == -1 ) + 1; %find the positions of the first zero for each region
    zends = find(diff(logtrial) == 1); %find the positions of the last zero for each region
    
    if logtrial(1) == 0 %check if trial starts with zero
        zstarts = [1 zstarts]; %if so, adds that position to zstarts
    end
    
    if logtrial(end) == 0 %check if trial ends with zero
        zends = [zends length(trial)]; %if so, adds that position to zends
    end
    
    for k = length(zends)-1:-1:1 %go backward through zends and zstarts
        if zstarts(k+1)-zends(k) < betblink %check to see if interblink regions of data are long enough
            zstarts(k+1) = []; %if not long enough, change zero location data to include that in blink
            zends(k) = [];
        end
    end
    
    for l = 1:length(zends) %this loop fills in determined zero regions with zeros
        trial(zstarts(l):zends(l)) = 0; %this eliminates interblink regions that are too short
        htrial(zstarts(l):zends(l)) = 0; %otherwise problems arise latter in program
    end
    
    t2 = zeros(1,length(zends)); %preload t2 variable
    t3 = zeros(1,length(zends)); %preload t3 variable
    
    for j = 1:length(zends) %this loop determines t2 and t3 points
        
        z1 = zstarts(j); %load small segment of htrial before first zero into wtrial
        if z1 <= bwindow
            wtrial = htrial(1:z1); %for if the first zero is too close to the beginning of htrial
        else
            wtrial = htrial(z1-bwindow:z1);
        end
        
        wt2 = find(diff(wtrial) <= -th1,1,'first'); %find location of first point below velocity threshold
        if isempty(wt2) %find t2
            t2(j) = z1; %t2 when wtrial is all zeros or point can't be found (missing data, not blink)
        else
            t2(j) = z1 - (length(wtrial)-wt2); %t2 when a point can be found
        end
        
        z2 = zends(j); %load a small segment of htrial after last zero into wtrial
        if z2 > length(htrial) - bwindow
            wtrial = htrial(z2:end); %for if last zero is too close to end of htrial
        else
            wtrial = htrial(z2:z2+bwindow);
        end
        
        wt3 = find(diff(wtrial) >= th2,1,'last'); %find location of last point above velocity threshold 
        if isempty(wt3)
            t3(j) = z2; %t3 when wtrial is all zeros or point can't be found (missing data, not blink)
        else
            t3(j) = z2 + wt3; %t3 when a point can be found
        end
        
        trial(t2(j)+1:t3(j)-1) = 0; %put zeros between blink onset and offset
        %cleans data so blink affected points arent chosen as t1 and t4
    end
    
    for k = length(t3)-1:-1:1 %loop backwards through chosen time points
        if t3(k) > t2(k+1) %check if any regions overlap
            t3(k) = []; %if overlap, remove relevant start and end point
            t2(k+1) = []; %basically 1 large blink region
        end
    end
    
    for j = 1:length(t2) %this loop does interpolations with defined t2 and t3 points
        
        if t2(j) < intbound || t3(j) > length(trial)-intbound %if blink is too close to trial boundaries, just put nans into it
            trial(t2(j):t3(j)) = nan;
        else
        
            t1 = t2(j) - (t3(j)-t2(j)); %find t1 
            if t2(j)-t1 > betblink %set limit on how far away t1 can be from t2
                t1 = t2(j) - betblink;
            end
            if t1 < 1 %prevent program from choosing points out of trial bounds
                t1 = 1;
            end
            x = t2(j)-t1; %counter variable
            while trial(t1) == 0 || isnan(trial(t1)) %this loop ensures trial ~= 0 or nan at chosen t1 point
                x = x-1;
                t1 = t2(j) - x; %distance between t1 and t2 shortened until nonzero point found
            end

            t4 = t3(j) + (t3(j) - t2(j)); %find t4
            if t4-t3(j) > betblink %set limit
                t4 = t3(j) + betblink;
            end
            if t4 > length(trial) %prevent program from choosing points out of trial bounds
                t4 = length(trial);
            end
            x = t4-t3(j); %counter variable
            while trial(t4) == 0 || isnan(trial(t4))  %ensures trial ~= 0 or nan at t4
                x = x-1;
                t4 = t3(j) + x; %distance between t3 and t4 shortened until nonzero found
            end
            
            if t1 ~= t2(j) && t3(j) ~= t4 %interp if all points are distinct
                trial(t2(j):t3(j)) = spline([t1 t2(j) t3(j) t4],[trial(t1) trial(t2(j)) trial(t3(j)) trial(t4)],t2(j):t3(j));
            elseif t1 == t2(j) && t3(j) ~= t4 %interp if t1 = t2
                trial(t2(j):t3(j)) = spline([t2(j) t3(j) t4],[trial(t2(j)) trial(t3(j)) trial(t4)],t2(j):t3(j));
            elseif t1 ~= t2(j) && t3(j) == t4 %interp if t3 = t4
                trial(t2(j):t3(j)) = spline([t1 t2(j) t3(j)],[trial(t1) trial(t2(j)) trial(t3(j))],t2(j):t3(j));
            elseif t1 == t2(j) && t3(j) == t4 %interp if t1=t2 and t3=t4
                trial(t2(j):t3(j)) = spline([t2(j) t3(j)],[trial(t2(j)) trial(t3(j))],t2(j):t3(j));
            end
            
        end
        
    end
    
end

output = trial; %trial with blinks interpolated outputed