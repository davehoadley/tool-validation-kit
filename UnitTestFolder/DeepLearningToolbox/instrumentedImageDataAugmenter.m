classdef instrumentedImageDataAugmenter < imageDataAugmenter
    % imageDataAugmenter subclass which provides access to intermediate
    % transform values for testing.

    % Copyright 2024 The MathWorks, Inc.

    methods
        function obj = instrumentedImageDataAugmenter(varargin)
            obj@imageDataAugmenter(varargin{:});
        end

        function T = getAffineTransform(obj, varargin)
            %getAffineTransform Return the affine transform matrix
            %
            %  getAffineTransform(obj) returns the full 3x3 matrix that the
            %  imageDataAugmenter used for the most recent augment() call.
            %
            %  getAffineTransform(obj, rowidx, colidx, pageidx) indexes the above
            %  matrix and returns only the requested elements.

            T = obj.AffineTransforms;
            if nargin>1
                T = T(varargin{:});
            end
        end
    end
end