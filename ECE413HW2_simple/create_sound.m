function sound = create_sound(instrument,notes,constants)
    
    % Define A0 -> C8 frequencies from wikipedia frequencies

    % A0 to B0
    freqs0 = [27.50000 29.13524 30.86771];

    % C1 to B1
    freqs1 = [32.70320 34.64783 36.70810 38.89087 41.20344 43.65353 46.24930 48.99943 51.91309 55.00000 58.27047 61.73541];

    just_ratios = [1; 16/15; 9/8; 6/5; 5/4; 4/3; 25/18; 3/2; 8/5; 5/3; 7/4; 15/8; 2];

    equal_ratios = [1; 2^(1/12); 2^(2/12); 2^(3/12); 2^(4/12); 2^(5/12); 2^(6/12); 2^(7/12); 2^(8/12); 2^(9/12); 2^(10/12); 2^(11/12); 2];
    
    % select chord notes
    switch instrument.mode
        case {'Major', 'major'}
            ratio_idx = [1, 5, 8];
        case {'Minor', 'minor'}
            ratio_idx = [1, 4, 8];
        case {'Root Note', 'root note', 'Root note', 'root_note', 'Root_note'}
            ratio_idx = 1;
        otherwise
            error('Accepted chord modes: major, minor, root_note')
    end
            
    % select temperament
    switch instrument.temperament
        case {'just','Just'}
            ratios = just_ratios(ratio_idx);
        
        case {'equal','Equal'}
            ratios = equal_ratios(ratio_idx);
        
        otherwise
            error('Accepted temperaments: just, equal')
    end
   
    % initialize matrix for output
    sound_mat = zeros(length(notes), notes{1}.duration);
    
    % calculate timbre for each note
    for i=1:length(notes)
        
        root = notes{i}.note;
        
        % determine fundamental frequency from note argument
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
       
        end
        
        chord_freqs = fundFreq*ratios;
        
        % time vector
        t = (1:notes{i}.duration)/constants.fs;
        
        chord_mat = zeros(length(chord_freqs), notes{i}.duration);
        
        % synthesize timbre for each note in the chord
        for k = 1:length(chord_freqs)
                    
            switch(instrument.sound)
                case{'Additive'}
                    
                    % a.) create bell from figure 4.28
                    amplitudes = [1, 1.67, 1, 1.8, 2.67, 1.67, 1.33, 1.33, 1, 1.33];
                    durations = [1, .9, .65, .55, .325, .35, .25, .2, .15, .1, .075];
                    freqmults = [0.56 0.56 0.92 0.92 1.19 1.7 2 2.74 3 3.76 4.07];
                    freqadds = [0 1 0 1.7 0 0 0 0 0 0 0];

                    % initialize matrix for each timbre frequency
                    timbre_mat = zeros(length(amplitudes), notes{i}.duration);

                    for j=1:length(amplitudes)
                        nsamp = floor(notes{i}.duration*durations(j));
                        timbre_mat(j,1:nsamp) = (exp(-t(1:nsamp)/durations(j))).*amplitudes(j).*sin(2*pi*(chord_freqs(k)*freqmults(j)+freqadds(j))*t(1:nsamp));
                    end
                    
                    % sum timbre and store this note of the chord in a
                    % matrix
                    chord_mat(k,:) = sum(timbre_mat, 1);

                    
                case{'Subtractive'}

                    % generate square wave
                    squarewave = square(2*pi*chord_freqs(k)*t);

                    % initial cutoff frequency for filter
                    fc_init = 10000;
                    % final cutoff frequency for filter
                    fc_final = 500;
                    
                    passband_width = 0.1;
                    
                    % vector of decreasing cutoff frequency values
                    fc = linspace(fc_init, fc_final, notes{i}.duration);
                    
                    % filter coefficients (update for each sample)
                    envelope = 2*sin((pi*fc(1))/constants.fs);

                    % intialize state varialbes
                    feedback=zeros(size(squarewave));
                    output=zeros(size(squarewave));

                    % first sample
                    feedback(1) = squarewave(1);
                    output(1) = envelope*feedback(1);

                    % difference equation
                    for j=2:length(squarewave)
                        
                        feedback(j) = squarewave(j) - passband_width*output(j-1);
                        output(j) = envelope*feedback(j) + output(j-1);
                        
                        envelope = sin((2*pi*fc(j))/notes{i}.duration);
                    end

                    % normalize
                    max_output = max(abs(output));
                    chord_mat(k,:) = output/max_output;

                case{'FM'}

                    % initialize vector for frequency modulation envelope
                    freqmod = zeros(1, notes{i}.duration);

                    % piece-wise define function for brass-like timbre
                    % based on Jerse Figure 5.9 (d), with some modification
                    % to make it sound better
                    freqmod(1:floor(notes{i}.duration)/3) = 2\t(1:floor(notes{i}.duration)/3);
                    freqmod(floor(notes{i}.duration/3+1:floor(notes{i}.duration*5/6))) = 12/18-t(1:floor(notes{i}.duration)/2)/20;
                    freqmod(floor(notes{i}.duration)*5/6+1:end) = 10.25/18-(t(1:floor(notes{i}.duration)/6))*2;
                    freqmod(freqmod < 0) = 0;

                    % evaluate and store this note of the chord in a matrix
                    chord_mat(k,:) = freqmod.*sin(2*pi*chord_freqs(k)*t+freqmod.*sin(2*pi*chord_freqs(k)*t));


                case{'Waveshaper'}

                    % sinewave at note frequency
                    sinewave = sin(2*pi*chord_freqs(k)*t);

                    % Evaluate chebyshev first kind polys
                    sinewave_mat(1,:) = ones(1, notes{i}.duration);
                    sinewave_mat(2,:) = sinewave;
                    sinewave_mat(3,:) = 2*sinewave.^2 + 1;
                    sinewave_mat(4,:) = 4*sinewave.^3 - 3*sinewave;
                    sinewave_mat(5,:) = 8*sinewave.^4 - 8*sinewave.^2 + 1;
                    sinewave_mat(6,:) = 16*sinewave.^5 - 20*sinewave.^3 + 5*sinewave;
                    sinewave_mat(7,:) = 32*sinewave.^6 - 48*sinewave.^4 + 18*sinewave.^2 - 1;

                    % sum chevyshev polys and store this note of the chord 
                    % in a matrix
                    chord_mat(k,:) = sum(sinewave_mat, 1);
                    
                    
            end
        end
        
        sound_mat(i, :) = sum(chord_mat, 1)/length(chord_freqs);
 
        remove_pop = (1:1000)/147;

        sound_mat(i, 1:1000) = (1-exp(-remove_pop)).*sound_mat(i, 1:1000);
        sound_mat(i, end-1000:end-1) = fliplr((1-exp(-remove_pop))).*sound_mat(i, end-1000:end-1);
        sound_mat(i, end) = 0;

    end
    
    % reshape as single time vector
    sound = reshape(sound_mat', [], 1);
    
end