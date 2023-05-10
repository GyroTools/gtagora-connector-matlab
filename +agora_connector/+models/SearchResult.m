classdef SearchResult < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        BASE_URL = '/api/v1/search/fulltext/';        
    end 
    
    methods (Static)
        function params = get_url_params(search_string, result_type)
            if nargin < 2
                result_type = 0;
            end
            if ischar(result_type)
                result_type = lower(result_type);
                switch result_type
                    case 'all'
                        result_type = 0;
                    case 'project'
                        result_type = 6;
                    case 'patient'
                        result_type = 5;
                    case 'study'
                        result_type = 2;
                    case 'exam'
                        result_type = 2;
                    case 'series'
                        result_type = 3;
                    case 'serie'
                        result_type = 3;
                    case 'dataset'
                        result_type = 4;
                    case 'folder'
                        result_type = 1;
                    case 'task'
                        result_type = 9;
                    case 'script_task'
                        result_type = 10;
                    case 'tag'
                        result_type = 11;                   
                    otherwise
                        error('unknown result_type');
                end             
            end
            params = ['?q=', search_string, '&t=', num2str(result_type)];
        end
    end
end

