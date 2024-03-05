classdef DatastoreTest < matlab.unittest.TestCase
    % DATASTORETEST is an example validation test case for some features
    % of the MATLAB language.  This sample is intended to show how the user can
    % create additional tests to be executed.
    %
    % Copyright 2022 The MathWorks, Inc.
    
    methods(Test)
        
        function imdsBasicMethods(testCase)
            % Test basic image datastore methods

            fs = matlab.io.datastore.FileSet(["street1.jpg","street2.jpg"]);
            imds = imageDatastore(fs);

            street1gTruth = imread("street1.jpg");
            street2gTruth = imread("street2.jpg");

            testCase.verifyTrue(hasdata(imds), "Validate hasdata method of datastore is true")

            street1 = read(imds);
            % Using verifyTrue since verifyEqual prints out full multi-dim
            % array in report
            testCase.verifyTrue(isequal(street1, street1gTruth), "Validate read method of datastore matches ground truth image");

            testCase.verifyTrue(hasdata(imds), "Validate hasdata method of datastore is true")

            street2 = read(imds);
            testCase.verifyTrue(isequal(street2, street2gTruth), "Validate read method of datastore matches ground truth image");

            testCase.verifyFalse(hasdata(imds), "Validate hasdata method of datastore is false") %no data left in imds

            reset(imds)
            allImages = readall(imds);
            testCase.verifyTrue(isequal(allImages, {street1gTruth; street2gTruth}), "Validate readall method of datastore matches ground truth images");

        end %function

        function transformDatastore(testCase)
            % Verify transform method of image datastore

            imds = imageDatastore({'street1.jpg','peppers.png'});

            targetSize = [224,224];

            imdsReSz = transform(imds,@(x) imresize(x,targetSize)); %testCase.verifyWarningFree(@() transform(imds,@(x) imresize(x,targetSize)));

            imgReSz1 = read(imdsReSz);
            imgReSz2 = read(imdsReSz);

            testCase.verifyEqual(size(imgReSz1), [targetSize, 3], "Validate transform method matches target size of ground truth image");
            testCase.verifyEqual(size(imgReSz2), [targetSize, 3], "Validate transform method matches target size of ground truth image");

        end %function
   
    end %methods
end %classdef