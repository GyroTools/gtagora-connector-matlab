classdef Filter
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        field = [];
        operators = {}; 
    end
    properties       
        value = [];
        operator = [];              
    end    
    properties (Hidden, Constant)
        text_filter_operators = {'iexact', 'icontains', 'istartswith', 'iendswith', 'iregex', 'exact', 'contains', 'startswith', 'endswith', 'regex'};
        date_filter_operators = {'gte', 'gt', 'lte', 'lt', 'range', 'year', 'month', 'day', 'week', 'week_day', 'exact'};
        datetime_filter_operators =  {'gte', 'gt', 'lte', 'lt', 'range', 'year', 'month', 'day', 'week', 'week_day', 'exact', 'date__gte', 'date__gt', 'date__lte', 'date__lt', 'date__range', 'date__exact', 'hour', 'minute', 'second', 'time', 'date'};
        number_filter_operators = {'gte', 'gt', 'lte', 'lt', 'range', 'exact'};
    end
    properties (Hidden, SetAccess=private)
        type = [];
    end

    methods
        function self = Filter(field, type)
            self.type = type;
            self.field = field;
            if strcmpi(type, 'string')
                self.operators = self.text_filter_operators;
                self.operator = 'icontains';
            elseif strcmpi(type, 'number')
                self.operators = self.number_filter_operators;
                self.operator = 'exact';
            elseif strcmpi(type, 'date')
                self.operators = self.date_filter_operators;
                self.operator = 'exact';
            elseif strcmpi(type, 'datetime')
                self.operators = self.datetime_filter_operators;
                self.operator = 'exact';
            end
        end 
        function self = set.operator(self, value)
            if ~ischar(value)
                error('the operator must be a string');
            end

            if ismember(value, self.operators)
                self.operator = value;
            else
                error('invalid operator');
            end
        end
    end
end