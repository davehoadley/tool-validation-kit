classdef FileIOTest < matlab.unittest.TestCase
% FILEIOTEST is an example validation test case for some features
% of the MATLAB language.  Specifically, it demonstrates reading and
% writing of textual data (as strings and numbers) and binary data (MAT
% file format).  It requires the MATLAB unit test framework as a test
% executive.
%
% Author: Dave Hoadley
% Copyright 2017 - 2018 The MathWorks, Inc.

    properties
        hReadTextFile
        hWriteTextFile
    end
 
    methods(TestClassSetup)
        function openFiles(testCase)
            testCase.hReadTextFile = fopen('.\FileIO\LowLevelAPIReadTest.txt','r');
            testCase.hWriteTextFile = fopen('.\FileIO\LowLevelAPIWriteTest.txt','w+');
        end
    end
    
    methods(TestClassTeardown)
        function closeFiles(testCase)
            if testCase.hReadTextFile ~= -1
                fclose(testCase.hReadTextFile);
            end
            if testCase.hWriteTextFile ~= -1
                fname = fopen(testCase.hWriteTextFile);
                fclose(testCase.hWriteTextFile);
                % chosing to delete the file.  Comment out if you want to
                % keep it
                if exist(fname,'file') == 2
                    delete(fname);
                end
            end
            try
                % chosing to delete the file.  Comment out if you want to
                % keep it
                if exist('.\FileIO\textWriteTest.csv','file') == 2
                    delete('.\FileIO\textWriteTest.csv');
                end
            catch
            end
            try
                % chosing to delete the file.  Comment out if you want to
                % keep it
                if exist('.\FileIO\binaryWriteTest.mat','file') == 2
                    delete('.\FileIO\binaryWriteTest.mat');
                end
            catch
            end
        end
    end

    methods(Test)
        function filepartsPoint(testCase)
            here = fileparts(mfilename("fullpath"));
            % since the test suite is portable, we only check here for a
            % partial match
            found = contains(here, ['UnitTestFolder' filesep 'Base']);
            testCase.verifyEqual(found, true, ...
                'Fileparts folder name not correct');

            filename = [here filesep 'FileIO' filesep 'formattedText.txt'];
            [~, name, ext] = fileparts(filename);
            testCase.verifyEqual(name, 'formattedText', ...
                'Fileparts file name not correct');
            testCase.verifyEqual(ext, '.txt', ...
                'Fileparts extension not correct');
        end

        function directoryPoint(testCase)
            here = fileparts(mfilename("fullpath"));
            found = exist([here filesep 'FileIO'],'dir') == 7;
            testCase.verifyEqual(found, true, ...
                'Exist on directory not valid');
            
            found = exist([here filesep 'FileIO' filesep 'formattedText.txt'],'dir') == 7;
            testCase.verifyEqual(found, false, ...
                'Exist on file as directory not valid');

            found = exist([here filesep 'TestMe'],'dir') == 7;
            testCase.verifyEqual(found, false, ...
                'Exist on missing directory not valid');

            mkdir([here filesep 'TestMe']);
            found = exist([here filesep 'TestMe'],'dir') == 7;
            testCase.verifyEqual(found, true, ...
                'Exist on new directory not valid');
            
            rmdir([here filesep 'TestMe']);
            found = exist([here filesep 'TestMe'],'dir') == 7;
            testCase.verifyEqual(found, false, ...
                'Exist on deleted directory not valid');
        end

        function fileOpenPoint(testCase)
            testCase.verifyEqual(testCase.hReadTextFile, 3, ...
                'File not opened for read access');

            testCase.verifyEqual(testCase.hWriteTextFile, 4, ...
                'File not opened for write access');

            hBadFile = fopen('.\FileIO\ShouldNotExist.txt','r');
            testCase.verifyEqual(hBadFile, -1, ...
                'Missing file not detected');
        end
        
        function textFileReadPoint(testCase)
            % Low-level file I/O API
            result = fgetl(testCase.hReadTextFile);
            lineToMatch = sprintf('%s\t%s\t%s\t%s','Test data file', '', ...
                '', '');
            testCase.verifyEqual(result, lineToMatch, ...
                'Low-level file read failed');

            result = fgetl(testCase.hReadTextFile);
            lineToMatch = sprintf('%s\t%s\t%s\t%s','Time', 'Sensor1', ...
                'Sensor2', 'Sensor3');
            testCase.verifyEqual(result, lineToMatch, ...
                'Low-level file read failed');

            result = fgetl(testCase.hReadTextFile);
            lineToMatch = sprintf('%s\t%s\t%s\t%s','0', '1.01', ...
                '6.775067751', '10');
            testCase.verifyEqual(result, lineToMatch, ...
                'Low-level file read failed');

            % CSV file API
            try
                csvread('.\FileIO\ReadTest.csv');
            catch exc
                testCase.verifyEqual(exc.identifier, 'MATLAB:textscan:handleErrorAndShowInfo', ...
                    'csvread bad range not detected');
            end
            
            result = csvread('.\FileIO\ReadTest.csv',2,0,[2,0,15,3]);
            expectedData = [0,1.01,6.775067751,10; ...
                0.25,1.257403959,2.79798545,9; ...
                0.5,1.489425539,1.356116084,8; ...
                0.75,1.69163876,1.007658202,7; ...
                1,1.851470985,0.890947969,6; ...
                1.24,1.955783999,0.885269122,5; ...
                1.5,2.007494987,0.992654358,4; ...
                1.75,1.993985947,1.311647429,3; ...
                2,1.919297427,2.54841998,1; ...
                2.25,1.788073197,9.746588694,2; ...
                2.49999999,1.608472152,1.383891555,6; ...
                2.75,1.391660992,0.681384573,7; ...
                3,1.151120008,0.427789185,4; ...
                3.5,0.659216772,0.224587881,-1];

            testCase.verifyEqual(result, expectedData, ...
                'Data mismatch for csvread, numeric range');

            result = csvread('.\FileIO\ReadTest.csv',2,0,'A3..D16');
            testCase.verifyEqual(result, expectedData, ...
                'Data mismatch for csvread, string range');
        end
        
        function textFileWritePoint(testCase)
            % Low-level file I/O API
            % write some data
            line1ToWrite = sprintf('%s\t%s\t%s','Test file write', '', ...
                '');
            fprintf(testCase.hWriteTextFile, line1ToWrite);
            fprintf(testCase.hWriteTextFile, sprintf('\n'));
            line2ToWrite = sprintf('%s\t%s\t%s','Scan', 'data1', ...
                'data2');
            fprintf(testCase.hWriteTextFile, line2ToWrite);
            fprintf(testCase.hWriteTextFile, sprintf('\n'));
            line3ToWrite = sprintf('%s\t%s\t%s','4.1', '0.01', ...
                '22.4');
            fprintf(testCase.hWriteTextFile, line3ToWrite);
            fprintf(testCase.hWriteTextFile, sprintf('\n'));
            line4ToWrite = sprintf('%s\t%s\t%s','-53', '99.999', ...
                '-1');
            fprintf(testCase.hWriteTextFile, line4ToWrite);
            fprintf(testCase.hWriteTextFile, sprintf('\n'));

            %now reset the file pointer to start of file and re-read
            frewind(testCase.hWriteTextFile);
            result = fgetl(testCase.hWriteTextFile);
            testCase.verifyEqual(result, line1ToWrite, ...
                'Low-level file read failed');

            result = fgetl(testCase.hWriteTextFile);
            testCase.verifyEqual(result, line2ToWrite, ...
                'Low-level file read failed');

            result = fgetl(testCase.hWriteTextFile);
            testCase.verifyEqual(result, line3ToWrite, ...
                'Low-level file read failed');

            result = fgetl(testCase.hWriteTextFile);
            testCase.verifyEqual(result, line4ToWrite, ...
                'Low-level file read failed');

            % CSV file API
            dataToWrite = [-1, 17.2, 1.0522E8; 0, 7.9999, 31];
            csvwrite('.\FileIO\textWriteTest.csv',dataToWrite);
            readBackData = csvread('.\FileIO\textWriteTest.csv');
            testCase.verifyEqual(dataToWrite, readBackData, ...
                    'csvwrite test failed');
        end
        function MATFileReadPoint(testCase)
            % Expected results
            w_match = 'This string is a test';  % string
            t_match = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10];  % column vector
            x_match = [1.0000 1.0101 1.0411 1.0957 1.1788 1.2984 1.4680 1.7094 ...
                2.0602 2.588 3.4255]; % row vector
            y_match = [0.6551, 0.4984, 0.5853, 0.2551; 0.1626, 0.9597, 0.2238, 0.5060; ...
                0.1190, 0.3404, 0.7513, 0.6991];  % array
            z_match = -33.00000008;  % scalar
            c_match = {t_match, w_match, z_match};  % cell array
            
            load('.\FileIO\binaryReadTest');
            
            testCase.verifyEqual(w, w_match, ...
                'Binary file read failed for string');
            testCase.verifyEqual(t, t_match, ...
                'Binary file read failed for column vector');
            testCase.verifyEqual(x, x_match, ...
                'Binary file read failed for row vector');
            testCase.verifyEqual(y, y_match, ...
                'Binary file read failed for array');
            testCase.verifyEqual(z, z_match, ...
                'Binary file read failed for scalar');
            for idx = 1:length(c_match)
                testCase.verifyEqual(c{idx}, c_match{idx}, ...
                    'Binary file read failed for cell array');
            end
        end
        function MATFileWritePoint(testCase)
            % store some known data to disk, re-read it to verify operation
            rng(0)
            a = 'This string is another test';  % string
            b = [-1; -100; -1000];  % column vector
            c = [1, 1, 2, 3, 5, 8, 11]; % row vector
            d = 50 * rand(5,7) + 11;  % array
            e = -1.5E-11;  % scalar
            f = {e, a, c};  % cell array

            save('.\FileIO\binaryWriteTest','a','b','c','d','e','f');

            % store for expected results, then clear
            a_match = a;
            clear('a');
            b_match = b;
            clear('b');
            c_match = c;
            clear('c');
            d_match = d;
            clear('d');
            e_match = e;
            clear('e');
            f_match = f;
            clear('f');
            
            % re-load
            load('.\FileIO\binaryWriteTest');
            
            testCase.verifyEqual(a, a_match, ...
                'Binary file read failed for string');
            testCase.verifyEqual(b, b_match, ...
                'Binary file read failed for column vector');
            testCase.verifyEqual(c, c_match, ...
                'Binary file read failed for row vector');
            testCase.verifyEqual(d, d_match, ...
                'Binary file read failed for array');
            testCase.verifyEqual(e, e_match, ...
                'Binary file read failed for scalar');
            for idx = 1:length(f_match)
                testCase.verifyEqual(f{idx}, f_match{idx}, ...
                    'Binary file read failed for cell array');
            end
        end %function

        function infoGraphicsFile(testCase)

            info = imfinfo('ngc6543a.jpg');

            testCase.verifyEqual(info.CodingMethod, 'Huffman', "Validate correct coding method");

        end %function

        function testimwrite(testCase)

            import matlab.unittest.fixtures.WorkingFolderFixture

            testCase.applyFixture(WorkingFolderFixture);

            imageExpFilePath = fullfile(fileparts(mfilename("fullpath")), "FileIO", "myGray.png");
            expVal = imread(imageExpFilePath);

            rng(0)
            A = rand(50);
            imwrite(A,'myGray.png')

            actVal = imread("myGray.png");

            testCase.verifyTrue(isequal(actVal, expVal), "Validate image file write")

        end %function

        function readWriteCellPoint(testCase)
            
            here = fileparts(mfilename("fullpath"));
            filename = [here filesep 'FileIO' filesep 'testbook1.xlsx'];
            resp1 = readcell(filename);
            resp2 = readcell(filename,'Sheet','test1');
            resp3 = readcell(filename,'Sheet','test2');

            testCase.verifyEqual(resp1, {'This is a test workbook'; 'It has 2 sheets'}, ...
                'Validate readcell');

            testCase.verifyEqual(resp2, {'This is a test workbook'; 'It has 2 sheets'}, ...
                'Validate readcell');

            testCase.verifyEqual(resp3, [{1} {6}; {2} {7}; {3} {8}; {4} {9}; {5} {10}], ...
                'Validate readcell');

            filename = [here filesep 'FileIO' filesep 'testbook2.xlsx'];
            cellArray = {'strings' 'to' 'write';'in' 'excel' 'sheet'};
            writecell(cellArray, filename,  'Sheet', 'testcase');
            
            resp4 = readcell(filename,'Sheet','testcase');
            testCase.verifyEqual(resp4, cellArray, ...
                'Validate writecell');

            delete(filename);
        end

        function textscanPoint(testCase)
            here = fileparts(mfilename("fullpath"));
            filename = [here filesep 'FileIO' filesep 'formattedText.txt'];

            file = fopen(filename);
            allData = textscan(file, '%s', 'delimiter', '\n');
            fclose(file);

            testCase.verifyEqual(allData{1}{1}, 'Header line', 'verify textscan reads a string');
            testCase.verifyEqual(allData{1}{2}, 'Data line 112358', 'verify textscan reads a string');
            testCase.verifyEqual(allData{1}{3}, 'EOF', 'verify verify textscan reads a string');
        end

        function freadPoint(testCase)
            here = fileparts(mfilename("fullpath"));
            filename = [here filesep 'FileIO' filesep 'formattedText.txt'];
            fileID = fopen(filename,'r');
            data = fread(fileID, [1 inf], '*char');
            fclose(fileID);

            expectedData = ['Header line' char(13) newline 'Data line 112358' char(13) newline 'EOF'];

            testCase.verifyEqual(data, expectedData, 'verify fread reads a char array');
        end
    end %methods
end %classdef