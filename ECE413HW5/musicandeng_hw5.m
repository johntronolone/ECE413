%% load audio sample

filename = 'recording.wav';
[recording, fs] = audioread(filename);

%%

signal = recording;

bufferLength = 512; % fft size
numFilts = 32;
sampleIncr = 32; % increment by 32 each iteration
numBuffers = floor((length(recording)-bufferLength)/sampleIncr)+1;

%window = zeors(512, 1);
hk = sin(pi*(0:511+1/2)/(2*512));

% load C and D windows
[C, D] = createCandD;

% create sine window
n = 64;
sineWindow = sin(pi*(1:n)/n);

subband_samples = zeros(numBuffers, n/2);


for ii = 1:numBuffers % for each buffer
    
    X_FIFO = signal((ii-1)*(sampleIncr)+1:(ii-1)*sampleIncr+bufferLength);
    
    Z_vector = X_FIFO.*C'; 
    
    Y_vector = sum(reshape(Z_vector, [], bufferLength/n), 2);
    
    for m = 1:(n/2)
        for k = 1:n
            summand(k) = Y_vector(k).*sineWindow(1,k)'.*cos(pi/2/n*(2*(k-1)+1+n/2)*(2*(m-1)+1));
        end
        subband_samples(ii,m) = sum(summand);
    end
end



% filter audio buffer with 32 bands





