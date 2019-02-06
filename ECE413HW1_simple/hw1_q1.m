% homework 1, question 1




% create table of frequecies for the notes in every key

% keys: C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B
%  C4
%  Db4
%  D4 
%  Eb4
%  E4
%  F4
%  Gb4
%  G4
%  Ab4
%  A4
%  Bb4
%  B4
%  C5

% initialize just intonation frequency table
freq_table = zeros(13, 12); % 13 notes for each key, 12 keys
C4 = 264; % Hz
freq_table(1,1) = C4;

% just intonation frequency ratios
ratios = [1; 16/15; 9/8; 6/5; 5/4; 4/3; 25/18; 3/2; 8/5; 5/3; 7/4; 15/8; 2];
inverse_ratios = 1./ratios;

% populate C scale frequencies
freq_table(:,1) = C4 * ratios;

% populate diagonals, i.e. assign Db4 from C scale to Db scale, etc.
n = 13;
freq_table(1:n+1:end) = freq_table(1:12,1);

% populate rest of frequency table
for ii = 2:12
    freq_table(:, ii) = freq_table(ii,ii)*[flipud(inverse_ratios(2:ii)); ratios(1:(13-ii+1))]';
end

