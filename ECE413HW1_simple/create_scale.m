function [soundOut] = create_scale( scaleType,temperament, root, constants )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION
%    [ soundOut ] = create_scale( scaleType,temperament, root, constants )
% 
% This function creates the sound output given the desired type of scale
%
% OUTPUTS
%   soundOut = The output sound vector
%
% INPUTS
%   scaleType = Must support 'Major' and 'Minor' at a minimum
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
% TODO: Add all relavant constants 


% Define A0 -> C8 frequencies from wikipedia frequencies

% A0 to B0
freqs0 = [27.50000 29.13524 30.86771];

% C1 to B1
freqs1 = [32.70320 34.64783 36.70810 38.89087 41.20344 43.65353 46.24930 48.99943 51.91309 55.00000 58.27047 61.73541];

just_ratios = [1; 16/15; 9/8; 6/5; 5/4; 4/3; 25/18; 3/2; 8/5; 5/3; 7/4; 15/8; 2];

equal_ratios = [1; 2^(1/12); 2^(2/12); 2^(3/12); 2^(4/12); 2^(5/12); 2^(6/12); 2^(7/12); 2^(8/12); 2^(9/12); 2^(10/12); 2^(11/12); 2];


switch scaleType
    case {'Major','major','M','Maj','maj'}
        ratio_idx = [1, 3, 5, 6, 8, 10, 12, 13, 12, 10, 8, 6, 5, 3, 1];
    
    case {'Minor','minor','m','Min','min'}
        ratio_idx = [1, 3, 4, 6, 8, 9, 11, 13, 11, 9, 8, 6, 4, 3, 1];
        
    case {'Harmonic', 'harmonic', 'Harm', 'harm'}
        ratio_idx = [1, 3, 4, 6, 8, 9, 12, 13, 12, 9, 8, 6, 4, 3, 1];
        
    case {'Melodic', 'melodic', 'Mel', 'mel'}
        ratio_idx = [1, 3, 4, 6, 8, 10, 12, 13, 11, 9, 8, 6, 4, 3, 1];
        
    otherwise
        error('Accepted scales: major, minor, harmonic, melodic');
end

switch temperament
    case {'just','Just'}
        % TODO: Pull the Just tempered ratios based on the pattern from the scales
        ratios = just_ratios(ratio_idx);
        
    case {'equal','Equal'}
        % TODO: Pull the equal tempered ratios based on the pattern from the scales
        ratios = equal_ratios(ratio_idx);
        
    otherwise
        error('Accepted temperaments: just, equal')
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

scale_freqs = fundFreq*ratios;

% make time vector to use in generating sinwave, based on fs

seconds = 0.5; 
t = 0:1/constants.fs:seconds-1/constants.fs;

% create signals as column vectors
x_mat = sin(2*pi*t'.*scale_freqs');

% arrange signals into single row vector
x = reshape(x_mat, 1, []);

% create attack/delay envelope

soundOut = x;

end
