function [soundOut] = create_chord( chordType,temperament, root, constants )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION
%    [ soundOut ] = create_scale( chordType,temperament, root, constants )
% 
% This function creates the sound output given the desired type of chord
%
% OUTPUTS
%   soundOut = The output sound vector
%
% INPUTS
%   chordType = Must support 'Major' and 'Minor' at a minimum
%   temperament = may be 'just' or 'equal'
%   root = The Base frequeny (expressed as a letter followed by a number
%       where A4 = 440 (the A above middle C)
%       See http://en.wikipedia.org/wiki/Piano_key_frequencies for note
%       numbers and frequencies
%   constants = the constants structure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define C1 -> B1 frequencies from wikipedia frequencies

% C1 to B1
freqs1 = [32.70320 34.64783 36.70810 38.89087 41.20344 43.65353 46.24930 48.99943 51.91309 55.00000 58.27047 61.73541];

just_ratios = [1; 16/15; 9/8; 6/5; 5/4; 4/3; 25/18; 3/2; 8/5; 5/3; 7/4; 15/8; 2];

equal_ratios = [1; 2^(1/12); 2^(2/12); 2^(3/12); 2^(4/12); 2^(5/12); 2^(6/12); 2^(7/12); 2^(8/12); 2^(9/12); 2^(10/12); 2^(11/12); 2];



switch chordType
    case {'Major','major','M','Maj','maj'}
        ratio_idx = [1, 5, 8];
    case {'Minor','minor','m','Min','min'}
        ratio_idx = [1, 4, 8];
    case {'Power','power','pow'}
        ratio_idx = [1, 8];
    case {'Sus2','sus2','s2','S2'}
        ratio_idx = [1, 3, 8];
    case {'Sus4','sus4','s4','S4'}
        ratio_idx = [1, 7, 8];
    case {'Dom7','dom7','Dominant7', '7'}
        ratio_idx = [1, 5, 8, 11];
    case {'Min7','min7','Minor7', 'm7'}
        ratio_idx = [1, 4, 8, 11];
    otherwise
        error('Inproper chord specified');
end

switch temperament
    case {'just','Just'}
        ratios = just_ratios(ratio_idx);
    case {'equal','Equal'}
        ratios = equal_ratios(ratio_idx);

    otherwise
        error('Inproper temperament specified')
end


switch length(root)
    case{2}  % non-accidental scales
        switch(root(1))
            case{'C'}
                fundFreq_toMult = freqs1(1);
            case{'D'}
                fundFreq_toMult = freqs1(3);
            case{'E'}
                fundFreq_toMult = freqs1(5);
            case{'F'}
                fundFreq_toMult = freqs1(6);
            case{'G'}
                fundFreq_toMult = freqs1(8);
            case{'A'}
                fundFreq_toMult = freqs1(10);
            case{'B'}
                fundFreq_toMult = freqs1(12);
            otherwise
                error('Accepted roots: A0, A#0/Bb0, ..., C8')
        end
        
    case{3} % must have specified sharp/flat key
        switch root(2)
            case{'b'}
                switch root(1)
                    case{'D'}
                        fundFreq_toMult = freqs1(2);
                    case{'E'}
                        fundFreq_toMult = freqs1(4);
                    case{'G'}
                        fundFreq_toMult = freqs1(7);
                    case{'A'}
                        fundFreq_toMult = freqs1(9);
                    case{'B'}
                        fundFreq_toMult = freqs1(11);
                    otherwise
                    error('Accepted roots: A0, A#0/Bb0, ..., C8')
                end
                
            case{'#'}
                switch root(1)
                    case{'C'}
                        fundFreq_toMult = freqs1(2);
                    case{'D'}
                        fundFreq_toMult = freqs1(4);
                    case{'F'}
                        fundFreq_toMult = freqs1(7);
                    case{'G'}
                        fundFreq_toMult = freqs1(9);
                    case{'A'}
                        fundFreq_toMult = freqs1(11);
                    otherwise
                    error('Accepted roots: A0, A#0/Bb0, ..., C8')
                end
                
            otherwise
                error('Accepted roots: A0, A#0/Bb0, ..., C8')
                
        end
        
    otherwise
        error('Accepted roots: A0, A#0/Bb0, ..., C8')
        
end

if root(end) == '0'
    fundFreq = fundFreq_toMult/2;
else
    fundFreq = fundFreq_toMult*(2.^(str2double(root(end))-1));


% create frequency vector

chord_freqs = fundFreq*ratios;

% make time vector to use in generating sinwave, based on fs

seconds = 2; 
t = 0:1/constants.fs:seconds-1/constants.fs;

% create signals as row vectors
x_mat = sin(2*pi*t.*chord_freqs);

% sum rows together and divide by number of signals
x = sum(x_mat)./length(ratio_idx);

% create attack/delay envelope

soundOut = x;

% Complete with chord vectors

% similar to create scale, except use differnet `ratio_idx` and sum instead
% of concat

end
