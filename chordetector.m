function [chord, rel, elapsed_time, sample_time, nfft2] = chordetector(fname, plot_en)
% function [chord, rel, elapsed_time, sample_time, nfft2] = chordetector(fname, plot_en)
%
%   Marco Merlin Copyright (C) 2015, 
%   mail: marcomerli @ gmail.com
%
% This script is able to process a short audio file in .wav format, and "guess" the
% musical chord which better matches the sound. NB: only the first nfft2 (return
% parameter) samples are actually analyzed.
% 
% The algorithm is able to distinguish between different simple and complex 
% chord patterns, including single-pitched notes (ie tuner function), 
% power chords, major, minor, diminished, and 7th.
%
% A reliability estimate (rel) of the guess is reported as well. The algorithm
% is designed to report rel = 1 for a perfect chord, and -12 in the unlikely case
% of a "completely wrong" chord. Based on initial benchmarks, estimates with
% rel > 0 should be pretty reliable.
% 
% As far as I know this is an original implementation, making use of fft, 
% data binning to match fft components into discrete notes pitches,
% octave-folding, and a manually-built neural network, to estimate the best-matching
% chord pattern.
%  
% input:
%       -- fname: file name of input
%       -- plot_en: enable debug plotting
% output:
%       -- chord: estimated chord name
%       -- rel  : reliability of estimation (1 = 100%, -inf = 0%)
%       -- elapsed_time: processing time
%       -- sample_time: time duration of nfft2 audio samples used for processing
%       -- nfft: nfft/2 half number of points used for audio analysis

%% input parsing
if nargin < 1 || isempty(fname)
	fname = "./chords/Amin.wav";
end
if nargin < 2 || isempty(plot_en)
	plot_en = 1;
end

close all

%% load audio sample
%fname
%[x, fs] = auload(file_in_loadpath(fname));
[x, fs] = auload(fname);
%fs
%figure(1);
%auplot(x,fs);

%% what's the needed frequency resolution/minimum number of samples?
% starting from central A0 = 440Hz, we can assume the lowest note to resolute for being A-3 = 55Hz, therefore A#-3 = 55 * sqrt(2,1/12) = 58.27;
% min_freq_res = A#-3 - A-3 = 3.27 Hz
% min_freq_res = 3.27;
min_freq_res = 1; % this just seems to work for all chords in my bunch
% fs/(2*nfft) < min_freq_res
nfft = ceil(fs/2/min_freq_res);

%% merge channels, if stereo
[r,c] = size(x);
if c > 1
	x = x(:,1)+x(:,2);
else
	x = x(:,1);
end

%% fft
	#xfft = fftshift(fft(x, nfft));
	#nfft = length(xfft);
	#freq = [-nfft/2:(nfft-1)/2]*fs/nfft;
	#figure(2);
	#loglog(freq,abs(xfft)); hold on; grid on;

tic;
% discard negative freqs
xfft2 = fft(x, nfft); 
sample_duration = nfft/fs;
xfft2 = xfft2(1:ceil(nfft/2));
nfft2 = length(xfft2);
freq2 = [1:(nfft2)]*fs/2/nfft2;

if plot_en
    figure(22);
    loglog(freq2,abs(xfft2)); hold on; grid on;
end

%% apply psycho-acoustic model ??

%% pitch binning
%% pitch = 69 + 12*log2(f/440)
pitch = 69 + 12*log2(abs(freq2)/440);
pitch_bin = round(pitch);
pitch_bin_fold = rem(pitch_bin,12);

%% octave folding
for idx = 0:11
	tf = ismember(pitch_bin_fold, [idx]);
	% xlev(idx+1)   = (tf * abs(xfft2)) / sum(tf); % average freqs that fall on the same pitch
    xlev(idx+1)   = (tf * abs(xfft2)); % probably averaging is useless
end

%% normalization: to easen reliability calculation
xlev = xlev/max(xlev);

%% noise gate: assume noisefloor = mean, and remove lower harmonics
noise_idx = find(xlev < mean(xlev));
xlev(noise_idx) = zeros(length(noise_idx), 1);

%% plot pitch histogram
labels = {'C','C#','D','D#','E','F','F#','G','G#','A','A#','B'};
if plot_en
    figure(3);
    bar(xlev);
    set(gca,'XTick',[1:12]);
    set(gca,'xticklabel',labels);
end

%% neural network for chord detection

chord_patterns = { ...
[1],     ... % single-pitched note
[1 8],   ... % pow
[1 5 8], ... % maj
[1 3 8], ... % 2
[1 6 8], ... % 4
[1 4 8], ... % min
[1 4 7], ... % dim
[1 8 11], ... % pow7
[1 5 8 11], ... % maj7
[1 4 8 11], ... % min7
%[1 3 5 8 11], ... % maj79
%[1 3 4 8 11], ... % min79
};

chord_names = {...
''   ,... 
'pow',...
'maj',...
'2',...
'4',...
'min',...
'dim',...
'pow7',...
'maj7',...
'min7',...
%'maj79',...
%'min79',...
};

labels_tmp = labels;
for pitch_idx = 1:12
	for idx = 1:length(chord_patterns)
		% chord_lev(idx, pitch_idx) = sum(xlev(chord_patterns{idx})) / length(chord_patterns{idx});
        % chord_lev(idx, pitch_idx) = sum(xlev(chord_patterns{idx}));
        chord_lev(idx, pitch_idx) = xlev * pattern2weights(chord_patterns{idx});
	end
	
#	if pitch_idx == 10
#		figure(3);
#		bar(xlev);	
#		set(gca,'XTick',[1:12]);
#		set(gca,'xticklabel',labels_tmp);
#	end

	% rotate circular buffer xlev
	xlev       = [xlev(2:12) xlev(1)];
	labels_tmp = {labels_tmp{2:12}, labels_tmp{1}};
end

[m  , chord_idxs]  = max(chord_lev); % per-pitch chord array
[rel, chord_pitch] = max(m);         % 

chord=[labels{chord_pitch} chord_names{chord_idxs(chord_pitch)}];
elapsed_time = toc;

if plot_en
    figure(3);
    titlestr = [chord sprintf(', Rel: %d pct',round(rel*100))];
    title(titlestr);
end

%% markov chain for phrase detection ?

end

%% build neural network weights, based on chord pattern:
% "right" notes add on top of each other
% "wrong" notes subtract
function weights=pattern2weights(pattern)
    plusses  = zeros(12,1);
    minusses = ones(12,1);
    order = length(pattern);

    plusses(pattern)  = ones(order,1);
    minusses(pattern) = zeros(order,1);

    weights = plusses/order - minusses;
end
