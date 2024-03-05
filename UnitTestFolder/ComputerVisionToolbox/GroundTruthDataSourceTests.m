classdef GroundTruthDataSourceTests < matlab.unittest.TestCase
    % GROUNDTRUTHDATASOURCETESTS contains validation test cases for some features
    % of the Computer Vision Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc..

    %% Properties
    properties
        ImageNames          
        ImageSequenceDir
    end
    
    %% TestClassSetup Methods
    methods(TestClassSetup)
        function setup(testCase)

            testCase.ImageSequenceDir = fullfile(fileparts(mfilename('fullpath')), "GroundTruthTests", "roadSequence");

            dirList = dir(fullfile(testCase.ImageSequenceDir,'*.png'));
            testCase.ImageNames = {dirList.name};
        end %function

    end
    
    %% Test Methods
    methods(Test)
        function checkConstructFromImageDir(testcase)

            import matlab.unittest.fixtures.WorkingFolderFixture
            testcase.applyFixture(WorkingFolderFixture);
            
            % Construct datasource
            ds = groundTruthDataSource(testcase.ImageSequenceDir);
            
            % Verify source
            imds = imageDatastore(testcase.ImageSequenceDir);
            testcase.verifyEqual(ds.Source, imds.Files);
            
            % Verify timestamps
            testcase.verifyEqual(ds.TimeStamps, seconds(0 : 5)');
            
            % Construct datasource with timestamps
            ts = seconds( 1 : 6 )';
            ds = groundTruthDataSource(testcase.ImageSequenceDir, ts);
            
            % Verify source
            testcase.verifyEqual(ds.Source, imds.Files);
            
            % Verify timestamps
            testcase.verifyEqual(ds.TimeStamps, ts);

            save('foo.mat', 'ds');
            loaded = testcase.verifyWarningFree(@()load('foo.mat')); %#ok<*LOAD> 
            testcase.verifyEqual(loaded.ds.Source, ds.Source); 
        end
        
        function checkConstructFromImageNames(testcase)
            
            % Add image directory to path
            addpath(testcase.ImageSequenceDir);
            rmFromPath = onCleanup(@()rmpath(testcase.ImageSequenceDir));
            
            % Construct datasource
            ds = groundTruthDataSource(testcase.ImageNames);
            
            % Verify source
            imds = imageDatastore(testcase.ImageNames);
            testcase.verifyEqual(ds.Source, imds.Files);
            
            % Verify timestamps
            testcase.verifyEqual(ds.TimeStamps, []);
            
            % Use String
            dss = groundTruthDataSource(string(testcase.ImageNames));
            testcase.verifyEqual(ds.Source, dss.Source);
            testcase.verifyEqual(ds.TimeStamps, dss.TimeStamps);

        end
        
        function checkConstructFromImageDirAndTimeStamps(testcase)
            
            % Add image directory to path
            addpath(testcase.ImageSequenceDir);
            rmFromPath = onCleanup(@()rmpath(testcase.ImageSequenceDir));
            
            % Construct datasource
            ds = groundTruthDataSource(testcase.ImageSequenceDir, 0:5);
            
            % Verify source
            imds = imageDatastore(testcase.ImageNames);
            testcase.verifyEqual(ds.Source, imds.Files);
            
            % Verify timestamps
            testcase.verifyEqual(ds.TimeStamps,seconds(0 : 5)');
            
            % Use String
            dss = groundTruthDataSource(string(testcase.ImageSequenceDir), 0:5);
            testcase.verifyEqual(ds.Source, dss.Source);
            testcase.verifyEqual(ds.TimeStamps, dss.TimeStamps);
            
        end
        
        function checkConstructFromDatastore(testcase)
            imds = imageDatastore(fullfile(toolboxdir('vision'), 'visiondata', 'stopSignImages'));
            
            ds = groundTruthDataSource(imds);
            testcase.verifyClass(ds.Source, 'matlab.io.datastore.ImageDatastore');
            testcase.verifyEqual(numel(ds.Source.Files), numel(imds.Files));
            
        end
        
        function cellstrWithOneFile(testcase)
            % Edge case with one file
            ds = groundTruthDataSource(fullfile(testcase.ImageSequenceDir, "f00000.png"));
            testcase.verifyEqual(ds.Source, cellstr(fullfile(testcase.ImageSequenceDir, "f00000.png")));
        end
       
        function testStringAdoption(testcase)
            actRes1 = groundTruthDataSource('vipunmarkedroad.avi');
            expRes1 = groundTruthDataSource("vipunmarkedroad.avi");
            tol = 1e6*eps('double');
            testcase.verifyEqual(actRes1.TimeStamps, expRes1.TimeStamps, 'AbsTol', tol);
        end
        
        function checkUnsortedTimestamps(testcase)
            
            imageSeqFolder = fullfile(matlabroot, 'toolbox', 'vision', 'visiondata', 'bookCovers');
            timeStamps = [1, 10:19, 2, 20:29, 3, 30:39,4,40:49,5,50:58,6:9];
            
            % Make a datasource with unsorted timestamps
            dataSource = groundTruthDataSource(imageSeqFolder, timeStamps);
            
            % Verify that timestamps in groundTruthDataSource are sorted
            testcase.verifyTrue( issorted(dataSource.TimeStamps) );
            
            % Verify that file names are not mixed up
            [~, idx] = sort(timeStamps);
            imds = imageDatastore(imageSeqFolder);
            testcase.verifyEqual( dataSource.Source, imds.Files(idx) ); 
        end   

    end %methods
end %classdef