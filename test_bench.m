function test_bench(chordspath)
% function test_bench(chordspath)
%
%   Marco Merlin Copyright (C) 2015, 
%   mail: marcomerli @ gmail.com
%
% Test bench for chordetect function: just loop over all .wav files
% in a folder, and verify whether filename matches "guessed" chord.

if nargin < 1 || isempty(chordspath)
    chordspath = './chords/';
    % chordspath = './chords7/';
end

flist = readdir(chordspath);
passcount = 0;
failcount = 0;

for idx = 1:length(flist) 
	flist{idx};
	[dire,fname,ext]=fileparts(flist{idx});

	if strcmp(ext,'.wav')
		[chord,rel] = chordetector([chordspath flist{idx}],0);
		if strcmp(chord,fname)
			pass = 'PASS'; passcount = passcount+1;
		else
			pass = 'FAIL'; failcount = failcount+1;
        	% disp(['idx: ' sprintf('%d ',idx) 'file: ' fname ' chord: ' chord ' ' pass]);
		end
		disp(['idx: ' sprintf('%d, ',idx) 'file: ' fname ', chord: ' chord ', reliability: ' sprintf('%2.0f, ',rel*100) pass]);
	end
end

disp(sprintf('passcount: %d, failcount: %d, tests: %d, passrate: %3.0f pct', passcount, failcount, passcount+failcount, round(passcount/(passcount+failcount) * 100)));

end
