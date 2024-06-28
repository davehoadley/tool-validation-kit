classdef ImageDataAugmenterTests < matlab.unittest.TestCase
    % IMAGEDATAAUGMENTERTESTS contains validation test cases for some features
    % of the Deep Learning Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.
    
    properties
        cameramanImage
        peppersImage
        stream = RandStream('mt19937ar','Seed',0);
    end
    
    properties(TestParameter)
        pvPairs = iVariousInputs();
    end
    
    methods(TestClassSetup)
        function rngSetup(~)
            rng(0, 'twister');
        end
        function setupTestImages(testcase)
            testcase.cameramanImage = imread('cameraman.tif');
            testcase.peppersImage = imread('peppers.png');
        end
    end
    
    methods(Test)
        function testDefaultValues(testcase)
            augmenter = imageDataAugmenter();
            
            testcase.verifyEqual(augmenter.FillValue,0, "Incorrect FillValue for default object.")
            testcase.verifyFalse(augmenter.RandXReflection, "Incorrect RandXReflection for default object.")
            testcase.verifyFalse(augmenter.RandYReflection, "Incorrect RandYReflection for default object.")
            testcase.verifyEqual(augmenter.RandRotation,[0 0], "Incorrect RandRotation for default object.")
            testcase.verifyEqual(augmenter.RandScale,[1 1], "Incorrect RandScale for default object.")
            testcase.verifyEqual(augmenter.RandXScale,[1 1], "Incorrect RandXScale for default object.")
            testcase.verifyEqual(augmenter.RandYScale,[1 1], "Incorrect RandYScale for default object.")
            testcase.verifyEqual(augmenter.RandXShear,[0 0], "Incorrect RandXShear for default object.")
            testcase.verifyEqual(augmenter.RandYShear,[0 0], "Incorrect RandYShear for default object.")
            testcase.verifyEqual(augmenter.RandXTranslation,[0 0], "Incorrect RandXTranslation for default object.")
            testcase.verifyEqual(augmenter.RandYTranslation,[0 0], "Incorrect RandYTranslation for default object.")
        end
        
        function basicBehaviorRGB(testcase)
            
            augmenter = instrumentedImageDataAugmenter('RandRotation',[-20 20]);
            A = testcase.peppersImage;
            out = augment(augmenter,testcase.peppersImage);
            exp = imwarp(A,affine2d(augmenter.getAffineTransform),'OutputView',imref2d(size(A)));
            
            % Use SSIM to give us some wiggle room re: resizing algorithm,
            % intermediate datatype, etc. We just want to know if the same
            % geometric transformation was applied.
            ssimObserved = ssim(out,exp);
            
            testcase.verifyGreaterThan(ssimObserved,0.9,'Incorrect augmentation for RGB rotation.');
            
        end
        
        function basicBehaviorGrayscale(testcase)
            
            augmenter = instrumentedImageDataAugmenter('RandRotation',[-20 20],'RandXTranslation',[0 10]);
            
            A = testcase.cameramanImage;
            out = augment(augmenter,A);
            
            exp = imwarp(A,affine2d(augmenter.getAffineTransform()),'OutputView',imref2d(size(A)));
            
            ssimObserved = ssim(out,exp);
            
            testcase.verifyGreaterThan(ssimObserved,0.9,'Incorrect augmentation for RGB rotation.');            
        end
        
        function testRotation(testcase)
            
            A = testcase.peppersImage;
            augmenter = imageDataAugmenter('RandRotation',[90,90]);
            
            act = augmenter.augment(A);
            exp = imrotate(A,90,'nearest','crop'); % Interpolation method doesn't matter for 90 degree rotation.
            
            testcase.verifyTrue(isequal(act,exp),'Incorrect augmentation for 90 degree rotation.');
            
        end
        
        function testTranslation(testcase)
            
            A = testcase.cameramanImage;
            augmenter = imageDataAugmenter('RandXTranslation',[-1 -1],...
                'RandYTranslation',[2 2]);
            
            act = augmenter.augment(A);
            exp = imtranslate(A,[-1 2]);
            
            testcase.verifyTrue(isequal(act,exp),'Incorrect augmentation for [-1, 2] translation');
            
        end
        
        function testUniformScale(testcase)
            
            A = testcase.peppersImage;
            augmenter = imageDataAugmenter('RandScale',[1.2,1.2]);
            
            act = augmenter.augment(A);
            
            
            scaleT = [1.2 0 0; 0 1.2 0; 0 0 1];
            
            centeredScaleTransform = iShiftCenterToOriginTransformAndShiftBack(scaleT,size(A));
            
            scaleTform = affine2d(centeredScaleTransform);
            exp = imwarp(A,scaleTform,'OutputView',imref2d(size(A)));
            
            % There are some subtle spatial referencing differences in the
            % imwarp codepath that make getting exact equality between
            % act/exp tricky. However, the images are visually indistinguishable,
            % and I think both results are "correct".
            testcase.verifyGreaterThan(ssim(act,exp),0.99,'Incorrect augmentation for scale');
        end
        
        function testScale(testcase)
            
            A = testcase.peppersImage;
            augmenter = imageDataAugmenter('RandXScale',[1.2,1.2],...
                'RandYScale',[1.1 1.1]);
            
            act = augmenter.augment(A);
            
            
            scaleT = [1.2 0 0; 0 1.1 0; 0 0 1];
            
            centeredScaleTransform = iShiftCenterToOriginTransformAndShiftBack(scaleT,size(A));
            
            scaleTform = affine2d(centeredScaleTransform);
            exp = imwarp(A,scaleTform,'OutputView',imref2d(size(A)));
            
            % There are some subtle spatial referencing differences in the
            % imwarp codepath that make getting exact equality between
            % act/exp tricky. However, the images are visually indistinguishable,
            % and I think both results are "correct".
            testcase.verifyGreaterThan(ssim(act,exp),0.99,'Incorrect augmentation for scale');
            
        end
        
        function testXReflection(testcase)

            import matlab.unittest.constraints.IsEqualTo;

            A = testcase.cameramanImage;
            augmenter = imageDataAugmenter('RandXReflection',true);

            % Every result should be either flipped or not.
            Aflipped = fliplr(A);
            con = IsEqualTo(A) | IsEqualTo(Aflipped);

            % Use a fixed random sequence to ensure test repeatability.
            orig = rng(1);
            testcase.addTeardown(@rng, orig)

            flipped = false(1,100);
            for n = 1:100
                act = augmenter.augment(A);
                testcase.verifyThat(act, con, 'Incorrect augmentation for X reflection.');

                flipped(n) = all(act==Aflipped, 'all');
            end

            % The number flipped ought to be close to the expected mean, 50.  The exact
            % number is repeatable in this test due to the fixed seed, but may alter if
            % the imageDataAugmenter changes how it samples from the random stream.  To
            % allow for this we test that the flipping happens within the 2 sigma
            % level.
            testcase.verifyLessThanOrEqual(abs(sum(flipped)-50), 10, 'Incorrect augmentation for X reflection.');
        end

        function testYReflection(testcase)

            import matlab.unittest.constraints.IsEqualTo;

            A = testcase.cameramanImage;
            augmenter = imageDataAugmenter('RandYReflection',true);
            
            Aflipped = flipud(A);
            con = IsEqualTo(A) | IsEqualTo(Aflipped);

            % Use a fixed random sequence to ensure test repeatability.
            orig = rng(1);
            testcase.addTeardown(@rng, orig)

            flipped = false(1,100);
            for n = 1:100
                act = augmenter.augment(A);
                testcase.verifyThat(act, con, 'Incorrect augmentation for Y reflection.');

                flipped(n) = all(act==Aflipped, 'all');
            end

            % The number flipped ought to be close to the expected mean, 50.  The exact
            % number is repeatable in this test due to the fixed seed, but may alter if
            % the imageDataAugmenter changes how it samples from the random stream.  To
            % allow for this we test that the flipping happens within the 2 sigma
            % level.
            testcase.verifyLessThanOrEqual(abs(sum(flipped)-50), 10, 'Incorrect augmentation for Y reflection.');
        end

        function testShear(testcase)
            
            A = testcase.peppersImage;
            
            augmenter = imageDataAugmenter('RandXShear',[45 45]);
            
            act = augmenter.augment(A);
            
            shearTransform = [1 0 0; tand(45) 1 0; 0 0 1];
            shearTransform = iShiftCenterToOriginTransformAndShiftBack(shearTransform,size(A));
            exp = imwarp(A,affine2d(shearTransform),'OutputView',imref2d(size(A)));
            
            testcase.verifyGreaterThan(ssim(act,exp),0.98,'Incorrect X Shear');
            
            augmenter = imageDataAugmenter('RandYShear',[30 30]);
            act = augmenter.augment(A);
            
            shearTransform = [1 tand(30) 0; 0 1 0; 0 0 1];
            shearTransform = iShiftCenterToOriginTransformAndShiftBack(shearTransform,size(A));
            exp = imwarp(A,affine2d(shearTransform),'OutputView',imref2d(size(A)));
            
            testcase.verifyGreaterThan(ssim(act,exp),0.98,'Incorrect Y Shear');
            
        end
   
    end %methods
end %classdef

function tformOut = iShiftCenterToOriginTransformAndShiftBack(tform,imageSize)

Xtrans = (imageSize(2)-1)/2;
Ytrans = (imageSize(1)-1)/2;
[shiftCenterToOrigin,shiftBack] = deal(eye(3));

shiftCenterToOrigin(3,1:2) = [-Xtrans,-Ytrans];
shiftBack(3,1:2) = [Xtrans,Ytrans];

tformOut = shiftCenterToOrigin * tform * shiftBack;

end

function s = iVariousInputs()
fillValue.propName = 'FillValue';
fillValue.propVal = '1';

randXReflection.propName = 'RandXReflection';
randXReflection.propVal = '1';

randYReflection.propName = 'RandYReflection';
randYReflection.propVal = '1';

randRotation.propName = 'RandRotation';
randRotation.propVal = '[10 15]';

randScale.propName = 'RandScale';
randScale.propVal = '[0.5 3]';

randXScale.propName = 'RandXScale';
randXScale.propVal = '[2 3]';

randYScale.propName = 'RandYScale';
randYScale.propVal = '[2 3]';

randXShear.propName = 'RandXShear';
randXShear.propVal = '[1 3]';

randYShear.propName = 'RandYShear';
randYShear.propVal = '[1 3]';

randXTranslation.propName = 'RandXTranslation';
randXTranslation.propVal = '[1 3]';

randYTranslation.propName = 'RandYTranslation';
randYTranslation.propVal = '[1 3]';

s = struct('fillValue',fillValue,...
    'randXReflection',randXReflection,...
    'randYReflection',randYReflection,...
    'randRotation',randRotation,...
    'randScale',randScale,...
    'randXScale',randXScale,...
    'randYScale',randYScale,...
    'randXShear',randXShear,...
    'randYShear',randYShear,...
    'randXTranslation',randXTranslation,...
    'randYTranslation',randYTranslation);
end

function rangeNum = verifyInRange(range,val)
rangeNum = find(range(:,1)<=val & range(:,2)>=val);
end