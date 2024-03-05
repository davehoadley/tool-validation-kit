classdef ImageProcessingTest < matlab.unittest.TestCase
    % IMAGEPROCESSINGTEST contains validation test cases for some features
    % of the Image Processing Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.

    properties
        X
        map
    end

    methods(Static)

        function plotBWDistResponse(D1, D2, D3, D4)

            RGB1 = repmat(rescale(D1), [1 1 3]);
            RGB2 = repmat(rescale(D2), [1 1 3]);
            RGB3 = repmat(rescale(D3), [1 1 3]);
            RGB4 = repmat(rescale(D4), [1 1 3]);

            figure("Color", "W")
            tiledlayout("flow")

            nexttile()
            imshow(RGB1), title('Euclidean')
            hold on, imcontour(D1)
            nexttile()
            imshow(RGB2), title('Cityblock')
            hold on, imcontour(D2)
            nexttile()
            imshow(RGB3), title('Chessboard')
            hold on, imcontour(D3)
            nexttile()
            imshow(RGB4), title('Quasi-Euclidean')
            hold on, imcontour(D4)

        end %function

    end %methods

    methods(Test)
        function mat2grayTest(testCase)
            % This section should verify the expected results match the actual
            % results.

            I = imread('rice.png');

            J = filter2(fspecial('sobel'),I);

            output = mat2gray(J);

            % Load results
            contents = load("mat2grayResults.mat");

            % Verifications
            testCase.verifyTrue(isequal(output, contents.K), ...
                @() imshowpair(output, contents.K, 'montage'))
            testCase.verifyEqual(min(output(:)), contents.min_image, "AbsTol", 0.1, ...
                "Verify minimum value of mat2gray on input image")
            testCase.verifyEqual(max(output(:)), contents.max_image, "AbsTol", 0., ...
                "Verify maximum value of mat2gray on input image")

        end %function

        function montageTest(testCase)
            % A figure can show up in the final report

            [testCase.X , testCase.map] = imread('trees.tif');

            %Check all syntaxes
            inputx = testCase.X;
            inputx = imresize(inputx, 0.25,'nearest','antialiasing',false);
            X2 = flipud(inputx);
            inputx = cat(4, inputx, X2, inputx, X2, inputx, X2, inputx);
            
            I = reshape(ind2gray(inputx(:,:),testCase.map), [65 88 1 7]);
            I8 = uint8(round(I*255));
            
            RGB = zeros([65 88 3 7]);
            for k = 1:7
                RGB(:,:,:,k) = ind2rgb(inputx(:,:,:,k),testCase.map);
            end

            L = I8 < 100;
            fig1 = figure(); % Close opened figures
            h = montage(L, 'ThumbnailSize', []);
            f1 = onCleanup(@() close(fig1));
            act = size(get(h, 'cdata'));
            exp = [size(L,1)*3 size(L,2)*3];
            testCase.verifyTrue(isequal(act,exp), "Verify size of montage matches ground truth image");
            
            fig2 = figure();
            h = montage(L,testCase.map, 'ThumbnailSize', []);
            f2 = onCleanup(@() close(fig2)); % Close opened figures
            act = size(get(h,'cdata'));
            exp = [size(L,1)*3 size(L,2)*3];
            testCase.verifyTrue(isequal(act(1:2),exp), "Verify size of montage with map input matches ground truth image");
            
            % logical data, regression test for g330946
            fig15 = figure();
            h = montage(logical(eye(10)), 'ThumbnailSize', []);
            f15 = onCleanup(@() close(fig15)); % Close opened figures
            act = get(h,'cdata');
            exp = logical(eye(10));
            testCase.verifyTrue(isequal(act,exp), "Verify size of montage with logical data matches ground truth image");

        end %function

        function labeloverlayTest(testCase)
            % LABELOVERLAYTEST Unit tests for the labeloverlay function

            import matlab.unittest.constraints.IsEqualTo

            % Visualize segmentation over color image
            A = imread('kobi.png');
            [L,~] = superpixels(A,20);

            B = labeloverlay(A,L);

            contents = imread("kobiLO.png");
            testCase.verifyTrue(isequal(B, contents),  @() imshowpair(B, contents, 'montage'));

            % Visualize binary mask over grayscale image
            A = imread('coins.png');
            t = graythresh(A);
            BW = imbinarize(A,t);
            B = labeloverlay(A,BW);

            contents = imread("coinsLO.png");
            testCase.verifyTrue(isequal(B, contents), @() imshowpair(B, contents, 'montage'));

            % Visualize categorical labels over image
            A = imread('coins.png');
            BW = imbinarize(A);

            stringArray = repmat("table",size(BW));
            stringArray(BW) = "coin";
            categoricalSegmentation = categorical(stringArray);

            C = labeloverlay(A,categoricalSegmentation,'IncludedLabels',"coin", ...
                'Colormap','autumn','Transparency',0.25);

            contents = imread("coinsLOCategorical.png");
            testCase.verifyTrue(isequal(C, contents), @() imshowpair(C, contents, 'montage'));

        end %function

        function dicomreadVolumeTest(testCase)

            here = fileparts(mfilename("fullpath"));
            [V,spatial,dim] = dicomreadVolume(fullfile(here,"ImageProcessingTest/dog"));
            V = squeeze(V);

            contents = load("dicomreadResults.mat");

            testCase.verifyEqual(dim, contents.dim, "Verify correct dicom image dimensions");
            testCase.verifySize(size(V), [1 3], "Verify correct dicom image size")
            testCase.verifyTrue(isequal(V, contents.V), "Verify dicom image matches ground truth")
            testCase.verifyTrue(isequal(spatial, contents.spatial), "Verify correct spatial structure output")

        end %function

        function adjustIntensityValuesTest(testCase)

            % Adjust contrast of grayscale image
            I = imread('pout.tif');
            J = imadjust(I);

            contents = imread("poutimadjustStandard.png");
            testCase.verifySize(size(J), [1, 2], "Verify adjusted image size matches ground truth")
            testCase.verifyTrue(isequal(J, contents), "Verify adjusted image matches ground truth")

            % Adjust contrast of grayscale image by specifying contrast
            % limits
            K = imadjust(I,[0.3 0.7],[]);

            contents = imread("poutimadjustContrastLims.png");
            testCase.verifySize(size(J), [1, 2], "Verify adjusted image size matches ground truth")
            testCase.verifyTrue(isequal(K, contents), "Verify adjusted image matches ground truth")

            % Standard Deviation Based Image Stretching
            n = 2;
            Idouble = im2double(I);
            avg = mean2(Idouble);
            sigma = std2(Idouble);

            L = imadjust(I,[avg-n*sigma avg+n*sigma],[]);

            contents = imread("poutimadjustSTDStretch.png");
            testCase.verifySize(size(L), [1, 2], "Verify adjusted image size matches ground truth")
            testCase.verifyTrue(isequal(L, contents), "Verify adjusted image matches ground truth")

            % Scale intensity of 3-D volume of MRI data (imadjustn)
            mristack = load("mristack");
            V1 = im2double(mristack.mristack);
            V2 = imadjustn(V1,[0.2 0.8],[]);

            contents = load("mristackAdjust.mat");
            testCase.verifyTrue(isequal(V2, contents.V2), "Verify adjusted image matches ground truth");

        end %function

        function guassianFiltTest(testCase)

            % 2D Gaussian Filtering
            I = imread('cameraman.tif');
            Iblur = imgaussfilt(I,2);

            IblurResult = imread("cameramanGuassFilt.png");
            testCase.verifySize(size(Iblur), [1, 2], "Verify correct size of 2D guassian filter on input image")
            testCase.verifyTrue(isequal(Iblur, IblurResult), @() imshowpair(Iblur, IblurResult, 'montage'))

            % 3D Guassian Filtering
            vol = load('mri');

            vol = squeeze(vol.D);
            sigma = 2;

            volSmooth = imgaussfilt3(vol, sigma);

            volSmoothResults = load("mriVolume3DGuassFilt.mat");

            testCase.verifySize(size(volSmooth), [1,3], "Verify correct size of 3D guassian filter on input image")
            testCase.verifyTrue(isequal(volSmooth, volSmoothResults.volSmooth))

        end %function

        function imfillTest(testCase)
            %IMFILLTEST Unit tests for imfill()

            % Fill holes in binarized image
            I = imread('coins.png');
            BW = imbinarize(I);
            BW2 = imfill(BW,'holes');

            contents = load("imfillResults.mat");

            testCase.verifyTrue(isequal(BW2, contents.BW2), ...
                @() imshowpair(BW2, contents.BW2, 'montage'));

            % Fill image from specified starting point

            bwGT = [
                1   0   0   0   0   0   0   0
                1   1   1   1   1   0   0   0
                1   1   1   1   1   0   1   0
                1   1   1   1   1   1   1   0
                1   1   1   1   1   1   1   1
                1   0   0   1   1   1   1   0
                1   0   0   0   1   1   1   0
                1   0   0   0   1   1   1   0];

            BW1 = logical([1 0 0 0 0 0 0 0
                1 1 1 1 1 0 0 0
                1 0 0 0 1 0 1 0
                1 0 0 0 1 1 1 0
                1 1 1 1 0 1 1 1
                1 0 0 1 1 0 1 0
                1 0 0 0 1 0 1 0
                1 0 0 0 1 1 1 0]);

            BW2 = imfill(BW1,[3 3],8);

            testCase.verifyTrue(isequal(BW2, bwGT), @() imshowpair(BW2, bwGT, 'montage'));

        end %function

        function bwperimTest(testCase)
            % BWPERIMTEST Unit tests for bwperim()

            import matlab.unittest.constraints.IsTrue
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic

            BW = imread('circles.png');
            BW2 = bwperim(BW, 8);

            contents = load("bwperimResults.mat");

            testCase.verifyThat(isequal(BW2, contents.BW2), IsTrue, ...
                @() imshowpair(contents.BW2,BW2,'montage'));

        end %function

        function bwdistTest(testCase)
            % BWDISTTEST Unit tests for bwdist()

            import matlab.unittest.constraints.IsTrue
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic

            bw = zeros(200,200);
            bw(50,50) = 1; bw(50,150) = 1; bw(150,100) = 1;
            D1 = bwdist(bw,'euclidean');
            D2 = bwdist(bw,'cityblock');
            D3 = bwdist(bw,'chessboard');
            D4 = bwdist(bw,'quasi-euclidean');

            contents = load("bwdistResults.mat");

            flag = (isequal(D1, contents.D1)) && (isequal(D2, contents.D2)) && ...
                (isequal(D3, contents.D3)) && (isequal(D4, contents.D4));

            testCase.verifyThat(flag, IsTrue, ...
                @() ImageProcessingTest.plotBWDistResponse(D1, D2, D3, D4))

        end %function

        function imbinarizeTest(testCase)
            % IMBINARIZETEST Unit tests for imbinarize()

            import matlab.unittest.constraints.IsTrue
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic

            I = imread('coins.png');
            BW = imbinarize(I);

            contents = load("imbinarizeResults.mat");

            testCase.verifyThat(isequal(BW, contents.BW), IsTrue, ...
                @() imshowpair(I,BW,'montage'))

        end %function

        function strelTest(testCase)
            % STRELTEST Unit tests for strel()

            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic

            contents = load("strelResults.mat");

            SE = strel('square', 11);
            SE1 = strel('line', 10, 45);
            SE2 = strel('disk', 4);
            SE3 = strel('sphere', 15);

            testCase.verifyThat(SE, IsEqualTo(contents.SE), @() imshowpair(SE.Neighborhood,contents.SE.Neighborhood,"montage"));
            testCase.verifyThat(SE1, IsEqualTo(contents.SE1), @() imshowpair(SE1.Neighborhood,contents.SE1.Neighborhood,"montage"));
            testCase.verifyThat(SE2, IsEqualTo(contents.SE2), @() imshowpair(SE2.Neighborhood,contents.SE2.Neighborhood,"montage"));
            testCase.verifyThat(SE3, IsEqualTo(contents.SE3), "Verify correct 3D spherical structing element");

        end %function

        function imcloseTest(testCase)
            % IMCLOSETEST Unit tests for imclose()

            import matlab.unittest.constraints.IsTrue
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic

            originalBW = imread('circles.png');
            se = strel('disk',10);
            closeBW = imclose(originalBW,se);

            contents = load("imcloseResults.mat");

            testCase.verifyThat(isequal(closeBW, contents.closeBW), IsTrue, ...
                @() imshowpair(closeBW, contents.closeBW,"montage"))

        end %function

        function bwconncompTest(testCase)
            % BWCONNCOMPTEST Unit tests for bwconncomp()

            import matlab.unittest.constraints.IsEqualTo

            BW = cat(3, [1 1 0; 0 0 0; 1 0 0],...
                [0 1 0; 0 0 0; 0 1 0],...
                [0 1 1; 0 0 0; 0 0 1]);

            CC = bwconncomp(BW);

            contents = load("bwconncompResults.mat");

            testCase.verifyThat(CC, IsEqualTo(contents.CC), "Verify correct connected components structure");

        end %function

        function regionpropsTest(testCase)
            % REGIONPROPSTEST Unit tests for regionprops()

            import matlab.unittest.constraints.IsEqualTo

            BW = cat(3, [1 1 0; 0 0 0; 1 0 0],...
                [0 1 0; 0 0 0; 0 1 0],...
                [0 1 1; 0 0 0; 0 0 1]);

            CC = bwconncomp(BW);

            S = regionprops(CC,'Area');

            contents = load("regionpropsResults.mat");

            testCase.verifyThat(S(1), IsEqualTo(contents.S(1)), "Verify correct properties of image regions");
            testCase.verifyThat(S(2), IsEqualTo(contents.S(2)), "Verify correct properties of image regions");

        end %function

        function labelmatrixTest(testCase)
            %LABELMATRIXTEST Unit tests for labelmatrix()

            import matlab.unittest.constraints.IsTrue
            import matlab.unittest.constraints.IsEqualTo

            BW = imread('text.png');

            CC = bwconncomp(BW);
            L = labelmatrix(CC);

            contents = load("labelmatrixResults.mat");

            testCase.verifyThat(isequal(L, contents.L), IsTrue, ...
                @() imshowpair(L, contents.L, "montage"))
            testCase.verifyThat(double(max(L(:))), IsEqualTo(88), "Verify correct max value of label matrix");

        end %function

        function jitterColorHSVTest(testCase)
            %JITTERCOLORHSVTEST Unit tests for jitterColorHSV()

            import matlab.unittest.constraints.IsTrue
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic

            I = imread('kobi.png');

            rng(0) % set random generator seed for reproducibility
            J1 = jitterColorHSV(I,'Contrast',0.4,'Hue',0.1,'Saturation',0.2,'Brightness',0.3);
            J2 = jitterColorHSV(I,'Contrast',0.4,'Hue',0.1,'Saturation',0.2,'Brightness',0.3);
            J3 = jitterColorHSV(I,'Contrast',0.4,'Hue',0.1,'Saturation',0.2,'Brightness',0.3);

            contents = load("jitterColorHSVResults.mat");

            testCase.verifyThat(isequal(J1, contents.J1), IsTrue, ...
                @() imshowpair(J1, contents.J1, "montage"))
            testCase.verifyThat(isequal(J2, contents.J2), IsTrue, ...
                @() imshowpair(J2, contents.J2, "montage"))
            testCase.verifyThat(isequal(J3, contents.J3), IsTrue, ...
                @() imshowpair(J3, contents.J3, "montage"))

        end %function

        function imnoiseTest(testCase)
            %IMNOISETEST Unit tests for imnoise()

            import matlab.unittest.constraints.IsTrue
            import matlab.unittest.diagnostics.FunctionHandleDiagnostic

            I = imread('eight.tif');

            rng(0) % set random generator seed for reproducibility
            J = imnoise(I,'gaussian',0, rand(1)*.01);

            contents = load("imnoiseResults.mat");

            testCase.verifyThat(isequal(J, contents.J), IsTrue, ...
                @() imshowpair(J, contents.J, "montage"))

        end %function

        function rgblabTests(testCase)
            %RGBLABTESTS Unit tests for rgb2lab() and lab2rgb()

            lab = rgb2lab([1 1 1]);
            rgb = lab2rgb([70 5 10]);

            testCase.verifyEqual(lab, [100 0 0], "AbsTol", 0.01, "Verify rgb2lab correct output")
            testCase.verifyEqual(rgb, [0.7359 0.6566 0.6010], "AbsTol", 0.01, "Verify lab2rgb correct output")

        end %function

        function im2uint8Tests(testCase)
            %IM2UINT8TESTS Unit tests for im2uint8()

            I = reshape(uint16(linspace(0,65535,25)),[5 5]);
            I2 = im2uint8(I);

            result = uint8([ ...
                0    53   106   159   213
                11    64   117   170   223
                21    74   128   181   234
                32    85   138   191   244
                43    96   149   202   255]);

            testCase.verifyEqual(I2, result, "AbsTol", 0.01, "Verify im2uint8 correct output")

        end %function

        function imdilateTests(testCase)
            %IMDILATETESTS Unit tests for imdilate()

            import matlab.unittest.constraints.IsEqualTo;
            import matlab.unittest.constraints.AbsoluteTolerance;

            % verify output for binary image using a ones(3) nhood
            I = logical([
                1 0 0 0 0 0 0
                1 1 1 1 1 0 0
                1 0 1 1 1 0 0
                1 1 0 0 1 1 0
                1 1 0 0 0 1 0
                0 0 0 0 0 0 0]);
            act = imdilate(I, uint16(ones(3)));
            expec = logical([
                1 1 1 1 1 1 0
                1 1 1 1 1 1 0
                1 1 1 1 1 1 1
                1 1 1 1 1 1 1
                1 1 1 1 1 1 1
                1 1 1 0 1 1 1]);
            testCase.verifyEqual(act, expec, "Verify output for binary image using a ones(3) nhood");
            
            I = logical([
                0 0 0 0
                0 1 0 0
                0 0 0 0
                0 0 0 0]);
            act = imdilate(I, strel(ones(3)));
            expec = logical([
                1 1 1 0
                1 1 1 0
                1 1 1 0
                0 0 0 0]);
            testCase.verifyEqual(act, expec, "Verify output for binary image using a ones(3) nhood");
            
            act = imdilate([],strel(ones(3)));
            expec = [];
            testCase.verifyEqual(act, expec, "Verify output for binary image using a ones(3) nhood");

        end %function

        function imref3dTests(testCase)
            %IMREF3DTESTS Unit tests for imref3d()

            %% Defaults
                        
            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.AbsoluteTolerance

            % Verify parameter values and method behaviors for the default
            % imref object.
            % Default constructor
            R = imref3d();

            % Check if the properties are as expected
            expectedProperties = {  'XWorldLimits';
                'YWorldLimits';
                'ZWorldLimits';
                'ImageSize';
                'PixelExtentInWorldX';
                'PixelExtentInWorldY';
                'PixelExtentInWorldZ';
                'ImageExtentInWorldX';
                'ImageExtentInWorldY';
                'ImageExtentInWorldZ';
                'XIntrinsicLimits';
                'YIntrinsicLimits';
                'ZIntrinsicLimits'};

            testCase.verifyTrue(isequal(numel(expectedProperties),numel(properties(R))),...
                'Implementation of IMREF3D does not have expected number of properties');

            testCase.verifyTrue(isempty(setdiff(expectedProperties,properties(R))),...
                'Implementation of IMREF3D does not match list of expected properties.');

            expectedMethods = { 'contains'
                'imref3d'
                'intrinsicToWorld'
                'sizesMatch'
                'worldToIntrinsic'
                'worldToSubscript'};

            testCase.verifyTrue(isempty(setdiff(expectedMethods,methods(R))),...
                'Implementation of IMREF3D does not match list of expected methods.');

            % Verify property values ----------------------------------------

            expectedPropertyVals = {[0.5 2.5] %'XWorldLimits';
                [0.5 2.5] %'YWorldLimits';
                [0.5 2.5] %'ZWorldLimits';
                [2 2 2]   %'ImageSize';
                1         %'PixelExtentInWorldX';
                1         %'PixelExtentInWorldY';
                1         %'PixelExtentInWorldZ';
                2         %'ImageExtentInWorldX';
                2         %'ImageExtentInWorldY';
                2         %'ImageExtentInWorldZ';
                [0.5 2.5] %'XIntrinsicLimits';
                [0.5 2.5] %'YIntrinsicLimits';
                [0.5 2.5]}; %'ZIntrinsicLimits'

            for i=1:length(expectedPropertyVals)
                testCase.verifyEqual(R.(expectedProperties{i}),...
                    expectedPropertyVals{i},...
                    ['Incorrect default value for property ' expectedProperties{i},...
                    ' in IMREF3D obj']);
            end

            %% Property Settings

            
            R = imref3d();
            R.XWorldLimits = [0.5 6];
            R.YWorldLimits = [0.5 7];
            R.ZWorldLimits = [0.5 8];
            
            oldDx = R.PixelExtentInWorldX;
            oldDy = R.PixelExtentInWorldY;
            oldDz = R.PixelExtentInWorldZ;
            
            % Double the extent of the world X and Y limits.
            newXWorldLimits = R.XWorldLimits(1) + [0 2*diff(R.XWorldLimits)];
            newYWorldLimits = R.YWorldLimits(1) + [0 2*diff(R.YWorldLimits)];
            newZWorldLimits = R.ZWorldLimits(1) + [0 2*diff(R.ZWorldLimits)];
            R.XWorldLimits = newXWorldLimits;
            R.YWorldLimits = newYWorldLimits;
            R.ZWorldLimits = newZWorldLimits;
            
            % Verify setting worked
            testCase.verifyThat(R.XWorldLimits, IsEqualTo(newXWorldLimits, ...
                'Within', AbsoluteTolerance(eps(6))), ...
                'XWorldLimits should equal newXWorldLimits.')
            testCase.verifyThat(R.YWorldLimits, IsEqualTo(newYWorldLimits, ...
                'Within', AbsoluteTolerance(7)), ...
                'YWorldLimits should equal newYWorldLimits.')
            testCase.verifyThat(R.ZWorldLimits, IsEqualTo(newZWorldLimits, ...
                'Within', AbsoluteTolerance(7)), ...
                'ZWorldLimits should equal newZWorldLimits.')
            
            % Verify dependent properties changed appropriately
            testCase.verifyThat(R.ImageExtentInWorldX, IsEqualTo(diff(R.XWorldLimits), ...
                'Within', AbsoluteTolerance(eps(256))), ...
                'Raster width should equal 5 * 3.');
            testCase.verifyThat(R.ImageExtentInWorldY, IsEqualTo(diff(R.YWorldLimits), ...
                'Within', AbsoluteTolerance(eps(256))), ...
                'Raster height should equal 8 * 2.');
            testCase.verifyThat(R.ImageExtentInWorldZ, IsEqualTo(diff(R.ZWorldLimits), ...
                'Within', AbsoluteTolerance(eps(256))), ...
                'Raster depth should equal 8 * 2.');
            testCase.verifyThat(R.PixelExtentInWorldX, IsEqualTo(2*oldDx, ...
                'Within', AbsoluteTolerance(eps(10))), ...
                'PixelExtentInWorldX should be double of previous value')
            testCase.verifyThat(R.PixelExtentInWorldY, IsEqualTo(2*oldDy, ...
                'Within', AbsoluteTolerance(eps(10))), ...
                'PixelExtentInWorldY should be double of previous value')
            testCase.verifyThat(R.PixelExtentInWorldZ, IsEqualTo(2*oldDz, ...
                'Within', AbsoluteTolerance(eps(10))), ...
                'PixelExtentInWorldZ should be double of previous value')
            %------------------------------------------------
            
            % Change ImageSize and verify dependent properties
            R = imref3d();
            numRows = 181; numCols = 361; numPages = 21;
            R.ImageSize = [numRows numCols numPages];
            R.XWorldLimits = [300000 300090];
            R.YWorldLimits = [-650090 -650000];
            R.ZWorldLimits = [100000 100090];
            % Verify setting worked
            testCase.verifyEqual(R.ImageSize, [numRows numCols numPages], ...
                'Raster size should be 181-by-361-by-21.')
            testCase.verifyEqual(R.PixelExtentInWorldX, 90/361,'PixelExtentInWorldX should equal 1/4.');
            testCase.verifyEqual(R.PixelExtentInWorldY, 90/181,'PixelExtentInWorldY should equal 1/2.');
            testCase.verifyEqual(R.PixelExtentInWorldZ, 90/21,'PixelExtentInWorldZ should equal 90/21.');
            testCase.verifyEqual(R.ImageExtentInWorldX, 360/4, ...
                'Rectilinear, postings: raster width is (N - 1)*abs(PixelExtentInWorldX).');
            testCase.verifyEqual(R.ImageExtentInWorldY, 180/2, ...
                'Rectilinear, postings: raster height is (M - 1)*abs(PixelExtentInWorldY).');
            testCase.verifyEqual(R.ImageExtentInWorldZ, 90, ...
                'Rectilinear, postings: raster Depth is (P - 1)*abs(PixelExtentInWorldZ).');
            testCase.verifyEqual(R.XIntrinsicLimits, [0.5 361.5], ...
                'Limits in intrinsic X should be [0.5 360.5].');
            testCase.verifyEqual(R.YIntrinsicLimits, [0.5 181.5], ...
                'Limits in intrinsic Y should be [0.5 180.5].');
            testCase.verifyEqual(R.ZIntrinsicLimits, [0.5 21.5], ...
                'Limits in intrinsic Z should be [0.5 21.5].');

            %% contains method
            % Syntax being tested:
            % TF = R.contains(xWorld,yWorld,zWorld);
            %
            
            % defining input variables
            numRows = 101;
            numCols = 202;
            numPages = 33;
            I = zeros(numRows,numCols,numPages);
            XWorldLimits = [23 27.34]; % Spatial extent in world co-ord
            YWorldLimits = [-20 63.23];% Spatial extent in world co-ord
            ZWorldLimits = [34 64.66666];% Spatial extent in world co-ord
            R = imref3d();
            R.ImageSize = size(I);
            R.XWorldLimits = XWorldLimits;
            R.YWorldLimits = YWorldLimits;
            R.ZWorldLimits = ZWorldLimits;
            
            % [xWorld,yWorld,zWorld] inside R's extent
            xWorld = 25; yWorld = -pi; zWorld = 34.1;
            testCase.verifyTrue(R.contains(xWorld,yWorld,zWorld),...
                'Contains method error for [xWorld,yWorld,zWorld] inside R''s extent');
            
            % [xWorld,yWorld,zWorld] not inside R's extent
            xWorld = 2*pi; yWorld = -pi; zWorld = 34.1;
            testCase.verifyFalse(R.contains(xWorld,yWorld,zWorld),...
                'Contains method error for [xWorld,yWorld,zWorld] not inside R''s extent');
            
            % [xWorld,yWorld,zWorld ] on the border of R's extent
            xWorld = R.XWorldLimits(1); yWorld = R.YWorldLimits(2); zWorld = R.ZWorldLimits(2);
            testCase.verifyTrue(R.contains(xWorld,yWorld,zWorld),...
                'Contains method error for [xWorld,yWorld,zWorld] on the border of R''s extent');

            %% Intrinsic to world method

            % Syntax being tested:
            % [xWorld,yWorld,zWorld] = R.intrinsicToWorld(xIntrinsic,yIntrinsic,zIntrinsic);
            %
            
            % defining input variables
            numRows = 101;
            numCols = 202;
            numPages = 33;
            I = zeros(numRows,numCols,numPages);
            R = imref3d();
            R.ImageSize = size(I);
            % Change to non-default World coordinates
            R.XWorldLimits =   2*R.XIntrinsicLimits;
            R.YWorldLimits = 0.5*R.YIntrinsicLimits + 10;
            R.ZWorldLimits =     R.ZIntrinsicLimits - 100;
            
            % Verify transformations
            %              xi = [ 2  -4.68  -2.23  -4.54  -4   NaN   1.95  -1.83   4  -4.66];
            %              yi = [ 0  -1.18   2.66   2.95  -3   Inf  -0.54   1.46   2   2.55];
            xi = [ 2  -4.68  -2.23  -4.54  -4   NaN   1.95  -1.83   4  -4.66];
            yi = [ 0  -1.18   2.66    Inf  -3   NaN  -0.54   1.46   2   2.55] +10;
            zi = [ 0  -100    Inf    2.80  -1   NaN  -0.54   100    5   2.55] ;
            
            expectedXW =   2*xi;
            expectedYW = 0.5*yi + 10;
            expectedZW =     zi - 100;
            [xw, yw, zw] = R.intrinsicToWorld(xi, yi, zi);
            testCase.verifyThat(xw, IsEqualTo(expectedXW, ...
                'Within', AbsoluteTolerance(eps(2))), ...
                'Intrinsic to world is incorrect.');
            testCase.verifyThat(yw, IsEqualTo(expectedYW, ...
                'Within', AbsoluteTolerance(eps(2))), ...
                'Intrinsic to world is incorrect.');
            testCase.verifyThat(zw, IsEqualTo(expectedZW, ...
                'Within', AbsoluteTolerance(eps(100))), ...
                'Intrinsic to world is incorrect.');

            %% world to intrinsic method

            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.AbsoluteTolerance
            
            % defining input variables
            numRows = 101;
            numCols = 202;
            numPages = 21;
            I = zeros(numRows,numCols,numPages);
            R = imref3d();
            R.ImageSize = size(I);
            % Change to non-default World coordinates
            R.XWorldLimits =   2*R.XIntrinsicLimits;
            R.YWorldLimits = 0.5*R.YIntrinsicLimits + 10;
            R.ZWorldLimits =     R.ZIntrinsicLimits - 100;
            
            % Verify transformations
            %              xi = [ 2  -4.68  -2.23  -4.54  -4   NaN   1.95  -1.83   4  -4.66];
            %              yi = [ 0  -1.18   2.66   2.95  -3   Inf  -0.54   1.46   2   2.55];
            xW = [ 2  -4.68  -2.23  -4.54  -4   NaN   1.95  -1.83   4  -4.66];
            yW = [ 0  -1.18   2.66    Inf  -3   NaN  -0.54   1.46   2   2.55]+10;
            zW = [ 0  -100    Inf    2.80  -1   NaN  -0.54   100    5   2.55] ;
            
            expectedXI =    xW/2;
            expectedYI = 2*(yW - 10);
            expectedZI =    zW + 100;
            [xI, yI, zI] = R.worldToIntrinsic(xW, yW, zW);
            testCase.verifyThat(xI, IsEqualTo(expectedXI, ...
                'Within', AbsoluteTolerance(1e-13)), ...
                'World to Intrinsic is incorrect.');
            testCase.verifyThat(yI, IsEqualTo(expectedYI, ...
                'Within', AbsoluteTolerance(1e-13)), ...
                'World to Intrinsic is incorrect.');
            testCase.verifyThat(zI, IsEqualTo(expectedZI, ...
                'Within', AbsoluteTolerance(1e-13)), ...
                'World to Intrinsic is incorrect.');


        end %function

    end %methods
end %classdef