classdef BaseModel < dynamicprops
    %UNTITLED8 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Abstract,Constant)
        BASE_URL;
    end

    properties
        http_client = [];
    end        
    
    methods
        function self = BaseModel(http_client)
            if nargin > 0
                self.http_client = http_client;
            end
        end
        
        function self = get(self, id, http_client)
            if nargin < 2
                id = [];
            end
            if nargin < 3
                http_client = [];
            end
            self.http_client = http_client;
            self = self.get_object(id);
        end
        
        function objects = get_list(self, http_client)            
            if nargin < 2
                http_client = [];
            end
            self.http_client = http_client;
            url = self.BASE_URL;
            objects = self.get_object_list(url);
        end

        function remove(self)
            url = [self.BASE_URL, num2str(self.id), '/'];
            self.http_client.delete(url);   
        end
    end
    
    methods (Hidden)
        function self = get_object(self, id)
            if nargin < 2
                id = [];
            end
            if ~isempty(id)
                url = [self.BASE_URL, num2str(id), '/'];            
            else
                url = self.BASE_URL;
            end

            data = self.http_client.get(url);       
            self = self.fill_from_data(data);
        end
        
        function self = fill_from_data(self, data)
            fn = fieldnames(data);
            for i = 1:length(fn)
                self.addprop(fn{i});
                self.(fn{i}) = data.(fn{i});
            end
        end
        
        function object_list = fill_from_data_array(self, data)
            if isfield(data, 'results') && isfield(data, 'count')
                results = data.results;
                if data.count == 0
                    object_list = [];
                    return;
                end
                if data.count ~= length(results)
                    warning('could not get all series');
                end

                object_list(length(results)) = feval( class(self) );
                for i = 1:length(results)
                    object_list(i) = object_list(i).fill_from_data(results(i));
                    object_list(i).http_client = self.http_client;
                end
             elseif length(data) > 1
                 object_list(length(data)) = feval( class(self) );
                 for i = 1:length(data)
                    object_list(i) = object_list(i).fill_from_data(data(i));
                    object_list(i).http_client = self.http_client;
                 end                
             else
                object_list = self.fill_from_data(data);
                object_list.http_client = self.http_client;
            end
        end
        
        function object_list = get_object_list(self, url)            
            if isempty(self.http_client)
                error('http client not set');
            end
            object_list = [];
            data = self.http_client.get(url);   
            if ~isempty(data)
                object_list = fill_from_data_array(self, data);
            end
        end

        function name = get_class_name(self, full)
            if nargin < 2
                full = false;
            end
            name = class(self);
            if ~full 
                splitted = strsplit(name,'.');
                name = splitted{end};
            end
        end

        function path = remove_illegal_chars(self, path)
            illegal = [':', '*', '"', '<', '>', '|'];

            for i = 1:length(illegal)
                path = strrep(path, illegal(i), '');
            end

        end
    end       
end

