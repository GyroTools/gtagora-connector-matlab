classdef ConnectionLegacy 
    % gtAgoraConnection: This class holds the connection settings for Agora
    % (URL and credentials) 
    
    properties
        mURL = [];
        mUser = [];       
        mApiKey = [];
    end
    
    properties (Hidden)
        mPassword = [];
    end
    
    methods
        function C = ConnectionLegacy(aURL, aUser_ApiKey, aPassword)                      
           C.mURL = aURL;
           if nargin == 2
               C.mApiKey = aUser_ApiKey;
           else
               C.mUser = aUser_ApiKey;
               C.mPassword = aPassword;
           end
        end
        function options = GetWeboptions(C)
            options = weboptions;
            if ~isempty(C.mApiKey)
                options.KeyName = 'Authorization';
                options.KeyValue = ['X-Agora-Api-Key ', C.mApiKey];
            else                
                options.Username = C.mUser;
                options.Password = C.mPassword;
            end
        end
    end
    
end

