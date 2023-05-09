classdef Task < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here

    properties
    end

    properties (Constant)
        BASE_URL = '/api/v1/taskdefinition/'

        INPUT_TYPE_EXAM = 1;
        INPUT_TYPE_SERIES = 2;
        INPUT_TYPE_DATASET = 3;
        INPUT_TYPE_FILE = 4;
        INPUT_TYPE_STRING = 5;
        INPUT_TYPE_INTEGER = 6;
        INPUT_TYPE_FLOAT = 7;
        INPUT_TYPE_SELECT = 8;
        INPUT_TYPE_FOLDER = 9;
    end

    methods
        % This function runs the task with the given input and target and returns the result
        function timeline = run(self, target, varargin)  
            import agora_connector.models.TimelineItem

            body_inputs = self.get_inputs(varargin); % get the input dictionary from the keyword arguments            
            self.check_outputs(target); % check the outputs

            body = struct; % create an empty struct

            if nargin > 2 % check if target is given
                object_name = lower(class(target)); % get the target class name as a lowercase string
                body.target = struct('object_id', target.id, 'object_type', strrep(object_name, 'agora_connector.models.', '')); % add a struct to the data struct
            else
                body.target = []; % set the target to empty
            end

            body.inputs = body_inputs; % add the input dictionary to the data struct

            url = sprintf('%s%d/run/', self.BASE_URL, self.id); 
            data = self.http_client.post(url, body, 60);  
            timeline = TimelineItem(self.http_client);
            timeline = timeline.fill_from_data(data); % get a list of TimelineItem objects from the data                            
        end
    end

    methods (Hidden)
        % This function gets the inputs from the arguments and returns a dictionary
        function body_inputs = get_inputs(self, arguments)
            import agora_connector.models.Task
            body_inputs = struct;
            for i = 1:length(self.inputs) 
                input = self.inputs(i);
                argument_ind = find(cellfun(@(x) strcmp(x, input.key), arguments, 'UniformOutput', 1));
                if isempty(argument_ind)
                    error('\n\nThe task input ''%s'' is unassigned.\nRun the task with the following command:\n\n%s', input.key, self.get_run_cmd()); % raise an exception
                end

                argument_name = input.key; % get the argument name
                argument = arguments{argument_ind+1}; % get the argument value
                argument_type = lower(class(argument)); % get the argument type as a lowercase string
                input_type = self.get_type_name(input.type); % get the input type name

                if isa(argument, 'agora_connector.models.BaseModel') % check if the argument is an instance of BaseModel
                    if ~strcmp(strrep(argument_type, 'agora_connector.models.', ''), self.get_type_name(input.type)) % check if the argument type matches the input type
                        self.raise_input_error(input); % raise an input error
                    end
                    body_inputs.(argument_name) = struct('object_id', argument.id, 'object_type', input_type); % add a struct to the dictionary
                elseif input.type < Task.INPUT_TYPE_STRING || input.type == Task.INPUT_TYPE_FOLDER % check if the input type is less than string or equal to folder
                    if ~isa(argument, 'int') % check if the argument is an integer
                        self.raise_input_error(input); % raise an input error
                    end
                    body_inputs.(argument_name) = struct('object_id', argument, 'object_type', input_type); % add a struct to the dictionary
                elseif input.type == Task.INPUT_TYPE_STRING % check if the input type is string
                    if ~isa(argument, 'char') % check if the argument is a character array
                        self.raise_input_error(input); % raise an input error
                    end
                    body_inputs.(argument_name) = argument; % add the argument to the dictionary
                elseif input.type == Task.INPUT_TYPE_INTEGER % check if the input type is integer   
                    if floor(argument) == argument
                        argument = int32(argument);
                    else
                        argument = single(argument);
                    end
                    if ~isa(argument, 'int32') % check if the argument is an integer
                        self.raise_input_error(input); % raise an input error
                    end
                    body_inputs.(argument_name) = argument; % add the argument to the dictionary
                elseif input.type == Task.INPUT_TYPE_FLOAT % check if the input type is float
                    if floor(argument) == argument
                        argument = int32(argument);
                    else
                        argument = single(argument);
                    end
                    if ~isa(argument, 'single') % check if the argument is a double-precision floating-point number
                        self.raise_input_error(input); % raise an input error
                    end
                    body_inputs.(argument_name) = argument; % add the argument to the dictionary
                end

            end          
        end

        function check_outputs(self, target)
            if ~isempty(self.outputs) && isempty(target)
                error(['The "target" argument is missing (e.g. the output folder). Run the task with the following command:\n\n', self.get_run_cmd()]);
            end

            if ~isempty(self.outputs) && ~isa(target, 'agora_connector.models.BaseModel')
                error('The target must be an Agora object (e.g. a folder)');
            end
        end
    end

    methods (Static)
        function name = get_type_name(type)
            import agora_connector.models.Task

            if type == 0
                name = 'none';
            elseif type == Task.INPUT_TYPE_EXAM
                name = 'exam';
            elseif type == Task.INPUT_TYPE_SERIES
                name = 'series';
            elseif type == Task.INPUT_TYPE_DATASET
                name = 'dataset';
            elseif type == Task.INPUT_TYPE_FOLDER
                name = 'folder';
            elseif type == Task.INPUT_TYPE_STRING
                name = 'string';
            elseif type == Task.INPUT_TYPE_INTEGER
                name = 'integer';
            elseif type == Task.INPUT_TYPE_FLOAT
                name = 'float';
            elseif type == Task.INPUT_TYPE_SELECT
                name = 'select';
            end
        end
    end
end

