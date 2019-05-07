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
%         old_data_point = 0;
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
            noteTime=timeVec-obj.note.startTime;
      
            
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
%                             amplitudes = [1, 1.67, 1, 1.8, 2.67, 1.67, 1.33, 1.33, 1, 1.33];
%                             durations = [1, .9, .65, .55, .325, .35, .25, .2, .15, .1, .075];
%                             freqmults = [0.56 0.56 0.92 0.92 1.19 1.7 2 2.74 3 3.76 4.07];
%                             freqadds = [0 1 0 1.7 0 0 0 0 0 0 0];
                            
%                             amplitudes = [1 1/2 1/3 1/4 0 0 0 0 0 0 0];
%                             durations = [1 1 1 1 0 0 0 0 0 0 0];
%                             freqmults = [1 2 3 4 0 0 0 0 0 0 0];
%                             freqadds = [0 0 0 0 0 0 0 0 0 0 0];
                            
                            amplitudes = [1 1/2 1/4 1/8 0 0 0 0 0 0 0];
                            durations = [repmat((obj.note.endTime-obj.note.startTime), 1, 4) 0 0 0 0 0 0 0];
                            %durations = [1 1 1 1 0 0 0 0 0 0 0];
                            freqmults = [1 2 3 4 0 0 0 0 0 0 0];
                            freqadds = [0 0 0 0 0 0 0 0 0 0 0];

                            % initialize matrix for each timbre frequency
                            %dur = obj.note.endTime - obj.note.startTime;
                            dur = length(timeVec);
                            timbre_mat = zeros(length(amplitudes), dur);%notes{i}.duration);
                            
                            %noteTime

                            for j=1:4%length(1)
                                %nsamp = floor(notes{i}.duration*durations(j));
                                %nsamp = floor(dur*durations(j));
                                %timbre_mat(j,1:nsamp) = (exp(-t(1:nsamp)/durations(j))).*amplitudes(j).*sin(2*pi*(chord_freqs(k)*freqmults(j)+freqadds(j))*timeVec);%t(1:nsamp));
                                %envelope = 2 - exp(3*noteTime);
                                %envelope(envelope < 0) = 0;
                                %envelope(1:101) = linspace(0,1,101);
                                %timbre_mat(j,:) = envelope.*amplitudes(j).*sin(2*pi*(obj.note.frequency*freqmults(j)+freqadds(j))*timeVec);
                                timbre_mat(j,:) = amplitudes(j).*sin(2*pi*(obj.note.frequency*freqmults(j)+freqadds(j))*timeVec);
                                %timbre_mat(j,:) = ((exp(noteTime/durations(j)))).*amplitudes(j).*sin(2*pi*(obj.note.frequency*freqmults(j)+freqadds(j))*timeVec);
                                
                            end
                            
                            
                            audio = (sum(timbre_mat, 1)/4)'.*mask(:);
                            
                             % add envelope to end of note to prevent
                             % popping
                            %audio(end-81:end) = audio(end-81:end).*(fliplr(1:82)/82)
                            %length(audio(end-81:end))
                            %attenEnd = audio(end-81:end).*(fliplr(1:82)/82)';
                            
                            %audio(end-81:end) = audio(end-81:end).*(fliplr(1:82)/82)
                            %audio(end-81:end) = attenEnd;
                            
                            %0:20
                            
                            %length(audio)
                            
%                             endNum = 20;
%                             for q = 1:endNum
%                                 audio(end-(q-1)) = ((q-1)/endNum);
%                             end
                            
                            %audio(end-100: end) = unAttenAudio(end-100: end)
                            %audio
                            %length(audio)
                        case {'Subtractive'}
                            % generate square wave
                            squarewave = obj.note.amplitude*square(2*pi*obj.note.frequency*timeVec);
                            
                            
                            %noteLengthInSamples = (obj.note.endTime - obj.note.startTime)*obj.constants.SamplingRate-1;

                            

                            passband_width = 0.1;

                            %sT = obj.note.startTime;
%                             timeVec(1);
% 
                            eT = obj.note.endTime;
%                             timeVec(end);
%                             
%                             eT-sT
                            
                            % duration of note in samples
                            %total_dur = (obj.note.endTime - obj.note.startTime)*obj.constants.SamplingRate;
                            buffer_dur = (eT - timeVec(1))*obj.constants.SamplingRate-1;
                            %dur = length(timeVec);
                            %length(timeVec)
                            
                            % initial cutoff frequency for filter
                            %fc_init = 1000;%obj.note.frequency*2;%882*2*pi;%+dur/4;
                            % final cutoff frequency for filter
                            %fc_final = 100;%obj.note.frequency;
                            
                          
                            
                            % vector of decreasing cutoff frequency values
                            % fc is based on current time and note time
                            %fc_full = linspace(fc_init, fc_final, buffer_dur+1);%+1);
                            %fc_full = linspace(fc_init, fc_final, total_dur+1);
                            %fc_full = linspace(fc_init, fc_final, total_dur+obj.constants.BufferSize+1);
                            
                            fc = zeros(1, length(timeVec));
                            % fc for this buffer
                            %fc = fc_full(find(fc_full)
                            %if (obj.note.endTime > (obj.currentTime + (obj.constants.BufferSize*1.5+1)/obj.constants.SamplingRate ))
                            if (eT > obj.currentTime + length(timeVec)/obj.constants.SamplingRate)
                                
                                %noteTime
                                %startPointIdx = (length(timeVec) < eT)*obj.constants.SamplingRate + 1
                                %startPointIdx = 1;
                                
                                %if all(noteTime < timeVec)
                                startPointIdx = floor(noteTime(1)*obj.constants.SamplingRate) + 1;
                                if (startPointIdx < 1)
                                    startPointIdx = 1;
                                end
                                %end
                                
%                                 if timeVec(1) < obj.currentTime
%                                     %startPointIdx = (obj.currentTime-timeVec(1))*obj.constants.SamplingRate+1;
%                                     startPointIdx = (timeVec(1))*obj.constants.SamplingRate+1
%                                 end
                                                            
                                %enough length to fill entire fc
%                                 if timeVec(1) > obj.currentTime%obj.note.currentNoteTime
%                                     %reset starting point
%                                     startPointIdx = 1;
%                                     %obj.note.startTime*obj.constants.SamplingRate+1
%                                 else
%                                     %startPointIdx = (obj.note.currentNoteTime-obj.note.startTime)*obj.constants.SamplingRate+1;
%                                     startPointIdx = (obj.currentTime-timeVec(1))*obj.constants.SamplingRate+1;
%                                 end
                                %startPointIdx = (obj.currentTime-obj.note.startTime)*obj.constants.SamplingRate+1;%(obj.currentTime - obj.note.startTime)*obj.constants.SamplingRate+1+0.5*obj.constants.BufferSize;
                                %endPointIdx = startPointIdx + length(timeVec) - 1;
                                %endPointIdx = (obj.currentTime - obj.note.startTime)*obj.constants.SamplingRate+1.5*obj.constants.BufferSize;
                                %indices = floor(startPointIdx):floor(endPointIdx);
                                
                                % for some reason floor will make 1.0000
                                % become 0
%                                 if (indices(1) == 0)
%                                    indices = indices + 1; 
%                                 end
                                
                                %fc(:) = fc_full(indices);
                                
                                %obj.note.fc_full
                                fc = obj.note.fc_full(startPointIdx:(startPointIdx+length(timeVec)-1));
                                %length(fc)
                                %end
                            else 
                                % fc just to the end
                                %firstIndex = (obj.note.currentNoteTime-obj.note.startTime)*obj.constants.SamplingRate+1;%+0.5*obj.constants.BufferSize;
                                %obj.currentTime;
                                %timeVec(1);
                                firstIdx = length(find(timeVec <= obj.note.endTime));
                                %firstIndex = floor((timeVec(1))*obj.constants.SamplingRate)+1%+0.5*obj.constants.BufferSize;
                                
                                %fc(1:length(fc_full(floor(firstIndex):end))) = fc_full(floor(firstIndex):end);
                                %length(fc_full(floor(firstIndex):end));
                                %length(fc_full);
                                
                                
                                %firstIndex
                                %fc(1:((total_dur+1)-floor(firstIndex)+1)) = fc_full(floor(firstIndex):end);
                                %fc(1:length(fc_full(floor(firstIndex):end))) = fc_full(floor(firstIndex):end);
                                %firstIdx
                                %length(fc_full)
                                %length(fc_full) - firstIdx + 1
                                %if(obj.note.fc_full)
                                fc(1:firstIdx) = obj.note.fc_full((end-firstIdx+1):end);
                                %end
                                %fc_full(floor(firstIndex):end)
                                %TODO: THERE IS SOMETHING WRONG WITH THE
                                %ABOVE TWO LINES
                                
                            end
                            
                            
                            
                            
                            % filter coefficients (update for each sample)
                            envelope = sin((2*pi*fc(1))/buffer_dur);%-5*pi/11);%dur);%/obj.constants.SamplingRate);

                            % intialize state varialbes
                            %feedback=zeros(size(squarewave));
                            %output = zeros(size(squarewave));
                            output = zeros(length(timeVec),1);
                            feedback = squarewave(1);
                            
                            
                            %dataPt = t;

%                             if (obj.currentTime == obj.note.startTime)
%                                 % first sample
%                                 feedback(1) = squarewave(1);
%                                 output(1) = envelope*feedback(1);

                            %output(1) = envelope*feedback;
                            if (isempty(obj.note.old_data_point) || obj.note.old_data_point == 0)
                                %dataPt
                                % beginning of new note
                                %feedback = squarewave(1);
                                
                                output(1) = envelope*feedback;
                                %output(1)
                            else
                                % already playing note (retrieve prev. data
                                % point to filter)
                                feedback = feedback - passband_width*obj.note.old_data_point;
                                %envelope*feedback(1) + dataPt
                                output(1) = envelope*feedback + obj.note.old_data_point;
                               
                                %length(dataPt)
                                
                                    
                            end
                            
                            
%                             if (obj.old_data_point > 0)
%                                 if (obj.old_data_point < 0)
%                                 % first sample
%                                     feedback(1) = squarewave(1) - passband_width*obj.old_data_point;
%                                     output(1) = obj.old_data_point
%                                 else
%                                     % first sample
%                                     feedback(1) = squarewave(1);
%                                     output(1) = envelope*feedback(1);
%                                 end
%                             
%                                 
%                             else
%                                 
%                                 % first sample
%                                 feedback(1) = squarewave(1);
%                                 output(1) = envelope*feedback(1);
%                             end
                            %output(1) = feedback(1);
                            %fc

                            % difference equation
                            jj = 2;
                            while (fc(jj) > 0 && jj+1 <= length(timeVec))
%                                 feedback = squarewave(jj) - passband_width*output(jj-1);
%                                 output(jj) = envelope*feedback + output(jj-1);
%                                 
                                %output(jj) = envelope*(squarewave(jj) - passband_width*output(jj-1)) + output(jj-1);
                               
                                output(jj) =  sin(2*pi*(fc(jj-1))/buffer_dur)*(squarewave(jj) - passband_width*output(jj-1))/2 + output(jj-1);

                                %output(j)
                                %output(j) = feedback(j) + output(j-1);

                                %envelope = sin((2*pi*fc(jj))/total_dur);%notes{i}.duration);
                                jj = jj+1;
                            end
                            %length(fc)
                            %jj
                            %fc(jj)
                            if (jj <= length(timeVec) && fc(jj) == 0)
                           % if (jj <= length(timeVec))
                                importantNumber = length(find(output ~= 0));
                                output(1:importantNumber)=output(1:importantNumber)'.*linspace(1,0,importantNumber);
                            end
%                             
%                             if (fc(jj) == 0)
%                                output(jj-400:end) = zeros( ,1);
%                             end
                            
                            
                            
%                             if jj <= length(timeVec)
%                                 jj;
%                                 length(timeVec);
%                                 output(jj+1:end);
%                                 output(jj:end) = zeros(length(timeVec)-jj+1,1);
%                             end
                            
                            
                            
                            %output;
                            
                            
%                             for j=2:length(squarewave)
%                                 
%                                 if (fc(j) > 0)
%                                                    
%                                     feedback(j) = squarewave(j) - passband_width*output(j-1);
%                                     output(j) = envelope*feedback(j) + output(j-1);
%                                     %output(j)
%                                     %output(j) = feedback(j) + output(j-1);
% 
%                                     envelope = sin((2*pi*fc(j))/dur);%notes{i}.duration);
%                                     
%                                 else
%                                     %output(j) = output(j-1);
%                                     %output(j)
%                                     output(j) = 0;
%                                 end
%                  
%                             end
                            %output

%                             if (length(squarewave) > length(fc))
%                                 output((length(fc)+1):length(squarewave)) = 0;
%                             end

                            obj.note.old_data_point = output(end);
                            %find (output == 0)

                            % normalize
                            %max_output = 
                            
                            %audio = output/max_output/10.*mask(:);
                            
%                              if ~all(output)
%                                  output'
%                              end
                            
                            %if all(output)
                                audio = output.*mask(:)/max(abs(output))/5;
                            %else
                            %    audio = zeros(length(timeVec),1);
                            %end
                            
                            
                     


                            %audio = output/5;%.*mask(:);
                            %audio = output'/10.*mask(:);
%                             else
%                                 audio = zeros(length(mask(:)),1);
%                             end
%                             %audio = squarewave/5;
                        case {'FM'}
                            % initialize vector for frequency modulation envelope
                            dur = length(noteTime);
                            %freqmod = zeros(1, dur);%notes{i}.duration);
                            freqmod = ones(1, dur);
                            %fredmod
                            % piece-wise define function for brass-like timbre
                            % based on Jerse Figure 5.9 (d), with some modification
                            % to make it sound better
%                             freqmod(1:floor(dur)/3) = 2\noteTime(1:floor(dur)/3);
%                             freqmod(floor(dur/3+1:floor(dur*5/6))) = 12/18-noteTime(1:floor(dur)/2)/20;
%                             freqmod(floor(dur)*5/6+1:end) = 10.25/18-(noteTime(1:floor(dur)/6))*2;
%                             freqmod(freqmod < 0) = 0;

                            % evaluate and store this note of the chord in a matrix
                            
                            %audio = freqmod'.*sin(2*pi*obj.note.frequency*noteTime+freqmod'.*sin(2*pi*obj.note.frequency.*noteTime));
                            audio = sin(2*pi*obj.note.frequency*noteTime+freqmod'.*sin(2*pi*obj.note.frequency.*noteTime))/5.*mask(:);
                            
                            %audio(end-81:end) = audio(end-81:end).*(fliplr(1:82)/82)';
                            

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
