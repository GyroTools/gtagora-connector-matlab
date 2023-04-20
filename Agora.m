classdef Agora 
    %Agora - Matlab connector for Agora
    
    properties
       http_client = [];
    end
    
    properties (Constant)
    end
    
    methods
        function self = Agora(client)
            self.http_client = client;
%             self.set_default_client(client);
%             self.version = self.get_version();
%             self.version.needs('6.0.0', error_message='The python interface needs Agora version 6.0.0 or higher. Please update Agora')           
        end   
        
        function project = get_project(self, project_id)
            import agora_connector.models.Project
            project = Project;
            project = project.get(project_id, self.http_client);
        end
        
    end
    methods (Static)
        function agora = create(url, api_key, verify_certificate)
%         Creates an Agora instance. Prefer this method over using the Agora constructor.
% 
%         To authenticate use the api_key parameter 
% 
%         Arguments:
%             url {string} -- The base url of the Agora server (e.g "https://agora_connector.mycompany.com")
%             api_key {string} -- The API key 
% 
%         Returns:
%             Agora -- The agora instance

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

