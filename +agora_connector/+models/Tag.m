classdef Tag < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
    end
    
    properties (Constant)    
        BASE_URL = '/api/v2/tag-definition/';
    end
    
    methods
        function tag = create(self, http_client, name, user, project, group, color)
            import agora_connector.models.Tag

            if nargin > 1 && ~isempty(http_client)
                self.http_client = http_client;
            end
            if nargin < 4
                user = [];
            end
            if nargin < 5
                project = [];
            end
            if nargin < 6
                group = [];
            end
            if nargin < 7
                color = [];
            end

            if isempty(user) && isempty(project)
                error('Either user or project must be set');
            end

            data = struct();
            data.label = name;

            if ~isempty(user)
                data.user = user;
            end

            if ~isempty(project)
                if isnumeric(project)
                    data.project = project;
                elseif isa(project, 'agora_connector.models.Project')
                    data.project = project.id;
                else
                    error('Project must be an integer or a Project object');
                end
                data.visibility = 2;
                data.scope = 1;
            else
                data.visibility = 1;
                data.scope = 2;
            end

            if ~isempty(group)
                data.group = group;
            end
            if ~isempty(color)
                data.color = color;
            end

            response = self.http_client.post(self.BASE_URL, data);
            if ~isempty(response)
                tag = Tag(self.http_client);
                tag = tag.fill_from_data(response);
            else
                tag = [];
            end
        end
    end

    methods (Static)
        function objs = get_for_objects(objs, project_id)           
            import agora_connector.models.TagInstance
            import agora_connector.models.Tag

            if isempty(objs)
                return;
            end
            
            if nargin == 1
                project_id = 0;
            end

            if project_id == 0
                for i = 1:length(objs)
                    if ~isprop(objs(i),'project')
                        project_id = 0;
                        break;
                    else
                        if project_id == 0
                            project_id = objs(i).project;
                        end
                        if project_id ~= objs(i).project
                            project_id = 0;
                            break;
                        end
                    end
                end
            end
                                        
            url = TagInstance.BASE_URL;
            if project_id > 0
                url = strrep(url, '/tag-instance/', ['/project/', num2str(project_id), '/tag-instance/']);
            end
            http_client = objs(1).http_client;

            response = http_client.get(url);  
            instance = TagInstance(http_client);
            instances = instance.fill_from_data_array(response);                                            
            if ~isempty(instances)              
                tag = Tag;
                tag_definitions = tag.get_list(http_client);
                for i = 1:length(instances)
                    for j = 1:length(tag_definitions)
                        if tag_definitions(j).id == instances(i).tag_definition
                            instances(i).tag_definition = tag_definitions(j);                                                        
                            break;
                        end
                    end
                end                
            end   
           
            instances_map = containers.Map;
            for i = 1:length(instances)
                key = [instances(i).tagged_object_content_type, '_', num2str(instances(i).tagged_object_id)];
                if isKey(instances_map, key)
                    instances_map(key) = [instances_map(key), instances(i).tag_definition];
                else
                    instances_map(key) = [instances(i).tag_definition];
                end
            end
            instances = instances_map;  

            for i = 1:length(objs)     
                is_folder_item = isa(objs(i), 'agora_connector.models.FolderItem');                
                if ~isprop(objs(i),'tags')
                    objs(i).addprop('tags');
                end  
                if is_folder_item
                    if ~isprop(objs(i).content_object,'tags')
                        objs(i).content_object.addprop('tags');
                    end 
                end
                if is_folder_item
                    key = [objs(i).content_type, '_', num2str(objs(i).content_object.id)];
                else
                    key = [objs(i).get_content_type(), '_', num2str(objs(i).id)];
                end
                if isKey(instances, key)                              
                    objs(i).tags = instances(key);  
                    if is_folder_item
                        objs(i).content_object.tags = instances(key);
                    end
                else
                    objs(i).tags = [];  
                    if is_folder_item
                        objs(i).content_object.tags = [];
                    end
                end                
            end
        end
    end
end

