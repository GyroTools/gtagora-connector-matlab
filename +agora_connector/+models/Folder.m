classdef Folder < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
    end
    
    properties (Constant)
        BASE_URL = '/api/v1/folder/'
    end
    
    methods  
        function items = get_items(self)
            import agora_connector.models.FolderItem

            items = [];
            url = [self.BASE_URL, num2str(self.id), '/items/?limit=10000000000'];
            resp_items = self.http_client.get(url);
            for i = 1:length(resp_items)
                folder_item = FolderItem(self.http_client);
                items = [items, folder_item.fill_from_data(resp_items(i))];
            end
        end

        function item = get_item(self, name, type)
            if nargin < 3
                type = [];
            end
            items = self.get_items();
            for i = 1:length(items)
                if ~isempty(type)
                    if strcmp(items(i).content_object.name, name) && strcmp(items(i).content_type, type)
                        item = items(i).content_object;
                        return;
                    end
                else
                    if strcmp(items(i).content_object.name, name)
                        item = items(i).content_object;
                        return;
                    end
                end
            end
            item = [];
        end

        function folders = get_folders(self)
            folders = self.get_objs('folder');
        end

        function folder = create(self, name)
            if self.exists(name, 'folder')
                error(['a folder with the name "', name, '" already exists']);
            end
            url = [self.BASE_URL, num2str(self.id), '/new/'];
            data = struct;
            data.name = name;
            response = self.http_client.post(url, data);            
            if isfield(response, 'content_object')
                folder = agora_connector.models.Folder;
                folder = folder.fill_from_data(response.content_object);
            end       
        end
               
        function next_folder = get_or_create(self, path)
            next_folder = self;
                        
            p = path;
            parts = {};
            while p ~= '\'
                [p, part] = fileparts(p);
                parts{end+1} = part;
            end
            parts = parts(end:-1:1);
            for j = 1:length(parts)
                part = parts{j};
                next_folder_exists = false;
                folders = next_folder.get_folders();
                for i = 1:length(folders)
                    if strcmp(folders(i).name, part)
                        next_folder = folders(i);
                        next_folder_exists = true;
                        break;
                    end
                end
                if ~next_folder_exists
                    next_folder = next_folder.create(part);
                end
            end          
        end

        function downloaded_files = download(self, path, flat)
            if nargin < 3
                flat = false;
            end

            downloaded_files = [];
            items = self.get_items();
            for i = 1:length(items)
                item_path = path;
                if ~strcmpi(items(i).content_type, 'dataset')
                    if ~flat
                        item_path = fullfile(path, self.remove_illegal_chars(items(i).content_object.name));
                    end
                end
                if any(strcmpi(items(i).content_type, {'exam', 'folder'}))
                    downloaded_files = [downloaded_files, items(i).content_object.download(item_path, flat)];  
                else
                    downloaded_files = [downloaded_files, items(i).content_object.download(item_path)];                    
                end
            end
        end

        function val = exists(self, name, type)
            val = false;
            objs = self.get_objs(type);
            for i = 1:length(objs)
                if strcmp(objs(i).name, name)
                    val = true;
                    return;
                end
            end
        end
    end

    methods(Hidden)
        function objs = get_objs(self, obj_name)
            objs = [];
            items = self.get_items();
            for i = 1:length(items)
                if strcmpi(items(i).content_type, obj_name)
                    objs = [objs, items(i).content_object];
                end
            end
        end
    end
end

