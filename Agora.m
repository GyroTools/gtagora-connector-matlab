classdef Agora 
    %Agora - Matlab connector for Agora
    
    properties
       http_client = [];
       version = '0.0.1';
    end
    
    properties (Constant)
    end
    
    methods
        function self = Agora(client)
            self.http_client = client;
            self.version = self.get_version();
            self.version.needs('6.0.0', 'The python interface needs Agora version 6.0.0 or higher. Please update Agora');
        end   
        
        function projects = get_projects(self)
            import agora_connector.models.Project
            project = Project;
            projects = project.get_list(self.http_client);
        end
            
        function project = get_project(self, id_or_name)
            import agora_connector.models.Project
            if ischar(id_or_name)
                projects = self.get_projects();
                for i = 1:length(projects)
                    if strcmp(projects(i).name, id_or_name)
                        project = projects(i);
                        return;
                    end                    
                end
                error('project not found');
            else
                project = Project;
                project = project.get(id_or_name, self.http_client);
            end
        end
        
        function project = get_myagora(self)
            import agora_connector.models.Project
            project = Project;
            project = project.get('myagora', self.http_client);
        end  
        
        function roles = get_project_roles(self)
            import agora_connector.models.ProjectRole
            roles = ProjectRole;
            roles = roles.get_list(self.http_client);
        end  
            
        function exam = get_exam(self, id)
            import agora_connector.models.Exam
            exam = Exam;
            exam = exam.get(id, self.http_client);
        end
        
        function series = get_series(self, id)
            import agora_connector.models.Series
            series = Series;
            series = series.get(id, self.http_client);
        end
        
        function dataset = get_dataset(self, id)
            import agora_connector.models.Dataset
            dataset = Dataset;
            dataset = dataset.get(id, self.http_client);
        end
        
        function folder = get_folder(self, id)
            import agora_connector.models.Folder
            folder = Folder;
            folder = folder.get(id, self.http_client);
        end

        function task = get_task(self, id)
            import agora_connector.models.Task
            task = Task;
            task = task.get(id, self.http_client);
        end
        
        function version = get_version(self)
            import agora_connector.models.Version
            version = Version;
            version = version.get([], self.http_client);
        end  
        
        function tags = get_tags(self)
            import agora_connector.models.Tag
            tag = Tag;
            tags = tag.get_list(self.http_client);
        end 
        
        function tag = get_tag(self, id_or_name)
            import agora_connector.models.Tag
            if ischar(id_or_name)
                tags = self.get_tags();
                for i = 1:length(tags)
                    if strcmp(tags(i).label, id_or_name)
                        tag = tags(i);
                        return;
                    end                    
                end
                error('tag not found');
            else
                tag = Tag;
                tag = tag.get(id_or_name, self.http_client);
            end
        end
        
        function users = get_users(self)
            import agora_connector.models.User
            users = User;
            users = users.get_list(self.http_client);
        end 
        
        function results = search(self, search_string, result_type)
            import agora_connector.models.SearchResult
            
            if nargin < 3
                result_type = 0;
            end
            params = SearchResult.get_url_params(search_string, result_type);
            results = SearchResult;
            url = [results.BASE_URL, params];            
            results = results.get_list(self.http_client, url, 60);
        end

    end
    methods (Static)
        function agora = create(url, api_key, verify_certificate)
            % Creates an Agora instance. Prefer this method over using the Agora constructor.
            % 
            % To authenticate use the api_key parameter 
            % 
            % Arguments:
            %     url {string} -- The base url of the Agora server (e.g "https://agora_connector.mycompany.com")
            %     api_key {string} -- The API key 
            % 
            % Returns:
            %     Agora -- The agora instance

            import agora_connector.utils.validate_url
            import agora_connector.http.ApiKeyConnection
            import agora_connector.http.Client
            
            if nargin < 3
                verify_certificate = false;
            end
            
            url = validate_url(url);
            connection = ApiKeyConnection(url, api_key, verify_certificate);
            client = Client(connection);
            
            if ~client.check_connection()
                error(['Could not connect to the Agora server at ' , url]);
            end
            agora = Agora(client);
        end
    end
end

