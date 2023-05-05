classdef ClientLegacy
    % ClientLegacy: This handles all the html requests to Agora
    
    properties (Constant)
        mTimeout = 20;
    end
    
    methods (Static)
        function [IsConnection, ErrorMessage] = Ping(aURL)
            ErrorMessage = [];
            try
                connection = agora_connector.http.ConnectionLegacy(aURL, '', '');
                aURL = [aURL, '/api/v1/version/'];                
                Response = agora_connector.http.ClientLegacy.doGetRequest(aURL, connection);
                if isfield(Response, 'server')
                    IsConnection = true;
                else
                    IsConnection = false;
                end
            catch exeption
                IsConnection = false;
                ErrorMessage = sprintf( 'ERROR: %s', exeption.message );
            end
        end
        function [IsConnection, ErrorMessage] = CheckConnection(aURL, aConnection)
            ErrorMessage = [];
            if ~isa(aConnection, 'agora_connector.http.ConnectionLegacy') 
                error( 'aConnection must be a agora_connector.http.ConnectionLegacy');
            end
            try                                
                aURL = [aURL, '/api/v1/user/current/'];
                Response = agora_connector.http.ClientLegacy.doGetRequest(aURL, aConnection);                                
                if isfield(Response, 'institution')
                    IsConnection = true;
                else
                    IsConnection = false;
                end
            catch exeption
                IsConnection = false;
                ErrorMessage = sprintf( 'ERROR: %s', exeption.message );
            end
        end
        function DownloadedFile = Download(aURL, aConnection, aTargetFilename )
            if ~isa(aConnection, 'agora_connector.http.ConnectionLegacy') 
                error( 'aConnection must be a agora_connector.http.ConnectionLegacy');
            end
            
            [filepath,~,~] = fileparts(aTargetFilename);
            if ~exist(filepath, 'dir')              
                mkdir(filepath)              
            end
            
            aTimeout = agora_connector.http.ClientLegacy.mTimeout;            
            DownloadedFile = agora_connector.http.ClientLegacy.urldownload(aURL, aTargetFilename, aConnection, aTimeout);
            if exist(DownloadedFile, 'file') ~= 2
                DownloadedFile = [];
            end
        end
        function Response = doGetRequest(aURL, aConnection, aTimeout)
            if ~isa(aConnection, 'agora_connector.http.ConnectionLegacy') 
                error( 'aConnection must be a agora_connector.http.ConnectionLegacy');
            end
                        
            try
                if nargin == 2
                    aTimeout = agora_connector.http.ClientLegacy.mTimeout;
                end
                Response = agora_connector.http.ClientLegacy.urlget(aURL, aConnection, aTimeout);  
                
            catch exeption                
                error('ERROR: %s', exeption.message );
            end
        end
        function Response = doPostRequest(aURL, aData, aConnection, aTimeout)
            if ~isa(aConnection, 'agora_connector.http.ConnectionLegacy') 
                error( 'aConnection must be a agora_connector.http.ConnectionLegacy');
            end
                       
            try
                if nargin == 3
                    aTimeout = agora_connector.http.ClientLegacy.mTimeout;
                end
               
                Response = agora_connector.http.ClientLegacy.urlpost(aURL, aConnection, aData, aTimeout);  
            catch exeption                
                error('ERROR: %s', exeption.message);
            end
        end
        function Response = Upload(aURL, Files, TargetFiles, aConnection, aTimeout)
            if ~isa(aConnection, 'agora_connector.http.ConnectionLegacy')           
                error( 'aConnection must be a agora_connector.http.ConnectionLegacy');
            end

            if nargin < 5 || isempty(aTimeout)
                aTimeout = agora_connector.http.ClientLegacy.mTimeout;
            end
            
            Response = [];
            if ~iscell(Files)
                Files = {Files};
            end
            for i = 1:length(Files)                
                fid = fopen(Files{i});
                if fid == -1
                    ErrorMessage = ['Cannot open file ', Files{i}];
                    error(ErrorMessage);
                end
                fseek(fid, 0, 'eof');
                vFilesize = ftell(fid);
                fseek(fid, 0, 'bof');
                vNrChunks = ceil(vFilesize/agora_connector.http.ClientLegacy.getUploadChunkSize());
                                
                vFilename = TargetFiles{i};
                vUID = char(java.util.UUID.randomUUID);                              
                    
                for curChunk = 1:vNrChunks                   
                    d = fread(fid,agora_connector.http.ClientLegacy.getUploadChunkSize(),'*uint8'); % Read in byte stream                                        
                    agora_connector.http.ClientLegacy.urlupload(aURL, ...
                        {'description','','flowChunkNumber',num2str(curChunk),'flowChunkSize',num2str(agora_connector.http.ClientLegacy.getUploadChunkSize()),...
                        'flowCurrentChunkSize',num2str(length(d)), 'flowTotalSize',num2str(vFilesize), ...
                        'flowIdentifier', vUID, 'flowFilename', vFilename, ...
                        'flowRelativePath', vFilename, 'flowTotalChunks', num2str(vNrChunks), 'file',d,}...
                        , vFilename, aConnection, aTimeout);
                end
                fclose(fid);
            end  
        end
        function dataset = UploadDataset(Files, aConnection, parent, id, type)
            if ~isa(aConnection, 'agora_connector.http.ConnectionLegacy') 
                error( 'aConnection must be a agora_connector.http.ConnectionLegacy');
            end
                        
            if ~iscell(Files)
                Files = {Files};
            end
            for i = 1:length(Files)                
                fid = fopen(Files{i});
                if fid == -1
                    ErrorMessage = ['Cannot open file ', Files{i}];
                    error(ErrorMessage);
                end
            end
                
            dataset = gtAgoraDataset.Create(aConnection, parent, id, type);
            vURL = [aConnection.mURL, '/api/v1/dataset/', num2str(dataset.id), '/upload/'];
            agora_connector.http.ClientLegacy.Upload(vURL, Files, aConnection);                                                              
        end
        function Response = Delete(aURL, aConnection)
            if ~isa(aConnection, 'agora_connector.http.ConnectionLegacy') 
                error( 'aConnection must be a agora_connector.http.ConnectionLegacy');
            end
                        
            aTimeout = agora_connector.http.ClientLegacy.mTimeout;                                       
            Response = agora_connector.http.ClientLegacy.urldelete(aURL, aConnection, aTimeout);
        end
        function NrItems = GetNrItems(aURL, aConnection)
            if ~isa(aConnection, 'agora_connector.http.ConnectionLegacy') 
                error( 'aConnection must be a agora_connector.http.ConnectionLegacy');
            end
            
            % limit is already specified in the url --> replace it with
            % limit=1
            if ~isempty(strfind(aURL, 'limit='))
                aURL = regexprep(aURL,'(.*limit=)(\d*)(.*)','$11$3');
            elseif ~isempty(strfind(aURL, '/?'))
                % There is already a filter in the URL --> Add &limit=1
                aURL = [aURL, '&limit=1'];
            elseif aURL(end) == '/'
                aURL = [aURL, '?limit=1'];
            else
                aURL = [aURL, '/?limit=1'];
            end
            Response = agora_connector.http.ClientLegacy.doGetRequest(aURL, aConnection);
            if isfield(Response, 'results') && isfield(Response, 'count')
                NrItems = Response.count;
            else
                NrItems = 0;
            end
        end
        
    end
    
    methods (Static, Hidden)
        function [output,status] = urlget(urlChar, aConnection, aTimeout)                        
            % Check number of inputs and outputs.
            narginchk(3,3);
            nargoutchk(0,2,nargout);            
            urlConnection = agora_connector.http.ClientLegacy.urlgetconnection(urlChar,aConnection, aTimeout);  
            urlConnection.setRequestMethod('GET');
            [output,status] = agora_connector.http.ClientLegacy.urldorequest(urlConnection, aConnection);         
        end
        function [output,status] = urlpost(urlChar, aConnection, aData, aTimeout)                        
            % Check number of inputs and outputs.
            narginchk(4,4);
            nargoutchk(0,2,nargout);            
            urlConnection = agora_connector.http.ClientLegacy.urlgetconnection(urlChar,aConnection, aTimeout);  
            urlConnection.setRequestMethod('POST');
            postData = jsonencode(aData);
            printStream = java.io.PrintStream(urlConnection.getOutputStream);           
            printStream.print(postData);
            printStream.close;
            [output,status] = agora_connector.http.ClientLegacy.urldorequest(urlConnection, aConnection);         
        end
        function [output,status] = urldelete(urlChar, aConnection, aTimeout)                        
            % Check number of inputs and outputs.
            narginchk(3,3);
            nargoutchk(0,2,nargout);            
            urlConnection = agora_connector.http.ClientLegacy.urlgetconnection(urlChar,aConnection, aTimeout);  
            urlConnection.setRequestMethod('DELETE');
            [output,status] = agora_connector.http.ClientLegacy.urldorequest(urlConnection, aConnection);         
        end
        function [output,status] = urlupload(urlChar, params, filename, aConnection, aTimeout)                        
            % Check number of inputs and outputs.
            narginchk(5,5);
            nargoutchk(0,2,nargout);            
            urlConnection = agora_connector.http.ClientLegacy.urlgetconnection(urlChar,aConnection, aTimeout);  
            urlConnection.setRequestMethod('POST');
            
            boundary = '***********************';            
            urlConnection.setRequestProperty( 'Content-Type',['multipart/form-data; boundary=',boundary]);            
            printStream = java.io.PrintStream(urlConnection.getOutputStream);
            % also create a binary stream
            dataOutputStream = java.io.DataOutputStream(urlConnection.getOutputStream);
            eol = [char(13),char(10)];
            for i=1:2:length(params)
                printStream.print(['--',boundary,eol]);
                printStream.print(['Content-Disposition: form-data; name="',params{i},'"']);
                if ~ischar(params{i+1})
                    % binary data is uploaded as an octet stream
                    % Echo Nest API demands a filename in this case
                    printStream.print(['; filename="', filename, '"',eol]);
                    printStream.print(['Content-Type: application/octet-stream',eol]);
                    printStream.print([eol]);
                    dataOutputStream.write(params{i+1},0,length(params{i+1}));
                    printStream.print([eol]);
                else
                    printStream.print([eol]);
                    printStream.print([eol]);
                    printStream.print([params{i+1},eol]);
                end
            end
            printStream.print(['--',boundary,'--',eol]);
            printStream.close;
            
            [output,status] = agora_connector.http.ClientLegacy.urldorequest(urlConnection, aConnection);         
        end 
        function [filename,status] = urldownload(urlChar, filename, aConnection, aTimeout)                        
            % Check number of inputs and outputs.
            narginchk(4,4);
            nargoutchk(0,2,nargout);            
            urlConnection = agora_connector.http.ClientLegacy.urlgetconnection(urlChar,aConnection, aTimeout);  
            urlConnection.setRequestMethod('GET');
            [~, status] = agora_connector.http.ClientLegacy.urldorequest(urlConnection, aConnection, filename);                      
        end 
        function urlConnection = urlgetconnection(urlChar,aConnection,aTimeout)
            if ~usejava('jvm')
                error('MATLAB:urlreadpost:NoJvm','URLREADPOST requires Java.');
            end
            
            if ~isa(aConnection, 'agora_connector.http.ConnectionLegacy') 
                error( 'aConnection must be a agora_connector.http.ConnectionLegacy');
            end
                        
            import com.mathworks.mlwidgets.io.InterruptibleStreamCopier;
            
            % Be sure the proxy settings are set.
            com.mathworks.mlwidgets.html.HTMLPrefs.setProxySettings
            
            % Check number of inputs and outputs.
            narginchk(3,3);
            nargoutchk(0,3,nargout);
            if ~ischar(urlChar)
                error('MATLAB:urlreadpost:InvalidInput','The first input, the URL, must be a character array.');
            end
                                                                        
            % Create a urlConnection.
            [urlConnection,errorid,errormsg] = agora_connector.http.ClientLegacy.urlreadwrite(urlChar);
            if isempty(urlConnection)
               error(errorid,errormsg);               
            end
            
            if ~isempty(aConnection.mApiKey)
                basicAuth = ['X-Agora-Api-Key ', aConnection.mApiKey];
            else
                userpass = [aConnection.mUser, ':', aConnection.mPassword];
                base64_userpass = char(org.apache.commons.codec.binary.Base64.encodeBase64(uint8(userpass)))';
                basicAuth = ['Basic ' , base64_userpass];
            end
            
            set_auth = true;
            if isempty(aConnection.mUser) && isempty(aConnection.mPassword) && isempty(aConnection.mApiKey)
                set_auth = false;
            end
                                    
            % POST method.  Write param/values to server.
            % Modified for multipart/form-data 2010-04-06 dpwe@ee.columbia.edu
            %    try
            if set_auth
                urlConnection.setRequestProperty('Authorization', basicAuth);
            end
            urlConnection.setDoOutput(true);                 
            urlConnection.setRequestProperty('Content-Type', 'application/json');
            urlConnection.setRequestProperty('Accept', 'application/json');
            urlConnection.setConnectTimeout(1000*aTimeout);
            urlConnection.setReadTimeout(1000*aTimeout);                    
        end
        function [output,status] = urldorequest(urlConnection, aConnection, filename)
            import com.mathworks.mlwidgets.io.InterruptibleStreamCopier;
            
            if nargin == 2
                filename = [];
            end
            
            % Set default outputs.
            output = '';            
            
            try
                inputStream = urlConnection.getInputStream;
                status = urlConnection.getResponseCode();
                if urlConnection.getResponseCode() == 301   % this is a redirect
                    new_url =  char(urlConnection.getHeaderField('Location'));
                    urlConnection = agora_connector.http.ClientLegacy.urlgetconnection(new_url,aConnection,urlConnection.getConnectTimeout())  
                    [output,status] = agora_connector.http.ClientLegacy.urldorequest(urlConnection,aConnection);
                    return;
                else
                    if ~isempty(filename)
                        [~, outputStream] = agora_connector.http.ClientLegacy.getFileOutputStream(filename);
                    else
                        outputStream = java.io.ByteArrayOutputStream;
                    end
                    
                    % This StreamCopier is unsupported and may change at any time.
                    isc = InterruptibleStreamCopier.getInterruptibleStreamCopier;
                    isc.copyStream(inputStream,outputStream);
                    inputStream.close;
                    outputStream.close;
                    if isempty(filename)
                        output = native2unicode(typecast(outputStream.toByteArray','uint8'),'UTF-8');
                        if ~isempty(output)
                            try 
                                output = jsondecode(output); 
                            catch 
                            end
                        end
                    end
                end
            catch exeption                               
                error('ERROR: %s', exeption.message);                
            end
        end
        function [urlConnection,errorid,errormsg] = urlreadwrite(urlChar)
            %URLREADWRITE A helper function for URLREAD and URLWRITE.
            
            %   Matthew J. Simoneau, June 2005
            %   Copyright 1984-2007 The MathWorks, Inc.
            %   $Revision: 1.1.6.3.6.1 $ $Date: 2009/01/30 22:37:42 $
            
            % Default output arguments.
            urlConnection = [];
            errorid = '';
            errormsg = '';
            
            % Determine the protocol (before the ":").
            protocol = urlChar(1:min(find(urlChar==':'))-1);
            
            % Try to use the native handler, not the ice.* classes.
            switch protocol
                case 'http'
                    try
                        handler = sun.net.www.protocol.http.Handler;
                    catch exception %#ok
                        handler = [];
                    end
                case 'https'
                    try
                        handler = sun.net.www.protocol.https.Handler;
                    catch exception %#ok
                        handler = [];
                    end
                otherwise
                    handler = [];
            end
            
            % Create the URL object.
            try
                if isempty(handler)
                    url = java.net.URL(urlChar);
                else
                    url = java.net.URL([],urlChar,handler);
                end
            catch exception %#ok
                errorid = 'MATLAB: InvalidUrl';
                errormsg = 'Either this URL could not be parsed or the protocol is not supported.';
                return
            end
            
            % Get the proxy information using MathWorks facilities for unified proxy
            % prefence settings.
            mwtcp = com.mathworks.net.transport.MWTransportClientPropertiesFactory.create();
            proxy = mwtcp.getProxy();
            
            
            % Open a connection to the URL.
            if isempty(proxy)
                urlConnection = url.openConnection;
            else
                urlConnection = url.openConnection(proxy);
            end
        end
        function [file,fileOutputStream] = getFileOutputStream(location)
            % Specify the full path to the file so that getAbsolutePath will work when the
            % current directory is not the startup directory and urlwrite is given a
            % relative path.
            
            agora_connector.http.ClientLegacy.validateFileAccess(location);
            file = java.io.File(location);
            fileOutputStream = java.io.FileOutputStream(file);
        end
        function validateFileAccess(location)
            % Ensure that the file is writeable and return full path name.
            
            % Validate the the file can be opened. This results in a file on the disk.
            fid = fopen(location,'w');
            if fid == -1
                error(mm('urlwrite','InvalidOutputLocation',location))
            end
            fclose(fid);
        end
        function checkJavaHeapSpace()
            heap_space = java.lang.Runtime.getRuntime.maxMemory;
            heap_space_mb = heap_space /1024/1024;
            if heap_space_mb < 900
                warning('The Java heap space of your Matlab is small. The upload performance will suffer. You should increase it via: Preferences->General->Java Heap memory (and restart Matlab).');
            end
        end
        function chunk_size = getUploadChunkSize()
            heap_space = java.lang.Runtime.getRuntime.maxMemory;
            heap_space_mb = heap_space /1024/1024;
            if heap_space_mb < 500
                chunk_size = 8*1024*1024;
            elseif heap_space_mb < 900
                chunk_size = 50*1024*1024;
            else
                chunk_size = 100*1024*1024;
            end
        end
    end
end

