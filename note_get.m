joe_dir = "joes_test_data";
[joe_audio,joe_files] = loadWavs(joe_dir);
audio = joe_audio{3};

w = notewindows(audio);

figure(1)
plot(audio)
hold on
stem(w,ones(size(w)))
hold off

figure(2)
%[yupper,ylower] = envelope(audio,500,'peak');
[yupper,ylower] = envelope(audio,500,'rms');
t = [1:length(audio)];
plot(t,yupper,t,smoothdata(yupper,1,'movmean',750))
yupper = smoothdata(yupper,1,'movmean',750);

figure(3)
w_env = [round(notewindows(yupper)), length(audio)];
plot(t,audio,t,yupper)
hold on
stem(w_env,ones(size(w_env)))
hold off

% for i = 1:length(w_env)-1
%     sound(audio(w_env(i):w_env(i+1)),44.1e3)
%     pause;
% end

function divs = noteparse(data)
    len = length(data);
    
    %let's find a threshold value so we know when a note starts/stops
    threshup = .35 * max(data);  % 20% of the maximum value
    %threshdown = .12 * max(data);
    threshdown = 0.275; %function of local max

    quiet=1;  % a flag so we know if we're noisy or quiet right now
    j=1;
    local_max = 0;
    frame = 150;
    for i=frame+1:len-frame
       if quiet == 1  % we're trying find the begining of a note
          if (max(abs(data(i-frame:i+frame))) > threshup)
             quiet = 0;  % we found it
             divs(j) = i;  %record this division point
             j=j+1;
             local_max = max(abs(data(i-frame:i+frame)));
          end
       else % we're in a note
          if max(abs(data(i-frame:i+frame))) > local_max % if we're still increasing, update peak
              local_max = max(abs(data(i-frame:i+frame)));
          end
          if max(abs(data(i-frame:i+frame))) < threshdown*local_max %if we're decreasing, end the note
          %if (max(abs(data(i-50:i+50))) < threshdown)
             quiet = 1;  %note's over
             local_max = 0;
             divs(j) = i;
             j=j+1;
          end
       end
    end
end

function w = notewindows(data)
    
    divs = noteparse(data);
    
    d2(1) = 0;
    
    for i=1:length(divs)
        d2(i+1)=divs(i);
    end
    
    d2(length(divs)+2) = length(data);
    
    for i=1:length(d2)/2
        w(i) = (d2(2*i-1) + d2(2*i))/2;
    end
end

function [wavs, files] = loadWavs(directory)

    files = string(ls(directory+"\*.wav"));
    wavs = {};
    for i = 1:length(files)
        wavs{i} = audioread(directory+"\"+files(i));
    end

end