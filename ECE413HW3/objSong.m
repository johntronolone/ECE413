% Midi file to Song Ojbect

classdef objSong
    properties
    % These are the inputs that must be provided
    midiFilename % MIDI file to read
    startingNoteNumber % MIDI note number
    
    % Defaults
    temperament = 'equal'% Default to equal temperament
    key  = 'C'  % Default to key of C
    amplitude = 1  % amplitude of the whole chord
    synthMethod1 = 'Additive'
    synthMethod2 = 'Additive'
    synthMethod3 = 'Additive'
    synthMethod4 = 'Additive'
    tempo = 120 % Beats per minute
    noteDurationFraction = 0.8 % Duration of the beat the note is played for 
    breathDurationFraction = 0.2 % Duration pf the beat that is silent

    % Calculated
    secondsPerQuarterNote % The number of seconds in a quarterNote
    noteDuration % Duration of the note portion in seconds
    breathDuration % Duration of the breath portion in seconds
    arrayNotes = objNote.empty; % Array of notes for the scale
    end

    properties

    end

    methods
        
        function obj = objSong(varargin)

            obj.midiFilename=varargin{1};
            obj.temperament=varargin{2};
            if nargin >= 3
                obj.tempo=varargin{3};
            end
            
            if nargin >= 7 % fourth synth method given
                obj.synthMethod4 = varargin{7};
                obj.synthMethod3 = varargin{6};
                obj.synthMethod2 = varargin{5};
                obj.synthMethod1 = varargin{4};
            elseif nargin >= 6 % third synth method given
                obj.synthMethod4 = varargin{4};
                obj.synthMethod3 = varargin{6};
                obj.synthMethod2 = varargin{5};
                obj.synthMethod1 = varargin{4};
            elseif nargin >= 5 % second synth method given
                obj.synthMethod4 = varargin{4};
                obj.synthMethod3 = varargin{4};
                obj.synthMethod2 = varargin{5};
                obj.synthMethod1 = varargin{4};
            elseif nargin >= 4 % first synth method given
                obj.synthMethod4 = varargin{4};
                obj.synthMethod3 = varargin{4};
                obj.synthMethod2 = varargin{4};
                obj.synthMethod1 = varargin{4};
            end

            % Read midi file bytes into matlab
            fid = fopen(obj.midiFilename);
            hexData = fread(fid, 'uint8');
            fclose(fid);
            
            % MThd ID
            if ~isequal(hexData(1:4),[77; 84; 104; 100])
                error('Invalid MThd ID');
            end

            % length
            if ~(arrayToInt(hexData(5:8)) == 6)
                error('Invalid header length');
            end
            
            % format
            format = arrayToInt(hexData(9:10));
            switch (format)
                case {0,1,2}
                    midi.format = format;
                otherwise
                	error('Invalid Format');
            end

            % number of tracks
            nTracks = arrayToInt(hexData(11:12));
            if (format==0 && nTracks~=1)
                error('Format 0 specified with invlaid number of tracks');
            end
            
            % division
            ticksPerQuarterNote = arrayToInt(hexData(13:14));
            if (~bitand(ticksPerQuarterNote,2^15)==0)
                error('Time format not found)');
            end
            
            	% Compute some constants based on inputs
            obj.secondsPerQuarterNote       = 60/obj.tempo;                       
            obj.noteDuration                = obj.noteDurationFraction*obj.secondsPerQuarterNote;
                % Duration of the note in seconds (1/4 note at 120BPM)
            obj.breathDuration              = obj.breathDurationFraction*obj.secondsPerQuarterNote;
                % Duration between notes
           
            ticksPerQuarterNote = ticksPerQuarterNote/obj.secondsPerQuarterNote;

            % begin first track
            idx = 15;
            doNotIncTime = false;
            noteCnt = 1;
            
            % following implemented since some midi files have empty tracks
            sM = obj.synthMethod1;
            sMidx = 1;
            
            for i = 1:nTracks
                
                if noteCnt == 1
                    sM = obj.synthMethod1;
                elseif sMidx < 2
                    sMidx = 2;
                    sM = obj.synthMethod2;
                elseif sMidx < 3
                    sM = obj.synthMethod3;
                elseif sMidx < 4
                    sM = obj.synthMethod4;
                end
                
                startTime = 0;
                currentTime = startTime;
                
                if ~isequal(hexData(idx:idx+3),[77; 84; 114; 107])  % double('MTrk')
                    error(['Track ',  num2str(i), ': invalid track ID=MTrk']);
                end
                idx = idx + 4; % move pointer to 32-bit number for length
                
                trackLength = arrayToInt(hexData(idx:idx+3));
                idx = idx + 4; % move pointer to first delta time
                
                initIdx = idx;
                while (idx < initIdx + trackLength) 
                    % this loop runs once for each data message
                    % i.e. one loop for each <delta_time> <event> pair
                    
                    [deltaTime, incr] = retrieveVarLen(hexData, idx);
                    % do not increment time when <delta_time> has already
                    % been retrieved from running mode
                    if (~doNotIncTime)
                        currentTime = currentTime + deltaTime/ticksPerQuarterNote;
                    else
                        doNotIncTime = false;
                    end
                    
                    idx = idx + incr;
                    
                    % translate <event>
                    switch (hexData(idx))
                        
                        case 240 % F0 <length> <sysex_data>
                            idx = idx+1; % move pointer to length
                            [l, metaLength] = retrieveVarLen(hexData, idx);
                            idx = idx+metaLength+l; % move pointer to next <delta_time>
                            
                        case 247 % F7 <length> <any_data>
                            idx = idx+1; % move pointer to length
                            [l, metaLength] = retrieveVarLen(hexData, idx);
                            idx = idx+metaLength+l; % move pointer to next <delta_time>

                        case 255 % FF <type> <length> <data>
                            idx = idx+1; % move pointer to type
                            idx = idx+1; % move pointer to length
                            [l, metaLength] = retrieveVarLen(hexData, idx);
                            
                            if l >= 4
                               fprintf('%s\n',char(hexData(idx+metaLength:idx+metaLength+l-1)')); 
                            end
                            idx = idx+metaLength+l; % move pointer to next <delta_time>
                            
                        otherwise % MIDI event
                            
                            switch (bitshift(hexData(idx), -4))

                                case 8 % 8n Note off
                                    idx = idx+1; % move pointer to first data byte
                                    keyReleased = hexData(idx);
                                    idx = idx+1; % move pointer to second data byte
                                    
                                    noteOffToSet = true;
                                    for j = 1:noteCnt

                                        if (noteOffToSet && obj.arrayNotes(noteCnt-j).noteNumber == keyReleased)
                                            endTime = currentTime; %startTime1(noteCnt-j) + (obj.breathDuration + obj.noteDuration)*timeFrac*obj.secondsPerQuarterNote*4;
                                            obj.arrayNotes(noteCnt-j).endTime = endTime;
                                            obj.arrayNotes(noteCnt-j).total_duration = (endTime - startTime)*44100; % shouldn't be hard coded
                                            obj.arrayNotes(noteCnt-j).fc_init = 2000/2/pi;
                                            obj.arrayNotes(noteCnt-j).fc_final = 100/2/pi;

                                            obj.arrayNotes(noteCnt-j).fc_full = [zeros(1, 882) linspace(obj.arrayNotes(noteCnt-j).fc_init, obj.arrayNotes(noteCnt-j).fc_final, (obj.arrayNotes(noteCnt-j).endTime - obj.arrayNotes(noteCnt-j).startTime)*44100+882+1) zeros(1, 882)]; % shouldn't be hard coded
                                            obj.arrayNotes(noteCnt-j).old_data_point = 0;
                                            noteOffToSet = false;
                                        end
                                    end
                                    idx = idx+1;% move pointer to next delta time

                                case 9 % 9n Note on
                                    while (hexData(idx+1) < 128 && hexData(idx+2) < 128) % running mode
                                        idx = idx+1; % move pointer to first data byte
                                        keyPressed = hexData(idx);
                                        idx = idx+1; % move pointer to second data byte
                                        velocity = hexData(idx);
                                        idx = idx+1; % move pointer to next delta time
                                        if (velocity > 0)
                                            % note on --> create note
                                            % create note
                                            startTime = currentTime;
                                            endTime = startTime;
                                            obj.arrayNotes(noteCnt) = objNote(keyPressed, obj.temperament,startTime,endTime,velocity/127,sM);
                                            noteCnt = noteCnt + 1;
                                            % multiple note on's --> do not
                                            % update startTime
                                        else 
                                            % note off --> set endTime and
                                            % update object params
                                            
                                            noteOffToSet = true;
                                            for j = 1:noteCnt
                                                
                                                if (noteOffToSet && obj.arrayNotes(noteCnt-j).noteNumber == keyPressed)
                                                    endTime = currentTime;
                                                    obj.arrayNotes(noteCnt-j).endTime = endTime;
                                                    obj.arrayNotes(noteCnt-j).total_duration = (endTime - startTime)*44100; % shouldn't be hard coded
                                                    obj.arrayNotes(noteCnt-j).fc_init = 2000/2/pi;
                                                    obj.arrayNotes(noteCnt-j).fc_final = 100/2/pi;
            
                                                    obj.arrayNotes(noteCnt-j).fc_full = [zeros(1, 882) linspace(obj.arrayNotes(noteCnt-j).fc_init, obj.arrayNotes(noteCnt-j).fc_final, (obj.arrayNotes(noteCnt-j).endTime - obj.arrayNotes(noteCnt-j).startTime)*44100+882+1) zeros(1, 882)]; % shouldn't be hard coded
                                                    obj.arrayNotes(noteCnt-j).old_data_point = 0;
                                                    noteOffToSet = false;
                                                end
                                            end
                                        end
                                        
                                        [deltaTime, incr] = retrieveVarLen(hexData, idx);
                                        currentTime = currentTime + deltaTime/ticksPerQuarterNote;
                                        doNotIncTime = true;
                                        idx = idx + incr - 1;
                                    end

                                case 10 % An Aftertouch
                                    error('implement An aftertouch')

                                case 11 % Bn Control change
                                    while (hexData(idx+2) < 128) % running mode
                                        idx = idx + 1; % move pointer to ctrlr num
                                        ctrlr_num = hexData(idx);
                                        idx = idx + 1; % move pointer to ctrlr val
                                        ctrlr_val = hexData(idx);
                                    end
                                    idx = idx + 1; % move pointer to next <delta_time>

                                case 12 % Cn Program change
                                    idx = idx + 2;
                                    
                                case 13 % Dn Aftertouch
                                    error('implement Dn aftertouch')

                                case 14 % En Pitchbend
                                    error('implement En pitchbend')
                                    
                                otherwise
                                    error(['this shouldnt come up, value = ' int2str(hexData(idx)) ' at idx = ' int2str(idx) '.'])
                                end

                    end
                end
            end
        end
    end
end
    

function int = arrayToInt(array)
    int = 0;
    array = flipud(array);
    for i=1:length(array)
        int = int + bitshift(array(i), (i-1)*8);
    end
end

function [value, idxIncr] = retrieveVarLen(data, pointer)
    value = 0;
    doIter = true;
    pointerInit = pointer;
    while (doIter)
        if(~bitand(data(pointer),128)) 
            doIter=false;
        end
        value = value*128 + rem(data(pointer), 128);
        pointer = pointer + 1;
    end
    idxIncr = pointer - pointerInit;

end
    
