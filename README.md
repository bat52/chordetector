# chordetector
Chordetector is an algorithm to recognize a chord from a musical sample. It performs a spectral analysis on the sample, folds the audible spectrum in a single octave, then uses a simple neural network to find what is the most likely chord.

Chordetector is a reference implementation written with GNU octave, in Matlab syntax. 

The algorithm is able to distinguish between different simple and complex chord patterns, including single-pitched notes (ie tuner function), power chords, major, minor, diminished, and 7th. A reliability estimate (rel) of the guess is reported as well. The algorithm is designed to report rel = 1 for a perfect chord, and -12 in the unlikely case of a "completely wrong" chord. Based on initial benchmarks, estimates with rel > 0 should be pretty reliable.

As far as I know this is an original implementation, making use of fft, data binning to match fft components into discrete notes pitches, octave-folding, and a manually-built neural network, to estimate the best-matching chord pattern.

In the current implementation, the neural network does not require any training as it is only based on "a priori" guess of the chord patterns: this approach will work best with "pure sinewave" instruments, and will probably perform poorly with instruments with rich harmonic sounds (i.e. a distorted guitar, I guess).

The algorithm was tested using freely available chord packs (in .wav format), like those available here:
http://ibeat.org/piano-chords-free/
http://www.freesound.org/people/danglada/packs/1011/

For the test_bench script.m to work properly, the chord files should be named after the chord and pattern name (for instance Amin.wav).

Here are the currently supported pattern names:
'', ... (none = single-pitched note)
'pow',.. (power chord, no 3rd)
'maj',... 
'2',...
'4',...
'min',...
'dim',...
'pow7',...
'maj7',...
'min7',...

A puredata implementation of the algorithm is available at http://patchstorage.com/chordetector_pd/.
And one suitable for mobile (using MobMuPlat) here http://patchstorage.com/chordetector_pd_mobile/.

The concept was presented at the "Monaco Startup Weekend 2015"  ( http://www.up.co/communities/monaco/monaco/startup-weekend/5469 ) with the name of JamAlong, project, even though following the rules of the competition, none of this code was used in that occasion, and the prototype was developed using Max/MSP (https://cycling74.com/products/max/). Here the slides that were presented in that occasion: 
http://www.slideshare.net/MarcoMerlin/jamalong-edited-short-47964215.
