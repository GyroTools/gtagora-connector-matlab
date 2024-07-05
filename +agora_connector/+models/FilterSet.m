classdef FilterSet
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties (Dependent)
        fields;
    end

    properties (Hidden)
        filters = [];
    end

    properties (Constant, Hidden)
        exam_filters = containers.Map({'name', 'scanner_name', 'id', 'start_time', 'created_date'}, ...
            {agora_connector.models.Filter('name', 'string'), ...
            agora_connector.models.Filter('scanner_name', 'string'), ...
            agora_connector.models.Filter('id', 'number'), ...
            agora_connector.models.Filter('start_time', 'datetime'), ...
            agora_connector.models.Filter('created_date', 'datetime')});

        series_filters = containers.Map({'name', 'id'}, ...
            {agora_connector.models.Filter('name', 'string'), ...
            agora_connector.models.Filter('id', 'number')});

        dataset_filters = containers.Map({'name', 'id', 'type'}, ...
            {agora_connector.models.Filter('name', 'string'), ...
            agora_connector.models.Filter('id', 'number'), ...
            agora_connector.models.Filter('type', 'number')});
    end

    methods
        function self = FilterSet(class_name)
            if strcmpi(class_name, 'exam')
                self.filters = self.exam_filters;
            elseif strcmpi(class_name, 'series')
                self.filters = self.series_filters;
            elseif strcmpi(class_name, 'dataset')
                self.filters = self.dataset_filters;
            else
                error('the class does not exist');
            end
        end
        function fields = get_fields(self)
            fields = self.filters.keys();
        end

        function filter = get_filter(self, field)
            try
                filter = self.filters(field);
            catch
                error('the filter does not exist. Display a list of available fields with "get_filter_fields()"');
            end
        end

        function value = get.fields(self)
            value = self.get_fields();
        end
    end
end
