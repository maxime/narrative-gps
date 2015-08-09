clear;

% Setup
settings.fileName = '..\data\20150725-122514.snap';
settings.dataType = 'ubit1';
settings.IF                 = 0; %[Hz]
settings.samplingFreq       = 1.024e6; %[Hz]
settings.codeFreqBasis      = 1.023e6; %[Hz]

% Define number of chips in a code period
settings.codeLength         = 1023;
settings.acqSatelliteList   = [1:32]; %[PRN numbers]

% Reading data
disp ('Reading data...');

[fid, message] = fopen(settings.fileName, 'rb');

raw_data = fread(fid, settings.dataType)';

data1 = raw_data(1:2:end);
data1 = 1 - (2*data1);
data2 = raw_data(2:2:end);
data2 = 1 - (2*data2);

% Create the complex data from the intervaled bits
data = data1 + 1i .* data2;

N = length(data);
Nrows = 1024;

% How many 'batches'?
Nbatches = 4;

Nsnap = N / Nrows;
Ncol = Nsnap / Nbatches;

disp (['Nrows= ' num2str(Nrows)]);
disp (['Nsnap= ' num2str(Nsnap) ' (length of signal in ms)']);
disp (['Nbatches= ' num2str(Nbatches)]);
disp (['Ncol= ' num2str(Ncol) ' (length of signal in each batch)']);

% Generate all C/A codes and sample them according to the sampling freq.
caCodesTable = makeCaTable(settings);

% Step 2
% ------

% Reshape the data as a matrix
matrix = reshape(data, [Nrows, Nsnap]);

% Pre-allocate
fft_matrix = zeros(Nrows, Ncol);
dataOfBatch = zeros(Nrows, Ncol);

acqResults = zeros(max(settings.acqSatelliteList), Nrows, Ncol);

sumOfRows = zeros(1, Ncol);
sumOfRows2 = zeros(1, Ncol);

compensated_fft_matrix = zeros(Nrows, Ncol);
compensation_vector = zeros(1, Ncol);

fprintf('(');
for batchIndex = [1:Nbatches]
    fprintf('.');

    y_start = (batchIndex-1)*Ncol + 1;
    y_end = batchIndex*Ncol;
    dataOfBatch = matrix(1:Nrows, y_start:y_end);
    
    % Step 3
    % ------
    
    for y = [1:Nrows]
        row = dataOfBatch(y, :);
        fft_row = fft(row);
        fft_matrix(y,:) = fft_row;
    end % for each row

    sumOfRows = sumOfRows + abs((squeeze(sum(fft_matrix.^2))));
    
    % Step 4
    % ------
    
    
    % -- FROM THE PDF:
    %
    % frequency compensation term
    % exp ( - j * 2 * Pi * r * T ( k * 1kHz + (C/Ncol) * 1kHz ) )

    % T > sampling rate
    % k > integer of coarse frequency
    % C - the column index
    % r - the row number

    
    % -- FROM StackExchange
    % -- http://dsp.stackexchange.com/questions/509/what-effect-does-a-delay-in-the-time-domain-have-in-the-frequency-domain

    % exp (-j * 2 * Pi * k * D / N)
    
    % D > the delay in number of samples    
    % N > total number of samples
    % k > the index
    
    % (D*k)/N == r *
    % BACKUP:
    %  compensation_vector = exp( - 1i * 2 * pi * (y-1) * ts * 1000* ( ([0:(Ncol-1)] / Ncol)));        

    % T * (k + C/N) * 1kHz

    % -- FROM self tests in Matlab:
    % compensation_term = exp((-2i*pi*nn*d)/N);
        
    for y = [1:Nrows]            
      delayInSamples = (y-1)*Nrows;        
      nn = [0:(Ncol-1)] + delayInSamples;
      
      compensation_vector = exp(- 2i * pi * delayInSamples * nn / Ncol);
      
      compensated_fft_matrix(y,:) = bsxfun(@times, fft_matrix(y,:), compensation_vector);
    end
    
    sumOfRows2 = sumOfRows2 + abs((squeeze(sum(compensated_fft_matrix.^2))));

    
    % Step 5
    % -----
    
    % Perform search for all listed PRN numbers ...
     for PRN = settings.acqSatelliteList
 
      %--- Perform DFT of C/A code ------------------------------------------
      caCodeFreqDom = conj(fft(caCodesTable(PRN, :)));

      %--- Multiplication in the frequency domain (correlation in time domain)
       
      % for each column...
      for x = [1:Ncol]
        
        col_fft = fft(compensated_fft_matrix(:, x)');
          
        conv = col_fft .* caCodeFreqDom;

        %--- Perform inverse DFT and store correlation results ------------
        acqRes = abs(ifft(conv) .^ 2);

        % - Step 6 -
        acqResults(PRN, :, x) = acqResults(PRN, :, x) + acqRes;

        
      end % for each column

     end
    
    
end % for each batch
fprintf(')\n');

%figure(1);
%plot(sumOfRows);
%figure(2);
%plot(sumOfRows2);

for PRN = settings.acqSatelliteList
     results = squeeze(acqResults(PRN, :, :));
     avg_acq = mean(mean(results));
     max_acq = max(max(results));
     result = max_acq / avg_acq;
     disp(['Satellite:' num2str(PRN) ' - R: ' num2str(result) ' - MAX: ' num2str(max_acq) ' - AVG: ' num2str(avg_acq)]);
end










