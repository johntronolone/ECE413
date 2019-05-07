% Midi file to Song Ojbect

classdef objSongOld
    properties
    % These are the inputs that must be provided
    midiFilename % MIDI file to read
    startingNoteNumber % MIDI note number
    temperament = 'equal'% Default to equal temperament
    key  = 'C'  % Default to key of C
    amplitude = 1  % amplitude of the whole chord

    % Defaults
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
            if (format==0 && num_tracks~=1)
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
           
%             if (bitand(time,2^15)==0)
%               midi.ticks_per_quarter_note = timeFormat;
%             else
%               error('Time format not found)');
%             end

            % begin first track
            
            % MThd Header - 4 bytes
            % track length - 4 bytes
            % first delta time - (1 byte this case) = 0
            % event is FF --> Meta message
            % type is 03
            % length is 9
            % data is 70 117 114 32 69 108 105 115 101
            
            % at idx = 277, ...
            % 144 76 70 47 76
            % Hex: 90 4C 46 2F 4C 
            
            noteCnt = 1;
            currentlyPlayingNotes = 0;
            idx = 15;
            for i = 1:nTracks
                
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
                    currentTime = currentTime + deltaTime/ticksPerQuarterNote;
                    %startTime = startTime + deltaTime/ticksPerQuarterNote;
                    %startTime1(noteCnt) = startTime
                    %oldDeltaTime(noteCnt) = deltaTime;
                    idx = idx + incr;
                    
                    % retrieve <delta_time> of variable length
%                     deltaTime = 0;
%                     doIter = true;
%                     while (doIter)
%                         if(~bitand(hexData(idx),128)) 
%                             doIter=false;
%                         end
%                         deltaTime = deltaTime*128 + rem(hexData(idx), 128);
%                         idx = idx + 1;
%                     end
                    
                    % retrieve <event>
                    switch (hexData(idx))
                        
                        case 240 % F0 <length> <sysex_data>
                            idx = idx+1; % move pointer to length
                            %length = hexData(idx)
                            [length, metaLength] = retrieveVarLen(hexData, idx);
                            idx = idx+metaLength+length; % move pointer to next <delta_time>
                            
                        case 247 % F7 <length> <any_data>
                            idx = idx+1; % move pointer to length
                            [length, metaLength] = retrieveVarLen(hexData, idx);
                            idx = idx+metaLength+length; % move pointer to next <delta_time>

                        case 255 % FF <type> <length> <data>
                            idx = idx+1; % move pointer to type
                            type = hexData(idx);
                            idx = idx+1; % move pointer to length
                            [length, metaLength] = retrieveVarLen(hexData, idx);
                            idx = idx+metaLength+length; % move pointer to next <delta_time>

                            

                            
                        otherwise % MIDI event
                            
                            switch (bitshift(hexData(idx), -4))

                                case 8 % 8n Note off
                                    while (hexData(idx+1) < 128 && hexData(idx+2) < 128 && hexData(idx+3) < 128) % running mode
                                        idx = idx+1; % move pointer to first data byte
                                        keyReleased = hexData(idx);
                                        idx = idx+1; % move pointer to second data byte
                                        velocity = hexData(idx);
                                        fprintf('key released: %d, with velocity: %d at <delta_time>: %d\n' , keyReleased, velocity, deltaTime);
                                    end
                                    idx = idx+1;% move pointer to next delta time

                                case 9 % 9n Note on
                                    while (hexData(idx+1) < 128 && hexData(idx+2) < 128) % running mode
                                        idx = idx+1; % move pointer to first data byte
                                        keyPressed = hexData(idx);
                                        idx = idx+1; % move pointer to second data byte
                                        velocity = hexData(idx);
                                        idx = idx+1; % move pointer to next delta time
                                        %fprintf('key pressed: %d, with velocity: %d, at <delta_time>: %d, at idx: %d\n',keyPressed, velocity, deltaTime, idx);
                                        if (velocity > 0)
                                            % note on --> create note
                                            % create note
                                            startTime = currentTime;
                                            endTime = startTime;
                                            %startTime = startTime + 
                                            obj.arrayNotes(noteCnt) = objNote(keyPressed, obj.temperament,startTime,endTime,velocity/127);
                                            startTime1(noteCnt) = startTime;
                                            %deltaTime1(noteCnt) = deltaTime;
                                            noteCnt = noteCnt + 1;
                                            currentlyPlayingNotes = currentlyPlayingNotes + 1;
                                            %noteDurInTicks = deltaTime;
                                            %startTime = startTime + noteDurInTicks/ticksPerQuarterNote;
                                            
                                            %oldDeltaTime(noteCnt) = deltaTime;
                                            
                                            
                                            % multiple note on's --> do not
                                            % update startTime
                                        else 
                                            % note off --> set endTime -->
                                            for j = 1:currentlyPlayingNotes
                                                if (obj.arrayNotes(noteCnt-j).noteNumber == keyPressed)
                                                	%noteDurInTicks = deltaTime;% + deltaTime1(noteCnt-j)% - startTime1(noteCnt-j);
                                                    %timeFrac = noteDurInTicks/ticksPerQuarterNote;
                                                    endTime = currentTime; %startTime1(noteCnt-j) + (obj.breathDuration + obj.noteDuration)*timeFrac*obj.secondsPerQuarterNote*4;
                                                    obj.arrayNotes(noteCnt-j).endTime = endTime;

                                                    
                                                    %startTime = startTime + noteDurInTicks/ticksPerQuarterNote;
                                                    fprintf('Note: %d, startTime: %f, endTime: %f\n', obj.arrayNotes(noteCnt-j).noteNumber, obj.arrayNotes(noteCnt-j).startTime, obj.arrayNotes(noteCnt-j).endTime); 
                                                end
                                            end
                                            currentlyPlayingNotes = currentlyPlayingNotes - 1;
                                            %obj.arrayNotes(noteCnt-currentlyPlayingNotes).endTime = endTime;  %  = objNote(keyPressed, obj.temperament,startTime,endTime,oldVelocity/127);


                                            %startTime = startTime + deltaTime/ticksPerQuarterNote;
                                        end
                                        
                                        [deltaTime, incr] = retrieveVarLen(hexData, idx);
                                        currentTime = currentTime + deltaTime/ticksPerQuarterNote;
                                        
%                                         if (velocity > 0)
%                                         end
                                        %oldVelocity = velocity;
                                        idx = idx + incr - 1;
                                        %idx = idx + incr;
                                    end
                                    %idx = idx+1;% move pointer to next delta time
                                    


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
%                                     while (hexData(idx) < 128 && hexData(idx+2) > 0)
%                                         idx = idx+3
%                                     end
%                                     idx = idx + 2;

                                case 12 % Cn Program change
                                    idx = idx + 2;
                                    
                                case 13 % Dn Aftertouch
                                    error('implement Dn aftertouch')

                                case 14 % En Pitchbend
                                    error('implement En pitchbend')

                                %case 0:7
                                    % running mode
                                    % TODO: implement this 
                                    % undo <delta_time> index

                                case 15
                                    error('this should never be reached')
                                otherwise
                                    error(['this shouldnt come up, value = ' int2str(hexData(idx)) ' at idx = ' int2str(idx) '.'])

                                end

                    end
                    
%                     if (hexData(idx) == 255)
% 
%                         type = hexData(idx+1);
% 
%                         idx = idx+2;
%                         
%                         % get meta length
%                         metaLength = 0;
%                         doIter = true;
%                         while (doIter)
%                             if(~bitand(hexData(idx),128)) 
%                                 doIter=false;
%                             end
%                             metaLength = metaLength*128 + rem(hexData(idx), 128);
%                             idx = idx + 1;
%                         end
%                         
%                         
%                         
%                         
%                         thedata = hexData(idx:idx+metaLength-1);
%                         chan = [];
%                         
%                         idx = idx + metaLength;
% 
%                         
%                     else
%                         if
%                         end
%                     end
                        
%                     currMsg.deltatime = deltatime;
%                     currMsg.midimeta = midimeta;
%                     currMsg.type = type;
%                     currMsg.data = thedata;
%                     currMsg.chan = chan;

                    
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
    
