classdef SignalToolboxTests < matlab.unittest.TestCase
% Copyright 2017 - 2018 The MathWorks, Inc.

    properties
      DisplayInfo = true;
    end
    
    methods(Static)
        
        function plotResponseComparison(Festimate,Hestimate,Fexpected,Hexpected)
            
            plot(Fexpected,20*log10(abs(Hexpected)));
            hold on
            plot(Festimate,20*log10(abs(Hestimate)));
            grid on
            legend('Expected magnitude response', 'Estimated magnitude response');
            
        end
        
        function plotAnalogDigitalComparison(Wz,HzdB,Wa,HadB)
            
            plot(Wa/(2*pi),HadB,'LineWidth',2);
            hold on;
            plot(Wz,HzdB,'r--');
            xlabel('Frequency (Hz)')
            ylabel('Magnitude (dB)');
            title('Magnitude Response Comparison');
            legend('Analog Filter','Digital Filter');
            
        end
        
        function  plotImpulseComparison(estImpulseResp,impulseResp)
            
            subplot(2,1,1)
            stem(estImpulseResp);
            title('Impulse Response with Prony Design');
            
            subplot(2,1,2)
            stem(impulseResp);
            title('Input Impulse Response');
            
        end
        
        function plotDecimatedComparison(F1,H1,F2,H2,legendH2)
            
            plot(F1,10*log10(H1));
            hold on
            plot(F2,10*log10(H2));
            xlabel('Hz');
            ylabel('Power Spectrum (dB)');
            legend('Original signal', legendH2);
            grid on;
            
        end
        
        function plotUpFirDownComparison(tx,xs,txud,xsud,F1,H1,F2,H2)
          
            stem(tx,xs);
            hold on
            stem(txud,xsud,'r','filled');
            xlabel('Time (s)');
            ylabel('Signal');
            legend('Original','Resampled');
            hold off
            
            snapnow; % for publishing
            
            plot(F1,10*log10(H1));
            hold on
            plot(F2,10*log10(H2));
            xlabel('Hz');
            ylabel('Power Spectrum (dB)');
            legend('Original signal', 'Decimated signal');
            grid on;
            
        end
        
        function printValidationmessage(testCase,functionlist,description)
        
        if testCase.DisplayInfo
            fprintf('\n================================================================================\n'); 
            fprintf('Validating:\n');
            for i=1:length(functionlist)
            fprintf('-> %s\n',functionlist{i});
            end

            if nargin>2
                fprintf('\n');
                disp(char(description));
            end
        end
        
        end   
        
    end
    
    % Test Method includes all unit test cases
    methods (Test)
        
        % Test Function
        function ConvolutionTest(testCase)
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            
            SignalToolboxTests.printValidationmessage(testCase,{...
            'conv',...
            'fft, ifft',...
            'fftfilt'
            });

            % Output of rectangular pulse x(n) = 1 for n = 0,1,2,...,9
            % when input to a system with impulse response h(n) = (0.9)^n * u(n)

            % Theoretical response
            n = (0:49)';
            y = zeros(50,1);
            y(1:10) = 10*(1-(0.9).^(n(1:10)+1));
            y(11:end) = 10*((0.9).^(n(11:end)-9))*(1-(0.9)^10);

            % Result using conv
            rectPulse = zeros(50,1);
            rectPulse(1:10) = 1;
            h = (0.9).^(n);

            yActual1 = conv(rectPulse,h);
            
            % Compare first 50 samples of the convolution output with theoretical
            % result
            testCase.verifyThat(yActual1(1:50)', IsEqualTo(y','Within', AbsoluteTolerance(1e-12)),...
                                  'Convolution via conv did not match theoretical result');

            % Convolution in time domain is multiplication in frequency domain
            R = fft(rectPulse,64);
            H = fft(h,64);
            Y = R.*H;
            yActual2 = ifft(Y,64);

            testCase.verifyThat(yActual2(1:50)', IsEqualTo(y','Within', AbsoluteTolerance(1e-12)),...
                                  'Convolution via FFT/IFFT did not match theoretical result');

            % Implement frequency domain multiplication using fftfilt
            yActual3 = fftfilt(h,rectPulse);

            testCase.verifyThat(yActual3(1:50)', IsEqualTo(y','Within', AbsoluteTolerance(1e-12)),...
                                  'Convolution via fftfilt did not match theoretical result');
        end
        
        function CorrelationTest(testCase)
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            
            SignalToolboxTests.printValidationmessage(testCase,{...
            'xcorr',...
            'conv'
            });
            
            % Compute correlation o x(n) = a^n * u(n), 0 < a < 1
            
            a = 0.2;

            % Theoretical result
            l = (-500:500).';
            rxx = (a.^abs(l))./(1-a^2);

            % Result using xcorr
            n = (0:1000).';
            x = a.^n;
            rxxActual1 = xcorr(x,x,500); % compute first 500 lags

            testCase.verifyThat(rxxActual1', IsEqualTo(rxx','Within', AbsoluteTolerance(1e-13)),...
                                  'Correlation via xcorr did not match theoretical results');

            % Result using convolution rxx = conv(x(l), x(-l));
            xFlipped = flipud(x);
            rxxActual2 = conv(x,xFlipped);
            
            testCase.verifyThat(rxxActual2(501:1501)', IsEqualTo(rxx','Within', AbsoluteTolerance(1e-13)),...
                                   'Correlation via conv did not match theoretical results');
            
        end
        
        function FrequencyResponseTest(testCase)
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            
            Description = {'Frequency and phase response of a moving average filter:';...
                            'y(n) = (1/3)*[x(n+1) + x(n) + x(n-1)];';...
                            'h = [1/3 1/3 1/3]; --> filter coefficients';...
                            'Theoretical frequency response is H(w) = (1/3)*(1+2*cos(w))';...
                            'Magnitude response = (1/3)*abs(1+2*cos(w))}'};
            
            SignalToolboxTests.printValidationmessage(testCase,{'freqz'},Description);
            
            h = [1 1 1]/3;
            w = 0:0.01:pi;
            Hexp = abs(1+2*cos(w))/3;
            Hact = abs(freqz(h,1,w));
            
            testCase.verifyThat(Hact, IsEqualTo(Hexp,'Within', AbsoluteTolerance(1e-13)),...
                                 'Frequency response via freqz did not match theoretical results');
        end
        
        function FrequencyResponseEstimateTest(testCase)
        
            Description ={'Design an FIR filter of order 30 and filter white noise. Estimate the';...
                          'filter''s transfer function using the white noise input and the filtered';...
                          'output. Then compare the transfer function estimate to the transfer';...
                          'function computed using freqz. Verify that they are close using mean';...
                          'squared error of the spectrum.'};
            
            SignalToolboxTests.printValidationmessage(testCase,{'tfestimate','freqz'},Description);
            
            import matlab.unittest.constraints.IsLessThanOrEqualTo
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic
            
            Fs = 512;
            h = fir1(30,0.2,rectwin(31));
            x = randn(16384,1);
            y = filter(h,1,x);
            [Hestimate, Festimate] = tfestimate(x,y,1024,0,1024,Fs, 'twosided');
            
            [Hexpected, Fexpected] = freqz(h,1,1024,'whole',Fs);
            
            mse = sum((abs(Hestimate)-abs(Hexpected)).^2)/length(Hestimate);
            
            testCase.verifyThat(mse, IsLessThanOrEqualTo(3e-5), ...
                                 @() SignalToolboxTests.plotResponseComparison(Festimate,Hestimate,Fexpected,Hexpected));
            
        end
        
        function GroupDelayTest(testCase)
                    
            Description = {'The group delay of a linear FIR filter is constant and equal to half the';
                          'filter order.';
                          ' ';
                          'Design a 70th order FIR lowpass filter and compute it''s group delay. Plot';
                          'the group delay and get its mean and std to show that it is constant and';
                          'equal to 35.'};
            
            SignalToolboxTests.printValidationmessage(testCase,{'grpdelay','filtord'},Description);
                      
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic
            
            b = fir1(70,0.2);
            gd = grpdelay(b,1);
            
            expectedGd = filtord(b)/2;
            
            actualGd = mean(gd);
            stdGd = std(gd);
            
            testCase.verifyEqual(actualGd,expectedGd,@() grpdelay(b,1));
            testCase.verifyEqual(stdGd,0);

        end
        
        function SpectralEstimationTest(testCase)
        
           Description ={'Design a 48th-order FIR linear phase lowpass filter with passband edge';
                          'at 0.35*Fs/2. Assuming Fs = 1000 Hz the passband edge is at 175 Hz.'};
            
           SignalToolboxTests.printValidationmessage(testCase,{...
               'fir1',...
               'filter',...
               'filtord',...
               'islinphase',...
               'pwelch',...
               'powerbw'...
               },Description);
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic
            
            Fs = 1e3;
            b = fir1(48,.35);
            
            % Filter white noise.
            x = filter(b,1,randn(1e6,1));
            
            % Compute the power spectrum of the filter using windows of length 512.
            [Pxx, F] = pwelch(x,512,256,512,Fs,'power');
            RBW = Fs/512;
            
            % Use the power spectrum to measure the 6 dB bandwidth and also produce a
            % plot. The measured BW should be close to the expected 175 Hz BW.
            BW = powerbw(Pxx,F,RBW,[],6);
            expectedBW = 0.35*Fs/2;
            
            % 1 Hz tolerance
            testCase.verifyThat(BW, IsEqualTo(expectedBW,'Within', AbsoluteTolerance(1)),...
                                 @() powerbw(Pxx,F,RBW,[],6));
            
            % Check the filter order and verify that filter is linear phase and compare
            % to actual values
            n = filtord(b,1);
            isLinPhaseFlag = islinphase(b,1);
            
            testCase.verifyEqual(n,48,'Filter order returned from filord was incorrect');
            testCase.verifyTrue(isLinPhaseFlag,'islinphase returned false for a linear phase filter');
            
        end
        
        function FilterDesignTest(testCase)
        
            Description = {'Design a 6th-order Butterworth bandpass filter with passband edges at';
                           '0.35*Fs/2 and 0.45*Fs/2. Asuming Fs = 1000 Hz the passband edges are at';
                            '175 and 225 Hz and the passband bandwidth is 50 Hz.'};
            
            SignalToolboxTests.printValidationmessage(testCase,{...
            'butter',...
            'sosfilt',...
            'filtord',...
            'islinphase',...
            'zp2sos',...
            'pwelch',...
            'powerbw'...
            },Description);
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic
            
            % Design a filter using second order sections
            Fs = 1e3;
            [z,p,k] = butter(6, [0.35, 0.45]);
            SOSMatrix = zp2sos(z,p,k);
            
            % Filter white noise.
            x = sosfilt(SOSMatrix,randn(1e6,1));
            
            % Compute the power spectrum of the filter using windows of length 512.
            [Pxx, F] = pwelch(x,512,256,512,Fs,'power');
            RBW = Fs/512;
            
            % Use the power spectrum to measure the 3 dB bandwidth and also produce a
            % plot. The measured BW should be close to the expected 50 Hz BW.
            [BW, Flo, Fhi] = powerbw(Pxx,F,RBW);
            expdBW = 0.45*Fs/2 - 0.35*Fs/2;
            expFlo = 0.35*Fs/2;
            expFhi = 0.45*Fs/2;
            
            % 1 Hz tolerance           
            testCase.verifyThat([BW Flo Fhi], IsEqualTo([expdBW expFlo expFhi],'Within',...
                                                         AbsoluteTolerance(1)),...
                                                       @() powerbw(Pxx,F,RBW));
            
            
            
            % Check the filter order and verify that filter is not a linear phase
            % filter. Compare to actual values. Order is 2*6 since this is a bandpass
            % filter. Also verify that the filter is stable
            n = filtord(SOSMatrix);
            isLinPhaseFlag = islinphase(SOSMatrix);
            isStableFlag = isstable(SOSMatrix);
            
            testCase.verifyEqual(n,2*6,'Filter order returned from filord was incorrect');
            testCase.verifyFalse(isLinPhaseFlag,'islinphase returned true for a non linear phase filter');
            testCase.verifyTrue(isStableFlag,'isstabel returned false for a stable filter');
            
        end
        
        function BilinearTransformTest(testCase)
            
            Description = {'Compute the bilinear transform of H(s) = (s+1)/(s^2 + 5*s + 6),and';
                           'compare to the theoretical result given by:';
                           'H(z) = (0.15 + 0.1*z^-1 - 0.05* z^-2)/ (1 + 0.2*z^-1)'};
            
            SignalToolboxTests.printValidationmessage(testCase,{'bilinear'},Description);
                       
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance
            
            num = [1, 1];
            den = [1, 5, 6];
            
            [b,a] = bilinear(num,den,1);
            
            exp_b = [.15, .1, -.05];
            exp_a = [1, 0.2, 0];
            
            testCase.verifyThat(b, IsEqualTo(exp_b,'Within',...
                                                    AbsoluteTolerance(1e-15)));
            testCase.verifyThat(a, IsEqualTo(exp_a,'Within',...
                                                    AbsoluteTolerance(1e-15)));
        end
        
        function AnalogDigitalFilterTest(testCase)
            
            Description ={'Illustrate the relationship between digital and analog frequency';
                          'responses. Design an analog butterworth filter, then convert the analog';
                          'response to digital using impulse invariance. Compare the frequency';
                          'response of the analog and the digital filters.'};
            
            SignalToolboxTests.printValidationmessage(testCase,{...
               'impinvar',...
               'freqs',...
               'freqz'...
               },Description);
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic
            
            [b,a] = butter(4,0.3,'s'); % analog filter
            [bz,az] = impinvar(b,a,10); % digital filter with 10 Hz sample rate
            [Ha,Wa] = freqs(b,a,512);   % analog response
            [Hz,Wz] = freqz(bz,az,512,10); % digital response
            
            HadB = 20*log10(abs(Ha));
            HzdB = 20*log10(abs(Hz));
            
            %Resample digital filter response to compare against HadB
            HzdBr = interp1(Wz,HzdB,Wa/(2*pi),'spline');
            
            testCase.verifyThat(HzdBr', IsEqualTo(HadB','Within',...
                AbsoluteTolerance(0.03)),...
                @() SignalToolboxTests.plotAnalogDigitalComparison(Wz,HzdB,Wa,HadB));

        end
        
        function AutoRegressiveModelTest(testCase)
            
            SignalToolboxTests.printValidationmessage(testCase,{...
               'arcov',...
               'armcov',...
               'aryule'...
               });
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance
            
            % Estimate AR coefficients using the modified covariance method
            a = [1, .1, -0.8];                         % AR coefficients
            var = 0.4;                                 % noise variance
            order = numel(a)-1;                        % Process order
            w = sqrt(var)*randn(500e3,1);              % white noise
            x = filter(1,a,w);                         % realization of AR process
            
            % estimate AR model parameters using different functions
            [aEstimate,varEstimate] = arcov(x,order);
            testCase.verifyThat([aEstimate varEstimate], IsEqualTo([a var],'Within',...
                                                         AbsoluteTolerance(1e-2)));
            
            [aEstimate,varEstimate] = armcov(x,order);
            testCase.verifyThat([aEstimate varEstimate], IsEqualTo([a var],'Within',...
                                                         AbsoluteTolerance(1e-2)));
            
            [aEstimate,varEstimate] = aryule(x,order);
            testCase.verifyThat([aEstimate varEstimate], IsEqualTo([a var],'Within',...
                                                         AbsoluteTolerance(1e-2)));
            [aEstimate,varEstimate] = lpc(x,order);
            testCase.verifyThat([aEstimate varEstimate], IsEqualTo([a var],'Within',...
                                                         AbsoluteTolerance(1e-2)));
            
        end
        
        function ImpulseResponseTest(testCase)
            
            Description ={'Compute the impulse response of an IIR filter, feed this input response';
                          'to the prony function to estimate a transfer function, estimate the';
                          'impulse response from the transfer function and verify that the original';
                          'and estimated impulse responses are close.'};
            
            SignalToolboxTests.printValidationmessage(testCase,{...
               'prony',...
               'impz'...
               },Description);
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance
            import matlab.unittest.constraints.IsLessThanOrEqualTo
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic
            
            d = designfilt('lowpassiir','NumeratorOrder',4,'DenominatorOrder',4, ...
                'HalfPowerFrequency',0.2,'DesignMethod','butter');
            
            % Convert the sos matrix of the filter to a transfer function to be able to
            % compare to the numerator and denominator values obtained with prony
            [expectedNum,expectedDen] = sos2tf(d.Coefficients);
            
            impulseResp = filter(d,[1 zeros(1,31)]);
            denOrder = 4;
            numOrder = 4;
            [num,den] = prony(impulseResp,numOrder,denOrder);
            
            testCase.verifyThat(num, IsEqualTo(expectedNum,'Within',...
                                     AbsoluteTolerance(1e-12)));
                                 
            testCase.verifyThat(den, IsEqualTo(expectedDen,'Within',...
                                     AbsoluteTolerance(1e-12)));
            
            estImpulseResp = impz(num,den,length(impulseResp));
            
            mse = sum((estImpulseResp - impulseResp.').^2)/length(impulseResp);
                        
            testCase.verifyThat(mse, IsLessThanOrEqualTo(1e-25),...
                                      @() SignalToolboxTests.plotImpulseComparison(estImpulseResp,impulseResp));
            
        end
        
        function DownsampleUpsampleTest(testCase)
            
            SignalToolboxTests.printValidationmessage(testCase,{...
               'downsample',...
               'upsample'...
               });
            
            % Start with first sample on x
            x = randn(1000,1);
            xDown = downsample(x,3);
            xDownExpected = x(1:3:end);
            
            xUp = upsample(x,3);
            xUpExpected = [x.' ; zeros(2,1000)];
            xUpExpected = xUpExpected(:);
            
            testCase.verifyEqual(xDown.',xDownExpected.');
            testCase.verifyEqual(xUp.',xUpExpected.');
            
            % Start with an offset of 2 samples
            x = randn(1000,1);
            xDown = downsample(x,3,2);
            xDownExpected = x(3:3:end);
            
            xUp = upsample(x,3,2);
            xUpExpected = [x.' ; zeros(2,1000)];
            xUpExpected = xUpExpected(:);
            xUpExpected = [0; 0; xUpExpected(1:end-2)];
            
            testCase.verifyEqual(xDown.',xDownExpected.');
            testCase.verifyEqual(xUp.',xUpExpected.');
            
        end
        
        function DecimateInterpolateTest(testCase)
            
            Description = {'Decimate by 4 a signal consisting of two tones. Obtain the spectra of';
                           'original and decimated signals and compare. Signals should have very';
                           'close spectral content over a 400 Hz band.'};
            
            SignalToolboxTests.printValidationmessage(testCase,{...
               'decimate',...
               'interpolate'...
               },Description);
            
            import matlab.unittest.constraints.IsLessThanOrEqualTo
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic
            
            Fs = 1/0.00025;
            t = 0:.00025:1;
            x = sin(2*pi*30*t) + sin(2*pi*60*t);
            ydecim = decimate(x,4,240,'FIR');
            
            [H1,F1] = pwelch(x,512,256,512*4,Fs,'power');
            [H2,F2] = pwelch(ydecim,512/4,256/4,512,Fs/4,'power');
                       
            H1p = H1(F1 <= 400);
            mse = sum((H1p - H2(1:length(H1p))).^2)/length(H1p);
                       
            testCase.verifyThat(mse, IsLessThanOrEqualTo(1e-6),...
                @() SignalToolboxTests.plotDecimatedComparison(F1,H1,F2,H2,'Decimated signal'));
            
            Description ={'Now interpolate the decimated signal by 4 - the resulting signal should';
                          'be very close to the original signal. Measure mean squared error in time';
                          'and frequency.'};
            
            if testCase.DisplayInfo
            disp(char(Description));
            end
            
            yinterp = interp(ydecim,4);
            mse = sum((x - yinterp(1:length(x))).^2)/length(x);
            
            testCase.verifyThat(mse,IsLessThanOrEqualTo(1e-6));
            
            [H1,F1] = pwelch(x,512,256,512*4,Fs,'power');
            [H3,F3] = pwelch(yinterp,512,256,512*4,Fs,'power');
                       
            mse = sum((H1 - H3).^2)/length(H1);
            
            testCase.verifyThat(mse, IsLessThanOrEqualTo(1e-6),...
                @() SignalToolboxTests.plotDecimatedComparison(F1,H1,F3,H3,'Decimated-Interpolated signal'));
            
        end
        
        function upfirdownTest(testCase)

            import matlab.unittest.constraints.IsLessThanOrEqualTo
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic
            
            Description = {'Change the sampling rate of a 1 kHz sinusoid by a factor of 147/160. This';
                          'factor is used to convert from 48 kHz (DAT rate) to 44.1 kHz (CD sampling';
                          'rate). Verify that the spectra of the original and resampled signals is';
                          'equal.'};
            
            SignalToolboxTests.printValidationmessage(testCase,{'upfirdn'},Description);
            
            Fs = 48e3;                   % Original sampling frequency-48kHz
            FsNew = Fs*147/160;
            L = 147;                     % Interpolation/decimation factors
            M = 160;
            N = 24*L;
            h = fir1(N-1,1/M,kaiser(N,7.8562));
            h = L*h;                     % Passband gain is L
            
            n = 0:10239;                 % 10240 samples, 0.213 seconds long
            x = sin(2*pi*1e3/Fs*n);      % Original signal
            y = upfirdn(x,h,L,M);        % 9430 samples, still 0.213 seconds
            
            tx = n(1:49)/Fs;             % time index for original signal section
            xs = x(1:49);                % Original signal section
            txud = n(1:45)/(Fs*L/M);     % time index for resampled signal section
            xsud = y(13:57);             % Resampled signal section
                      
            [H1,F1] = pwelch(x,512,256,512,Fs,'power');
            [H2,F2] = pwelch(y,round(512*(147/160)),round(256*(147/160)),round(512*(147/160)),FsNew,'power');
            
            H1p = H1(F1 <= 500);
            mse = sum((H1p - H2(1:length(H1p))).^2)/length(H1p);
                       
            testCase.verifyThat(mse, IsLessThanOrEqualTo(1e-6),...
                @() SignalToolboxTests.plotUpFirDownComparison(tx,xs,txud,xsud,F1,H1,F2,H2));
            
        end
        
        function resampleTest(testCase)
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance
            
            Description ={'Bring a non-uniformly sampled signal to a uniform sample rate.'};
            
            SignalToolboxTests.printValidationmessage(testCase,{'resample'},Description);
            
            % Create a time vector and add/subtract small values to make it
            % non-uniform.
            tx = linspace(0,1,21) + .0012*[1 4 2 -5 -5 6 -4 7 3 2 1 5 -5 4 3 -6 5 2 3 5 2];
            x = sin(2*pi*tx);
            
            % Resample to a uniform rate
            [act_y, act_ty] = resample(x, tx, 'spline');
            
            % Compare resample output to the uniformly sampled version of the input
            % signal.
            exp_ty = linspace(tx(1),tx(end),21);
            exp_y = sin(2*pi*exp_ty);
            
            testCase.verifyThat(act_y,IsEqualTo(exp_y,'Within',AbsoluteTolerance(1e-4)));
            testCase.verifyThat(act_ty,IsEqualTo(exp_ty,'Within',AbsoluteTolerance(eps)));
            
        end
        
        function ReconstructMissingData(testCase)
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance
            
            Description ='Reconstruct missing data using resample.';
            
            SignalToolboxTests.printValidationmessage(testCase,{'resample'},Description);
            
            Fs = 4000;
            N = 2^11+1;
            t = (0:(N-1))/Fs;
            f = @(t) sin(2*pi*440*t)+ sin(2*pi*700*t+pi/sqrt(3));
            
            x = f(t);
            
            idx = 2:2:N-1;
            
            % resample understands NaNs as missing data. Set some data points to NaNs,
            % then resample and compare to the complete signal to verify proper
            % reconstruction.
            xNaN=x;
            xNaN(idx)=NaN;
            
            tNaN=t;
            tNaN(idx)=NaN;
            
            % Check that there are no NaN at the output and that resample signal
            % matches analog signal within a tolerance. Use different interpolation
            % algorithms.
            [xout,tout]=resample(xNaN,tNaN,2*Fs);
            testCase.verifyThat(xout(100:4000),IsEqualTo(f(tout(100:4000)),'Within',...
                                                      AbsoluteTolerance(2e-3))); % needed because xout1 and xout2 are different
            
            [xout,tout]=resample(xNaN,tNaN,2*Fs,'pchip');
            testCase.verifyThat(xout(100:4000),IsEqualTo(f(tout(100:4000)),'Within',...
                                                      AbsoluteTolerance(2e-3))); % needed because xout1 and xout2 are different
            
            [xout,tout]=resample(xNaN,tNaN,2*Fs,'spline');
            testCase.verifyThat(xout(100:4000),IsEqualTo(f(tout(100:4000)),'Within',...
                                                      AbsoluteTolerance(2e-3))); % needed because xout1 and xout2 are different
        
        end
        
        function subspaceMethodsTest(testCase)
            
            Description = {'Estimate frequencies of 3 complex exponentials in noise using rootmusic,';
                           'pmusic, peig, pcov, and pburg.'};
            
            SignalToolboxTests.printValidationmessage(testCase,{...
              'rootmusic',...
              'pmusic',...
              'peig',...
              'pcov',...
              'pburg',...
              'corrmtx',...
              'findpeaks'...
                },Description);
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance  
            
            n=0:100e3;
            s=2*exp(1i*pi/2*n) + 1.5*exp(1i*pi/4*n) + exp(1i*pi/3*n)+randn(1,length(n));
            % Estimate the correlation matrix using the modified covariance method.
            [X, R] = corrmtx(s,12,'mod');
            
            [W,P] = rootmusic(X,3); % get estimates using data matrix X
            [W1,P1] = rootmusic(R,3, 'corr'); % get estimates using correlation matrix R
            
            [pseudoSpectrum, w] = pmusic(X,3);
            [~,W2] = findpeaks(log10(pseudoSpectrum), w, 'MinPeakHeight', 0);
            
            [pseudoSpectrum1, w1] = peig(X,3);
            [~,W3] = findpeaks(log10(pseudoSpectrum1), w1, 'MinPeakHeight', 0);
            
            [S, w] = pcov(s,100);
            [~,W4] = findpeaks(log10(S), w, 'MinPeakHeight', -0.5);
            
            [S, w] = pburg(s,100);
            [~,W5] = findpeaks(log10(S), w, 'MinPeakHeight', -0.5);
            
            expectedW = [pi/4, pi/3, pi/2]';
            expectedP = [1, 1.5^2, 2^2]';
            
            testCase.verifyThat(sort(W),IsEqualTo(expectedW,'Within',AbsoluteTolerance(1e-2)));
            testCase.verifyThat(sort(P),IsEqualTo(expectedP,'Within',AbsoluteTolerance(1e-1)));
            
            testCase.verifyThat(sort(W1),IsEqualTo(expectedW,'Within',AbsoluteTolerance(1e-2)));
            testCase.verifyThat(sort(P1),IsEqualTo(expectedP,'Within',AbsoluteTolerance(1e-1)));
            
            testCase.verifyThat(sort(W2),IsEqualTo(expectedW,'Within',AbsoluteTolerance(1e-2)));
            
            testCase.verifyThat(sort(W3),IsEqualTo(expectedW,'Within',AbsoluteTolerance(1e-2)));
            
            testCase.verifyThat(sort(W4),IsEqualTo(expectedW,'Within',AbsoluteTolerance(1e-2)));
           
            testCase.verifyThat(sort(W5),IsEqualTo(expectedW,'Within',AbsoluteTolerance(1e-2)));
            
        end
        
        function toneEstimationTest(testCase)
            
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance
            
            Description = {'Spectral estimation of tones';
                           'Measure tone powers and compare to theoretical tone power'; 
                           'which equals A^2/2'};
            
            SignalToolboxTests.printValidationmessage(testCase,{...
              'periodogram',...
              'meanfreq'...
                },Description);
            
            % Create tones at 100 Hz with different amplitudes.
            N = 1024;
            Fs = 1024;
            x = sin( 2 * pi * 100 * (0:N-1)/N);
            [P,F] = periodogram(x,ones(size(x)),length(x),Fs,'power');
            
            actualPower = 1/2;
            actualFreq = 100;
            [estimatedPower, idx] = max(P);
            estimatedFreq = F(idx);
            
           % Verifying periodogram
            testCase.verifyThat(actualPower,IsEqualTo(estimatedPower,'Within',AbsoluteTolerance(eps)));
            testCase.verifyThat(actualFreq,IsEqualTo(estimatedFreq,'Within',AbsoluteTolerance(1e-14)));
            
            x = 0.15*sin( 2 * pi * 100 * (0:N-1)/N);
            [P, F] = periodogram(x,ones(size(x)),length(x),Fs,'power');
            
            actualPower = (0.15)^2/2;
            actualFreq = 100;
            [estimatedPower, idx] = max(P);
            estimatedFreq = F(idx);
            
            testCase.verifyThat(actualPower,IsEqualTo(estimatedPower,'Within',AbsoluteTolerance(eps)));
            testCase.verifyThat(actualFreq,IsEqualTo(estimatedFreq,'Within',AbsoluteTolerance(1.5e-14)));
            
            % Use meanfreq to find the tone frequency and power. Use time domain and
            % frequency domain versions.
            [estimatedFreq, estimatedPower] = meanfreq(x,Fs);
            
            % Verifying meanfreq
            testCase.verifyThat(actualPower,IsEqualTo(estimatedPower,'Within',AbsoluteTolerance(eps)));
            testCase.verifyThat(actualFreq,IsEqualTo(estimatedFreq,'Within',AbsoluteTolerance(1.5e-14)));
            
            [estimatedFreq, estimatedPower] = meanfreq(P,F);
            testCase.verifyThat(actualPower,IsEqualTo(estimatedPower,'Within',AbsoluteTolerance(eps)));
            testCase.verifyThat(actualFreq,IsEqualTo(estimatedFreq,'Within',AbsoluteTolerance(1.5e-14)));
            
        end
        
        function noiseEstimationTest(testCase)
                       
            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance
            
            Description = {'Spectral estimation of noise.';
                           'Integrate PSD over frequency intervals to compute total power which';
                           'should be equal to the noise power.';
                           'Use periodogram and pwelch to estimate power spectral density.'};
            
            SignalToolboxTests.printValidationmessage(testCase,{...
              'periodogram',...
              'pwelch',...
              'bandpower'...
                },Description);
            
            noisePower = .015;
            N = 2^14;
            Fs = N;
            xn = sqrt(noisePower)*randn(N,1);
            [PSD,F] = periodogram(xn,ones(N,1),N,Fs,'psd');
            deltaF = F(2)-F(1);
            estimatedPower = sum(PSD*deltaF);
            
            % Verifying periodogram
            testCase.verifyThat(estimatedPower,IsEqualTo(noisePower,'Within',AbsoluteTolerance(1e-1)));
            
            [PSD,F] = pwelch(xn,ones(round(N/100),1),0,round(N/100),Fs,'psd');
            deltaF = F(2)-F(1);
            estimatedPower = sum(PSD*deltaF);
            
            % Noise floor should be equal to noisePower/Fs
            noiseFloor = 10*log10(noisePower/Fs);
            estimatedNoiseFloor = 10*log10(mean(PSD))-3; % Subtract three as we are computing one sided spectrum
            
            % Verifying pwelch
            testCase.verifyThat(estimatedPower,IsEqualTo(noisePower,'Within',AbsoluteTolerance(1e-1)));
            testCase.verifyThat(estimatedNoiseFloor,IsEqualTo(noiseFloor,'Within',AbsoluteTolerance(2e-1)));
            
            % Estimate power of the signal using the bandpower function. Use time and
            % frequency domain versions.
            estimatedPower = bandpower(xn, Fs, [0 Fs/2]);
            
            % Verifying bandpower
            testCase.verifyThat(estimatedPower,IsEqualTo(noisePower,'Within',AbsoluteTolerance(1e-1)));
            
            estimatedPower = bandpower(PSD, F, [0 Fs/2], 'psd');
            testCase.verifyThat(estimatedPower,IsEqualTo(noisePower,'Within',AbsoluteTolerance(1e-1)));
            
        end

    end
end