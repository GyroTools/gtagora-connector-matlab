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

        function dataset_types = get_dataset_types(self)
            import agora_connector.models.DatasetTypes
            dataset_types = DatasetTypes;
        end

        function filters = get_exam_filters(self)
            import agora_connector.models.FilterSet
            filters = FilterSet('exam');
        end

        function filters = get_series_filters(self)
            import agora_connector.models.FilterSet
            filters = FilterSet('series');
        end

        function filters = get_dataset_filters(self)
            import agora_connector.models.FilterSet
            filters = FilterSet('dataset');
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

        function session = create_upload_session(self, paths, target_folder_id, progress_file, json_import_file, verbose, wait)
            import agora_connector.models.UploadSession
            import agora_connector.models.UploadState

            if nargin < 3
                target_folder_id = [];
            end
            if nargin < 4
                progress_file = [];
            end
            if nargin < 5
                json_import_file = [];
            end  
            if nargin < 6
                verbose = true;
            end
            if nargin < 7
                wait = true;
            end

            if nargin == 2 && ischar(paths) && UploadState.is_progress_file(paths)
                progress_file = paths;
                paths = [];
            end


            if ~isempty(target_folder_id)
                try
                    self.get_folder(target_folder_id);
                catch
                    error(['The target folder with id ', num2str(target_folder_id), ' does not exist']);
                end
            end
            session = UploadSession(self.http_client, paths, target_folder_id, progress_file, json_import_file, verbose, wait);
        end  

        function logfiles = get_logfiles(self)
            import agora_connector.models.Logfile
            logfile = Logfile;
            logfiles = logfile.get_list(self.http_client);
        end

        function traffic = plot_traffic(self, interval_sec)
            import agora_connector.models.Logfile

            if nargin == 1
                interval_sec = 3600;           
            end

            logfiles = self.get_logfiles();
            if isempty(logfiles)
                return;
            end
            filenames = cell(1, length(logfiles));
            for i = 1:length(logfiles)
                filenames{i} = logfiles(i).filename;
            end
            [~, idx] = sort(filenames);
            logfiles = logfiles(idx);
            traffic = [];
            traffic_old = [];
            disp('parsing logfiles...');
            for i = 1:length(logfiles)                                
                [cur_traffic, cur_traffic_old] = logfiles(i).parse_traffic();
                if ~isempty(cur_traffic) || ~isempty(cur_traffic_old)
                    disp(['  ', logfiles(i).filename]);
                end
                if ~isempty(cur_traffic)                    
                    if isempty(traffic)
                        traffic = cur_traffic;
                    else
                        try
                            traffic = cat(1, traffic, cur_traffic);
                        catch
                        end
                    end
                end
                if ~isempty(cur_traffic_old)                    
                    if isempty(traffic)
                        traffic_old = cur_traffic_old;
                    else
                        try
                            traffic_old = cat(1, traffic_old, cur_traffic_old);
                        catch
                        end
                    end
                end
            end
            disp('creating plots');
            if ~isempty(traffic)
                Logfile.plot_traffic(traffic, interval_sec);
            elseif ~isempty(traffic_old)
                Logfile.plot_traffic(traffic_old, interval_sec);
            end
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

