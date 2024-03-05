classdef GroundTruthTests < matlab.unittest.TestCase
    % GROUNDTRUTHTESTS contains validation test cases for some features
    % of the Computer Vision Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.
    
    %% Test Methods
    methods(Test)
        function dataSourceIsImageDatastore(test)
            % SHOULD be able to create a groundTruth object using an
            % imageDatastore.
            
            [defs, data] = iRectangleLabelDefAndDataForTwoImages();
            
            gds = iCreateGroundTruthDataSource();
            gt = groundTruth(gds, defs, data);
            
            test.verifyEqual(gt.DataSource,gds);
            
            % label data should be a table
            test.verifyClass(gt.LabelData, 'table');
            
            test.verifyEqual(gt.LabelDefinitions, defs);
            test.verifyEqual(gt.LabelData, data);
            
        end
        
        function hasOnlyPixelLabelType(test)
            % SHOULD be able to create gTruth for just pixel labeled ground
            % truth.
            [defs, data] = iPixelLabelDefAndDataForTwoImages();
            
            gds = iCreateGroundTruthDataSource();
            gt = groundTruth(gds, defs, data);
            
            % when there are pixel labels only, the width of the label data
            % table is 1.
            test.verifyEqual(width(gt.LabelData), 1)
            
            test.verifyEqual(gt.LabelDefinitions.Properties.VariableNames, {'Name','Type','PixelLabelID','Group'});
            
            test.verifyEqual(gt.LabelDefinitions, defs);
            test.verifyEqual(gt.LabelData, data);
            
        end
        
        function mixedRectangleAndPixelLabel(test)
            % SHOULD be able to create a groundTruth object to hold mixed
            % label types.
            [defs, data] = iMixedLabelDefAndDataForTwoImages();

            gds = iCreateGroundTruthDataSource();
            gt = groundTruth(gds, defs, data);
            
            test.verifyEqual(gt.LabelDefinitions.Properties.VariableNames, ...
                {'Name', 'Type', 'PixelLabelID', 'Group'});
            
            test.verifyTrue(isequal(gt.LabelDefinitions, defs));
            test.verifyEqual(gt.LabelData, data);
            
        end
        
        function pixelLabelIDIsRGBTriplet(test)
            % SHOULD be able to use RGB triplet values as pixel label ID.
            
            [defs, data] = iPixelLabelDefAndDataForTwoImages();
            
            % define label id using RGB triplet
            defs.PixelLabelID{1} = [0 0 0; 1 1 1];
            defs.PixelLabelID{2} = [2 2 2];
            
            gds = iCreateGroundTruthDataSource();
            gt = groundTruth(gds, defs, data);
            
            % when there are pixel labels only, the width of the label data
            % table is 1.
            test.verifyEqual(width(gt.LabelData), 1)
            
            test.verifyEqual(gt.LabelDefinitions.Properties.VariableNames, {'Name','Type','PixelLabelID', 'Group'});
            
            test.verifyEqual(gt.LabelDefinitions, defs);
            test.verifyEqual(gt.LabelData, data);
        end
        
        function savesAndLoadsScalarPixelLabelIDs(test)
            % SHOULD be able to save and load gTruth.

            import matlab.unittest.fixtures.WorkingFolderFixture
            test.applyFixture(WorkingFolderFixture);
            
            [defs, data] = iPixelLabelDefAndDataForTwoImages();
            
            % define scalar pixel label ID
            defs.PixelLabelID{1} = 1;
            defs.PixelLabelID{2} = 2;
            
            gds = iCreateGroundTruthDataSource();
            gt = groundTruth(gds, defs, data);
           
            imwrite(ones(10,10),'foo.png');
            imwrite(ones(10,10),'bar.png');
            save foo gt
            
            loaded = test.verifyWarningFree(@()load('foo.mat')); %#ok<*LOAD> 
            
            test.verifyEqual(gt, loaded.gt);
            
        end
       
         function savesAndLoadsNonScalarPixelLabelIDs(test)
            % SHOULD be able to save and load gTruth.

            import matlab.unittest.fixtures.WorkingFolderFixture
            test.applyFixture(WorkingFolderFixture);
            
            [defs, data] = iPixelLabelDefAndDataForTwoImages();
            
            % define scalar pixel label ID
            defs.PixelLabelID{1} = 1;
            defs.PixelLabelID{2} = [2;3];
            
            gds = iCreateGroundTruthDataSource();
            gt = groundTruth(gds, defs, data);
           
            imwrite(ones(10,10),'foo.png');
            imwrite(ones(10,10),'bar.png');
            save foo gt
            
            loaded = test.verifyWarningFree(@()load('foo.mat'));
            
            test.verifyEqual(gt, loaded.gt);
            
         end
       
         function savesAndLoadsMixedLabelTypes(test)
            % SHOULD be able to save and load gTruth.

            import matlab.unittest.fixtures.WorkingFolderFixture
            test.applyFixture(WorkingFolderFixture);
            
            [defs, data] = iMixedLabelDefAndDataForTwoImages(); 
            
            gds = iCreateGroundTruthDataSource();
            gt = groundTruth(gds, defs, data);
           
            imwrite(ones(10,10),'foo.png');
            imwrite(ones(10,10),'bar.png');
            save foo gt
            
            loaded = test.verifyWarningFree(@()load('foo.mat'));
            
            test.verifyEqual(gt, loaded.gt);
            
         end
        
         function selectLabels(test)

             [defs, data] = iMixedLabelDefAndDataForTwoImages(); 
            
            gds = iCreateGroundTruthDataSource();
            gt = groundTruth(gds, defs, data);
            
            % select by type
            gtpx = gt.selectLabelsByType(labelType.PixelLabel);
            
            test.verifyEqual(gtpx.DataSource, gt.DataSource);
            test.verifyEqual(gtpx.LabelDefinitions, gt.LabelDefinitions([2,4],:))
            test.verifyEqual(gtpx.LabelData,gt.LabelData(:,'PixelLabelData'));
            
            gtpx = gt.selectLabelsByGroup('Pixel');
            test.verifyEqual(gtpx.DataSource, gt.DataSource);
            test.verifyEqual(gtpx.LabelDefinitions, gt.LabelDefinitions([2,4],:))
            test.verifyEqual(gtpx.LabelData,gt.LabelData(:,'PixelLabelData'));

         end
   
    end %methods
end %classdef

%% Local Functions
function [def, labelData] = iRectangleLabelDefAndDataForTwoImages()
names = {'Cars'; 'People'};
types = [labelType('Rectangle'); labelType('Rectangle')];
groups = {'None'; 'None'};
def = table(names, types, groups, 'VariableNames', {'Name', 'Type', 'Group'});

% Add 2 car labels and 2 lane markers to the first frame.
carsTruth{1} = [182 186 31 22; 404 191 53 34];
carsTruth{2} = carsTruth{1};

peopleTruth{1} = [182 186 31 22; 404 191 53 34];
peopleTruth{2} = peopleTruth{1};

% Construct table of label data
labelData = table(carsTruth', peopleTruth', 'VariableNames', names);

end


function [def, labelData] = iPixelLabelDefAndDataForTwoImages()
names = {'Cars'; 'People'};
types = [labelType('PixelLabel'); labelType('PixelLabel')];
groups = {'None'; 'None'};
pxid  = {1; [2;3]};
def = table(names, types, pxid, groups,'VariableNames', {'Name', 'Type', 'PixelLabelID', 'Group'});

% Add 2 car labels and 2 lane markers to the first frame.
truth{1} = 'foo.png';
truth{2} = 'bar.png';

% Construct table of label data. only 1 column
labelData = table(truth', 'VariableNames', {'PixelLabelData'});

end

function [def, labelData] = iMixedLabelDefAndDataForTwoImages()
names = {'Cars'; 'People'; 'Road'; 'Lane'};
types = [labelType('Rectangle'); labelType('PixelLabel'); labelType('Rectangle'); labelType('PixelLabel')];
groups = {'Rectangle'; 'Pixel'; 'Rectangle'; 'Pixel'};
pxid  = {[]; 1; []; [2;3]};
def = table(names, types, pxid, groups, 'VariableNames', {'Name', 'Type', 'PixelLabelID', 'Group'});

% Add 2 car labels and 2 lane markers to the first frame.
carsTruth{1} = [182 186 31 22; 404 191 53 34];
carsTruth{2} = carsTruth{1};

peopleTruth{1} = [182 186 31 22; 404 191 53 34];
peopleTruth{2} = peopleTruth{1};

truth{1} = 'foo.png';
truth{2} = 'bar.png';

% Construct table of label data, order shouldn't matter
labelData = table(carsTruth', truth', peopleTruth', 'VariableNames', {'Cars', 'PixelLabelData', 'Road'});

end

function gds = iCreateGroundTruthDataSource()

dataPath = fullfile(fileparts(mfilename('fullpath')), "GroundTruthTests", "roadSequence");

imds = imageDatastore(dataPath);
imds.Files = imds.Files(1:2); % just 2 b/c that's what the data has.
gds = groundTruthDataSource(imds.Files);
end