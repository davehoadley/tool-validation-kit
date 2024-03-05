classdef GraphicsImageTests < matlab.unittest.TestCase
    % GRAPHICSIMAGETESTS is an example validation test case for some features
    % of the MATLAB language.  Specifically, it demonstrates functionality
    % for image graphics operations.
    % It requires the MATLAB unit test framework as a test
    % executive.
    %
    % Copyright 2022 The MathWorks, Inc.

    %% Properties
    properties
        %This section can be used to define test properties
        Tol = 1e-6;
    end

    %% Class and Method Setup
    methods(TestClassSetup)
        %This section can be used to define actions to execute before all
        %tests.
    end %methods

    methods(TestMethodSetup)
        %This section can be used to define actions to execute before each
        %test.
    end %methods

    methods(TestMethodTeardown)
        %This section can be used to define actions to execute after each
        %test.
    end %methods

    methods(TestClassTeardown)
        %This section can be used to define actions to execute after all
        %tests in this class have been completed.
    end %methods

    %% Test Methods
    methods(Test)

        function imresizeTest(testcase)
            % Unit tests for imresize()

            a = [10 11 14 15 1];

            % Turn a raised cosine into an interpolation kernel.
            h = @(x) (cos(x) + 1) .* ((x >= -pi) & (x <= pi));
            w = 2*pi;

            act1 = hCallFunction(testcase, a, 0.7, {h, w});
            exp1 = [11.314289010994194, 10.770023941248512, 9.320665214865953, 8.563047151368302];
            testcase.verifyEqual(act1, exp1, 'Abstol', testcase.Tol, "Verify resized vector with antialiasing");

            act2 = hCallFunction(testcase, a, 0.7, {h, w}, 'Antialiasing', false);
            exp2 = [10.886142589006651, 12.062852716206809, 9.409377237771102, 6.584515449618068];
            testcase.verifyEqual(act2, exp2, 'Abstol', testcase.Tol, "Verify resized vector without antialiasing");

            % Test indexed input

            X = uint8(magic(15));
            map = gray(256);

            % Algorithm for indexed image is to convert to RGB, resize the
            % image, and then convert back to indexed.
            rgb = matlab.images.internal.ind2rgb8(X, map);

            [X1,map1] = hCallFunction(testcase, X,map,2.3);
            rgb2 = hCallFunction(testcase, rgb,2.3);
            [X2,map2] = rgb2ind(rgb2, 256, 'dither');

            testcase.verifyTrue(isequal(X1, X2), "Verify index image");
            testcase.verifyTrue(isequal(map1, map2),  "Verify index image map");

            [X1,map1] = hCallFunction(testcase, X,map,2.3,'Colormap','original','Dither',false);
            X2 = rgb2ind(rgb2,map,'nodither');

            testcase.verifyTrue(isequal(X1, X2), "Verify index image");
            testcase.verifyTrue(isequal(map1, map), "Verify index image map");

            % Test parameter defaults.
            [X3, map3] = hCallFunction(testcase, X,map,4.1);
            [X4, map4] = hCallFunction(testcase, X,map,4.1,'Colormap','optimized','Dither',true);

            testcase.verifyTrue(isequal(X3, X4), "Verify index image");
            testcase.verifyTrue(isequal(map3, map4), "Verify index image map");

        end %function

    end %methods

    %% Private methods
    methods (Access = private)
        function varargout = hCallFunction(~, varargin)
            switch nargout
                case 0
                    imresize(varargin{:});
                case 1
                    varargout{1} = imresize(varargin{:});
                case 2
                    [varargout{1},varargout{2}] = imresize(varargin{:});
            end
        end %function
    end %methods

end %classdef