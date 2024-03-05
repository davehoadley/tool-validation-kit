classdef LayerGraphTests < matlab.unittest.TestCase
    % LAYERGRAPHTESTS contains validation test cases for some features
    % of the Deep Learning Toolbox.
    %
    % Copyright 2022 The MathWorks, Inc.

    properties(TestParameter)
        % test parameters for positive tests
        ValidLayerArray = iGetValidLayerArrays()
        ValidLayerArrayWithNotUniqueNames = iGetValidLayerArraysWithNotUniqueNames()
        ValidDAGNetwork = iGetValidDAGnetworks()
    end
    
    methods(Test)
        function canCallLayerGraphWithoutArguments(test)
            % Calling layerGraph without any input arguments should create
            % the correct LayerGraph object with expected properties.

            import matlab.unittest.constraints.IsOfClass
            import matlab.unittest.constraints.IsTrue
            
            % Calling layerGraph without any input arguments should not error
            lgraph = layerGraph();
            
            % The created object should be an external LayerGraph
            test.verifyThat( lgraph, IsOfClass('nnet.cnn.LayerGraph'), "Created object should be an external LayerGraph");
            
            % The Connections property in an empty LayerGraph should be an
            % empty table
            test.verifyThat( lgraph.Connections, IsOfClass('table'), "Connections property in an empty LayerGraph should be of class table");
            test.verifyThat( isempty(lgraph.Connections), IsTrue(), "Connections property in an empty LayerGraph should be an empty table");
            
            % The Layers property in an empty LayerGraph should be an empty
            % Layer array
            test.verifyThat( lgraph.Layers, IsOfClass('nnet.cnn.layer.Layer'), "Layers property in an empty LayerGraph should be of class nnet.cnn.layer.Layer");
            test.verifyThat( isempty(lgraph.Layers), IsTrue(), "Layers property in an empty LayerGraph should be an empty Layer array");
        end
        
        function canCreateLayerGraphFromLayerArray(test,ValidLayerArray)
            % Calling layerGraph with an array of layers as input should
            % create a LayerGraph object with the expected properties

            import matlab.unittest.constraints.IsOfClass
            import matlab.unittest.constraints.IsEqualTo
            
            lgraph = layerGraph(ValidLayerArray.Layers);
            
            % The created object should be an external LayerGraph
            test.verifyThat( lgraph, IsOfClass('nnet.cnn.LayerGraph'), "Created object should be an external LayerGraph");
            
            % The properties Layer should contain the exact same layer
            % array as passed into layerGraph as input argument
            test.verifyThat( lgraph.Layers, IsEqualTo(ValidLayerArray.Layers), ...
                "The properties Layer should contain the exact same layer array as passed into layerGraph as input argument");
            
            % The property Connections should contain a table with
            % connections between subsequent layers of the layer array
            test.verifyThat( lgraph.Connections, IsEqualTo(ValidLayerArray.Connections), ...
                "The property Connections should contain a table with connections between subsequent layers of the layer array");
        end
        
        function canCreateLayerGraphFromLayerArrayWithNotUniqueNames(test,ValidLayerArrayWithNotUniqueNames)
            % Calling layerGraph with an array of layers as input should
            % create a LayerGraph object with the expected properties

            import matlab.unittest.constraints.IsOfClass
            import matlab.unittest.constraints.IsEqualTo
            
            lgraph = layerGraph(ValidLayerArrayWithNotUniqueNames.Layers);
            
            % The created object should be an external LayerGraph
            test.verifyThat( lgraph, IsOfClass('nnet.cnn.LayerGraph'), "Created object should be an external LayerGraph");
            
            % The properties Layer should contain the exact same layer
            % array as passed into layerGraph as input argument
            test.verifyThat( lgraph.Layers, IsEqualTo(ValidLayerArrayWithNotUniqueNames.LayersUniqueName), ...
                "The properties Layer should contain the exact same layer array as passed into layerGraph as input argument" );
            
            % The property Connections should contain a table with
            % connections between subsequent layers of the layer array
            test.verifyThat( lgraph.Connections, IsEqualTo(ValidLayerArrayWithNotUniqueNames.Connections), ...
               "The property Connections should contain a table with connections between subsequent layers of the layer array" );
        end
        
        function canCreateLayerGraphFromSeriesNetwork(test)
            % Calling layerGraph with a SeriesNetwork as input should
            % create a LayerGraph object with the expected properties

            import matlab.unittest.constraints.IsOfClass
            import matlab.unittest.constraints.IsEqualTo

            ValidSeriesNetwork = iClassificationNetwork();
            lgraph = layerGraph(ValidSeriesNetwork);
            
            % The created object should be an external LayerGraph
            test.verifyThat( lgraph, IsOfClass('nnet.cnn.LayerGraph'), "Created object should be an external LayerGraph");
            
            % The property 'Layer' should contain the exact same layers
            % as the SeriesNetwork object
            test.verifyThat( lgraph.Layers, IsEqualTo(ValidSeriesNetwork.Layers), ...
                "The property 'Layer' should contain the exact same layers as the SeriesNetwork object");
            
            % The property 'Connections' should contain a table with the
            % layers connected one after the other, preserving the order of
            % the 'Layer' array
            
            % Calculate connections table
            layerNames = {lgraph.Layers.Name}';
            Source = layerNames(1:end-1);
            Destination = layerNames(2:end);
            connections = table(Source,Destination);
            % Verify connection table is correctly calculated
            test.verifyThat( lgraph.Connections, IsEqualTo(connections), "Verify connection table is correctly calculated");
        end
        
        function canCreateLayerGraphFromDAGNetwork(test,ValidDAGNetwork)
            % Calling layerGraph with a DAGNetwork as input should
            % create a LayerGraph object with the expected properties

            import matlab.unittest.constraints.IsOfClass
            import matlab.unittest.constraints.IsEqualTo
            
            lgraph = layerGraph(ValidDAGNetwork);
            
            % The created object should be an external LayerGraph
            test.verifyThat( lgraph, IsOfClass('nnet.cnn.LayerGraph'), "Created object should be an external LayerGraph");
            
            % The property 'Layer' should contain the exact same layers
            % as the DAGNetwork object
            test.verifyThat( lgraph.Layers, IsEqualTo(ValidDAGNetwork.Layers) , ...
                "The property 'Layer' should contain the exact same layers as the DAGNetwork object");
            
            % The property 'Connections' should contain a table with the
            % exact same connections as the DAGNetwork
            test.verifyThat( lgraph.Connections, IsEqualTo(ValidDAGNetwork.Connections), ...
                "The property 'Connections' should contain a table with the exact same connections as the DAGNetwork");
        end

        function canCreateLayerGraphFromDlnetwork(test)

            import matlab.unittest.constraints.IsTrue

            lgraph = layerGraph([
                imageInputLayer([1 1],'Name','i','Normalization','none')
                convolution2dLayer(1,1,'Name','c','Weights',single(1),...
                    'Bias',single(0))
                reluLayer('Name','r')
                ]);
            net = dlnetwork(lgraph);
            newLgraph = layerGraph(net);
            
            test.verifyEqual(newLgraph.Connections, lgraph.Connections,...
                "The property 'Connections' from layerGraph created from dlnetwork should contain the exact same connections as the prebuilt layerGraph");
           
            % Here we want to test that the user-visible layer properties
            % are equal, not the internal layer properties. For this
            % reason, we use isequal.
            test.verifyThat(isequal(newLgraph, lgraph), IsTrue(), ...
                "User-visible layer properties are equal");
        end

    end %methods
end %classdef

%% Local Functions
function validLayerInputs = iGetValidLayerArrays()

singleInputLayer = imageInputLayer([15,20,3],'Name','in');
validLayerInputs.singleInputLayer = struct( ...
    'Layers', { singleInputLayer }, ...
    'Connections', iCreateConnectionsTable(singleInputLayer));

singleClassificationLayer = classificationLayer('Name','out');
validLayerInputs.singleClassificationLayer = struct( ...
    'Layers', { singleClassificationLayer }, ...
    'Connections', iCreateConnectionsTable(singleClassificationLayer));

singleRegressionLayer = regressionLayer('Name','out');
validLayerInputs.singleRegressionLayer = struct( ...
    'Layers', { singleRegressionLayer }, ...
    'Connections', iCreateConnectionsTable(singleRegressionLayer));

partialEndLayers = [
    softmaxLayer('Name','soft')
    classificationLayer('Name','Classify')];
validLayerInputs.partialEndLayers = struct( ...
    'Layers', { partialEndLayers }, ...
    'Connections', iCreateConnectionsTable(partialEndLayers));

midLayersWithAddition = [
    convolution2dLayer(5,20,'Name','conv')
    additionLayer(2,'Name','add')
    reluLayer('Name','relu')];
validLayerInputs.midLayersWithAddition = struct( ...
    'Layers', { midLayersWithAddition }, ...
    'Connections', iCreateConnectionsTable(midLayersWithAddition));

midLayersWithConcatenation = [
    depthConcatenationLayer(2,'Name','cat')
    maxPooling2dLayer(4,'Name','maxPool')];
validLayerInputs.midLayersWithConcatenation = struct( ...
    'Layers', { midLayersWithConcatenation }, ...
    'Connections', iCreateConnectionsTable(midLayersWithConcatenation));

multiOutputMaxPoolAndAdditionLayer = [
    maxPooling2dLayer(2,'HasUnpoolingOutputs',true,'Name','maxPool')
    depthConcatenationLayer(2,'Name','cat')];
validLayerInputs.multiOutputMaxPoolAndAdditionLayer = struct( ...
    'Layers', { multiOutputMaxPoolAndAdditionLayer }, ...
    'Connections', iCreateConnectionsTable(multiOutputMaxPoolAndAdditionLayer));

singleOutputMaxPoolAndAdditionLayer = [
    maxPooling2dLayer(2,'Name','maxPool')
    depthConcatenationLayer(2,'Name','cat')];
validLayerInputs.singleOutputMaxPoolAndAdditionLayer = struct( ...
    'Layers', { singleOutputMaxPoolAndAdditionLayer }, ...
    'Connections', iCreateConnectionsTable(singleOutputMaxPoolAndAdditionLayer));

net = iClassificationNetwork();
validLayerInputs.simpleClassificationLayers = struct( ...
    'Layers', { net.Layers }, ...
    'Connections', iCreateConnectionsTable(net.Layers) );

sequenceLayers = [ 
    sequenceInputLayer(3, 'Name', 'in')
    lstmLayer(2, 'Name', 'lstm')
    bilstmLayer(5, 'OutputMode', 'last', 'Name', 'bilstm') ];
validLayerInputs.sequenceLayers = struct( ...
    'Layers', { sequenceLayers }, ...
    'Connections', iCreateConnectionsTable(sequenceLayers));

cnnLSTMLayers = [
    convolution2dLayer(3, 10, 'Name', 'conv')
    reluLayer('Name', 'relu')
    lstmLayer(10, 'Name', 'lstm'); ];
validLayerInputs.cnnLSTMLayers = struct( ...
    'Layers', { cnnLSTMLayers }, ...
    'Connections', iCreateConnectionsTable(cnnLSTMLayers));

end

function validLayerInputs = iGetValidLayerArraysWithNotUniqueNames()

LayersWithoutAnyNames = [
    convolution2dLayer(3, 10)
    reluLayer()
    lstmLayer(10) ];
LayersWithDefaultNames = [
    convolution2dLayer(3, 10, 'Name', 'conv')
    reluLayer('Name', 'relu')
    lstmLayer(10, 'Name', 'lstm') ];
validLayerInputs.LayersWithoutAnyNames = struct( ...
    'Layers', { LayersWithoutAnyNames }, ...
    'LayersUniqueName', { LayersWithDefaultNames }, ...
    'Connections', iCreateConnectionsTable(LayersWithDefaultNames));

LayersWithOneMissingName = [
    convolution2dLayer(3, 10, 'Name', 'conv')
    reluLayer('Name', 'relu')
    lstmLayer(10) ];
LayersWithDefaultNames = [
    convolution2dLayer(3, 10, 'Name', 'conv')
    reluLayer('Name', 'relu')
    lstmLayer(10, 'Name', 'lstm') ];
validLayerInputs.LayersWithOneMissingName = struct( ...
    'Layers', { LayersWithOneMissingName }, ...
    'LayersUniqueName', { LayersWithDefaultNames }, ...
    'Connections', iCreateConnectionsTable(LayersWithDefaultNames));

LayersWithDuplicateEmptyName = [
    convolution2dLayer(3, 10, 'Name', '')
    reluLayer('Name', '')
    lstmLayer(10, 'Name', '')
    convolution2dLayer(3, 10, 'Name', '')
    reluLayer('Name', '')
    lstmLayer(10, 'Name', '') ];
LayersWithDefaultNames = [
    convolution2dLayer(3, 10, 'Name', 'conv_1')
    reluLayer('Name', 'relu_1')
    lstmLayer(10, 'Name', 'lstm_1')
    convolution2dLayer(3, 10, 'Name', 'conv_2')
    reluLayer('Name', 'relu_2')
    lstmLayer(10, 'Name', 'lstm_2')];
validLayerInputs.LayersWithDuplicateEmptyName = struct( ...
    'Layers', { LayersWithDuplicateEmptyName }, ...
    'LayersUniqueName', { LayersWithDefaultNames }, ...
    'Connections', iCreateConnectionsTable(LayersWithDefaultNames));

end

function params = iGetValidDAGnetworks()
% Load different DAGNetworks from file. The networks were trained with the
% helper function hTrainDAGNetworks.m
params.DAGNet = squeezenet;
end

function connections = iCreateConnectionsTable(layers)

numLayers = numel(layers);

if numLayers<2
    connections = table.empty(0,2);
else
    sourceLayer = (1:numLayers-1)';
    sourcePort = ones(numLayers-1,1);
    destinationLayer = (2:numLayers)';
    destinationPort = ones(numLayers-1,1);
    EndPorts = mat2cell([sourcePort,destinationPort],ones(numLayers-1,1));
    
    connections = table([sourceLayer,destinationLayer],EndPorts, ...
        'VariableNames', {'EndNodes','EndPorts'});
end
connections = nnet.internal.cnn.util.hiddenToInternalConnections(connections);
connections = nnet.internal.cnn.util.internalToExternalConnections(connections, layers);
connections = {connections};
end

function net = iClassificationNetwork()
% Returns a SeriesNetwork for a simple classification task on digits
S = load('digitRecognitionCNN.mat');
net = S.net;
end
