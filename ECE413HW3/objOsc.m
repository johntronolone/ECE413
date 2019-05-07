classdef objOsc < matlab.System
    % untitled2 Add summary here
    %
    % This template includes the minimum set of functions required
    % to define a System object with discrete state.

    % Public, tunable properties
    properties
        % Defaults
        note                        = objNote;
        oscConfig                   = confOsc;
        constants                   = confConstants;
        lastOutput = 0;

    end

    % Pre-computed constants
    properties(Access = private)
        % Private members
        currentTime;
        EnvGen                = objEnv;
    end
    
    methods
        function obj = objOsc(varargin)
            %Constructor
            if nargin > 0
                setProperties(obj,nargin,varargin{:},'note','oscConfig','constants');
                
                tmpEnv=confEnv(obj.note.startTime,obj.note.endTime,...
                    obj.oscConfig.oscAmpEnv.AttackTime,...
                    obj.oscConfig.oscAmpEnv.DecayTime,...
                    obj.oscConfig.oscAmpEnv.SustainLevel,...
                    obj.oscConfig.oscAmpEnv.ReleaseTime);
                obj.EnvGen=objEnv(tmpEnv,obj.constants);
            end
        end
    end

    methods(Access = protected)
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            
            % Reset the time function
            obj.currentTime=0;
        end

        
        function audio = stepImpl(obj)
%             obj.EnvGen.StartPoint=obj.note.startTime;   % set the end point again in case it has changed
%             obj.EnvGen.ReleasePoint=obj.note.endTime;   % set the end point again in case it has changed
            
            timeVec=(obj.currentTime+(0:(1/obj.constants.SamplingRate):((obj.constants.BufferSize-1)/obj.constants.SamplingRate))).';
      
            %mask = obj.EnvGen.advance;

            mask = step(obj.EnvGen);
            
            if isempty(mask)
                audio=[];
            else
                if all (mask == 0)
                    audio = zeros(obj.constants.BufferSize,1);
                else
                    switch(obj.note.instrument)
                        case {'Additive'}
                            
                            amplitudes = [1 1/2 1/4 1/8 0 0 0 0 0 0 0];
                            durations = [repmat((obj.note.endTime-obj.note.startTime), 1, 4) 0 0 0 0 0 0 0];
                            freqmults = [1 2 3 4 0 0 0 0 0 0 0];
                            freqadds = [0 0 0 0 0 0 0 0 0 0 0];

                            % initialize matrix for each timbre frequency
                            dur = length(timeVec);
                            timbre_mat = zeros(length(amplitudes), dur);
                            
                            for j=1:4%length(1)
                                timbre_mat(j,:) = amplitudes(j).*sin(2*pi*(obj.note.frequency*freqmults(j)+freqadds(j))*timeVec);                                
                            end
                            
                            
                            audio = (sum(timbre_mat, 1)/2)'.*mask(:);
                            
                        case {'Subtractive'}
                            % computationally quicker than using square()
                            squarewave = obj.note.amplitude*(2*(mod(timeVec, 1/obj.note.frequency) < 1/obj.note.frequency/2)-1);
                            
                            passband_width = 0.2;

                            eT = obj.note.endTime;
                            sR = 44100;
                            
                            % duration of note in samples
                            note_dur = obj.note.total_duration;
                            
                            % vector of decreasing cutoff frequency values
                            % fc is based on current time and note time
                            fc = zeros(1, 882);

                            if (eT > floor(obj.currentTime + 882/sR))
                                % enough length to fill entire fc
                                startPointIdx = floor((obj.currentTime-obj.note.startTime)*sR)+1+882;

                                if (startPointIdx < 1)
                                    startPointIdx = 1;
                                end
                                fc = obj.note.fc_full(startPointIdx:(startPointIdx+882-1));
                            else 
                                % fc just to the end
                                firstIdx = nnz(timeVec <= eT);
                                fc(1:firstIdx) = obj.note.fc_full((end-firstIdx+1-882):end-882);
                            end
                            
                            % filter coefficients (update for each sample)
                            envelope = sin((2*pi*fc(1))/note_dur);

                            % intialize state varialbes
                            output = zeros(882,1);
                            feedback = squarewave(1);
                            oldDataPoint = obj.lastOutput;
                            
                            if (oldDataPoint == 0)
                                % first sample of note
                                output(1) = envelope*feedback;
                            else
                                % already playing note (retrieve prev data
                                % point to filter)
                                feedback = feedback - passband_width*oldDataPoint;
                                output(1) = envelope*feedback + oldDataPoint;
                            end
                            
                            for jj = 2:882
                                
                                if (fc(jj) > 0)
                                    output(jj) =  sin(2*pi*(fc(jj))/note_dur)*(squarewave(jj) - passband_width*output(jj-1)) + output(jj-1);
                                end   
                                
                            end
                            
                            obj.lastOutput = output(end);
     
                            audio = output.*mask(:)/10;
                            
                        case {'FM'}
                            % initialize vector for frequency modulation envelope
                            dur = length(timeVec);
                            
                            % simplified modulation index vector
                            freqmod = ones(1, dur);
                  
                            audio = sin(2*pi*obj.note.frequency*timeVec+freqmod'.*sin(2*pi*obj.note.frequency.*timeVec))/5.*mask(:);
                                  
                        case {'Waveshaper'}
                            
                            % sinewave at note frequency
                            sinewave = sin(2*pi*obj.note.frequency*timeVec);

                            dur = length(timeVec);
                            % Evaluate chebyshev first kind polys
                            sinewave_mat(1,:) = ones(1, dur);
                            sinewave_mat(2,:) = sinewave;
                            sinewave_mat(3,:) = 2*sinewave.^2 + 1;
                            sinewave_mat(4,:) = 4*sinewave.^3 - 3*sinewave;
                            sinewave_mat(5,:) = 8*sinewave.^4 - 8*sinewave.^2 + 1;
                            sinewave_mat(6,:) = 16*sinewave.^5 - 20*sinewave.^3 + 5*sinewave;
                            sinewave_mat(7,:) = 32*sinewave.^6 - 48*sinewave.^4 + 18*sinewave.^2 - 1;

                            % sum chevyshev polys and store this note of the chord 
                            % in a matrix
                            audio = (sum(sinewave_mat, 1)/7)'/5.*mask(:);
                    
                        otherwise
                            audio=obj.note.amplitude.*mask(:).*square(2*pi*obj.note.frequency*timeVec);
                            length(audio);
                    end
                end
            end
            obj.currentTime=obj.currentTime+(obj.constants.BufferSize/obj.constants.SamplingRate);      % Advance the internal time
            %obj.note.currentNoteTime = obj.currentTime;

        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            % Reset the time function
            obj.currentTime=0;
        end
    end
end
