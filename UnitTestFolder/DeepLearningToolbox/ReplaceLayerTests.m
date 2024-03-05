classdef ReplaceLayerTests < matlab.unittest.TestCase
    % REPLACELAYERTESTS contains validation test cases for some features
    % of the Deep Learning Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.
   
    properties(TestParameter)
        ReconnectBy = {'name', 'order'}
    end
    
    methods(Test)
        function testCanReplaceMiddleLayer( test, ReconnectBy )
            % Before replacement:
            %
            %   first ---> second ---> last
            %
            % After replacement:
            %
            %   first ---> replacementLayer ---> last

            import matlab.unittest.constraints.IsEqualTo
            
            originalLayers = [
                imageInputLayer([28 28], 'Name', 'first')
                fullyConnectedLayer(10, 'Name', 'second')
                reluLayer('Name', 'last')];
            lgraph = layerGraph(originalLayers);
            
            replacementLayer = convolution2dLayer(5, 32, ...
                'Name', 'replacementLayer');
            
            lgraph = replaceLayer(lgraph, 'second', replacementLayer, ...
                'ReconnectBy', ReconnectBy);
            
            % Verify the second layer has been replaced.
            test.verifyThat(lgraph.Layers(1), IsEqualTo(originalLayers(1)), "Verify the second layer has been replaced");
            test.verifyThat(lgraph.Layers(2), IsEqualTo(replacementLayer), "Verify the second layer has been replaced");
            test.verifyThat(lgraph.Layers(3), IsEqualTo(originalLayers(3)), "Verify the second layer has been replaced");
            
            % Verify that we get the expected connections.
            Source = {'first'; 'replacementLayer'};
            Destination = {'replacementLayer'; 'last'};
            expectedConnections = table( Source, Destination );
            test.verifyThat(lgraph.Connections, IsEqualTo(expectedConnections), "Verify that we get the expected connections");
        end
        
       function testCanReplaceFirstLayer( test, ReconnectBy )
            % Before replacement:
            %
            %   first ---> second ---> last
            %
            % After replacement:
            %
            %   replacementLayer ---> second ---> last

            import matlab.unittest.constraints.IsEqualTo
            
            originalLayers = [
                imageInputLayer([28 28], 'Name', 'first')
                fullyConnectedLayer(10, 'Name', 'second')
                reluLayer('Name', 'last')];
            lgraph = layerGraph(originalLayers);
            
            replacementLayer = convolution2dLayer(5, 32, ...
                'Name', 'replacementLayer');
            
            lgraph = replaceLayer(lgraph, 'first', replacementLayer, ...
                'ReconnectBy', ReconnectBy);
            
            % Verify the the first layer has been replaced.
            test.verifyThat(lgraph.Layers(1), IsEqualTo(replacementLayer), "Verify the the first layer has been replaced");
            test.verifyThat(lgraph.Layers(2), IsEqualTo(originalLayers(2)), "Verify the the first layer has been replaced");
            test.verifyThat(lgraph.Layers(3), IsEqualTo(originalLayers(3)), "Verify the the first layer has been replaced");
            
            % Verify that we get the expected connections.
            Source = {'replacementLayer'; 'second'};
            Destination = {'second'; 'last'};
            expectedConnections = table( Source, Destination );
            test.verifyThat(lgraph.Connections, IsEqualTo(expectedConnections), "Verify that we get the expected connections");
       end

       function testCanReplaceLastLayer( test, ReconnectBy )
            % Before replacement:
            %
            %   first ---> second ---> lastLayerWithNoOutputs
            %
            % After replacement:
            %
            %   first ---> second ---> replacementLayerWithOneOutput

            import matlab.unittest.constraints.IsEqualTo
            
            originalLayers = [
                imageInputLayer([28 28], 'Name', 'first')
                fullyConnectedLayer(10, 'Name', 'second')
                regressionLayer('Name', 'last')];
            lgraph = layerGraph(originalLayers);
            
            replacementLayer = softmaxLayer('Name', 'replacementLayer');
            
            lgraph = replaceLayer(lgraph, 'last', replacementLayer, ...
                'ReconnectBy', ReconnectBy);
            
            % Verify the the last layer has been replaced.
            test.verifyThat(lgraph.Layers(1), IsEqualTo(originalLayers(1)), "Verify the the last layer has been replaced");
            test.verifyThat(lgraph.Layers(2), IsEqualTo(originalLayers(2)), "Verify the the last layer has been replaced");
            test.verifyThat(lgraph.Layers(3), IsEqualTo(replacementLayer), "Verify the the last layer has been replaced");
            
            % Verify that we get the expected connections.
            Source = {'first'; 'second'};
            Destination = {'second'; 'replacementLayer'};
            expectedConnections = table( Source, Destination );
            test.verifyThat(lgraph.Connections, IsEqualTo(expectedConnections), "Verify that we get the expected connections");
       end

       function testCanReplaceBranchWithOneLayer( test, ReconnectBy )
            % Before replacement:
            %
            %   input ---> conv1 ---> add ---> relu
            %        \               /
            %         \___ conv2 ___/
            %
            % After replacement:
            %
            %   input ------> conv1 ------> add ---> relu
            %        \                      /
            %         \_ replacementLayer _/

            import matlab.unittest.constraints.IsEqualTo
            
            input = imageInputLayer([28 28], 'Name', 'input');
            conv1 = convolution2dLayer(5, 32, 'Name', 'conv1');
            conv2 = convolution2dLayer(5, 32, 'Name', 'conv2');
            finalSection = [
                additionLayer(2, 'Name', 'add')
                reluLayer('Name', 'relu')];
            lgraph = layerGraph();
            lgraph = addLayers(lgraph, input);
            lgraph = addLayers(lgraph, conv1);
            lgraph = addLayers(lgraph, conv2);
            lgraph = addLayers(lgraph, finalSection);
            lgraph = connectLayers(lgraph, 'input', 'conv1');
            lgraph = connectLayers(lgraph, 'input', 'conv2');
            lgraph = connectLayers(lgraph, 'conv1', 'add/in1');
            lgraph = connectLayers(lgraph, 'conv2', 'add/in2');
            
            replacementLayer = convolution2dLayer(5, 64, ...
                'Name', 'replacementLayer');
            
            lgraph = replaceLayer(lgraph, 'conv2', replacementLayer, ...
                'ReconnectBy', ReconnectBy);
            
            % Verify the layer in the second branch has been replaced.
            test.verifyThat(lgraph.Layers(1), IsEqualTo(input), "Verify the layer in the second branch has been replaced");
            test.verifyThat(lgraph.Layers(2), IsEqualTo(conv1), "Verify the layer in the second branch has been replaced");
            test.verifyThat(lgraph.Layers(3), IsEqualTo(replacementLayer), "Verify the layer in the second branch has been replaced");
            test.verifyThat(lgraph.Layers(4), IsEqualTo(finalSection(1)), "Verify the layer in the second branch has been replaced");
            test.verifyThat(lgraph.Layers(5), IsEqualTo(finalSection(2)), "Verify the layer in the second branch has been replaced");
            
            % Verify that we get the expected connections.
            Source = {'input';'input';'conv1';'replacementLayer';'add'};
            Destination = {'conv1';'replacementLayer';'add/in1';'add/in2';'relu'};
            expectedConnections = table( Source, Destination );
            test.verifyThat(lgraph.Connections, IsEqualTo(expectedConnections), "Verify that we get the expected connections");
       end

       function testCanReplaceDisconnectedMultiInputLayerWithSingleInputLayer( test, ReconnectBy )
            % Check that we can replace a multi input layer that isn't
            % connected to anything with a single input layer.
            %
            % Before replacement:
            %
            %   first ---> second      last
            %
            % After replacement:
            %
            %   first ---> second      replacementLayer

            import matlab.unittest.constraints.IsEqualTo
            
            firstSection = [
                imageInputLayer([28 28], 'Name', 'first')
                fullyConnectedLayer(10, 'Name', 'second')];
            add = additionLayer(2,'Name', 'last');
            lgraph = layerGraph(firstSection);
            lgraph = addLayers(lgraph, add);
            
            replacementLayer = reluLayer('Name','replacementLayer');
            
            lgraph = replaceLayer(lgraph, 'last', replacementLayer, ...
                'ReconnectBy', ReconnectBy);
            
            % Verify the second layer has been replaced.
            test.verifyThat(lgraph.Layers(1), IsEqualTo(firstSection(1)), "Verify the second layer has been replaced");
            test.verifyThat(lgraph.Layers(2), IsEqualTo(firstSection(2)), "Verify the second layer has been replaced");
            test.verifyThat(lgraph.Layers(3), IsEqualTo(replacementLayer), "Verify the second layer has been replaced");
            
            % Verify that we get the expected connections.
            Source = {'first'};
            Destination = {'second'};
            expectedConnections = table( Source, Destination );
            test.verifyThat(lgraph.Connections, IsEqualTo(expectedConnections), "Verify that we get the expected connections");
        end
   
    end %methods
end %classdef
