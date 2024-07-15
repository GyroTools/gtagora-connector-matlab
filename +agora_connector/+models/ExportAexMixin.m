classdef (Abstract, HandleCompatible) ExportAexMixin    
    methods       
        function aex_file = export(self, outdir, varargin)
            import agora_connector.models.DownloadFile  

            p = inputParser;
            booleanValidator = @(x) islogical(x) || (isnumeric(x) && isscalar(x) && (x == 0 || x == 1));            
            addOptional(p,'progress', false, booleanValidator);    
            addOptional(p,'compression', false, booleanValidator);
            parse(p, varargin{:});
            options = p.Results;

            if ~exist(outdir, 'dir')
                error('the output directory does not exist');
            end
            
            % download aex
            url = DownloadFile.project_url(self.project);
            body = self.get_base_body_aex();  
            if options.compression
                body.compression = true;
            end
            if options.progress
                disp('requesting aex file...');
            end
            data = self.http_client.post(url, body, 60);
            download_file = DownloadFile(self.http_client);
            download_file.fill_from_data(data);
            while(~download_file.ready)
                pause(0.5);
                download_file.get(download_file.id, download_file.http_client);
                if ~download_file.ready && ~isempty(download_file.error)
                    error(['error exporting the aex file: ', download_file.error]);
                end
            end
            if isempty(download_file.download_name)
                aex_file = [tempname(outdir), '.aex.'];
            else
                aex_file = fullfile(outdir, download_file.download_name);
            end
            url = [DownloadFile.BASE_URL, num2str(download_file.id), '/download/'];
            if options.progress
                disp(['downloading ', aex_file, '...']);
            end
            download_file.http_client.download(url, aex_file);                    
        end       
    end 
    methods (Hidden, Access=protected)
        function body = get_base_body_aex(self)            
            body = struct();
            if isa(self, 'agora_connector.models.Exam')
                body.exam_ids = {self.id};
            elseif isa(self, 'agora_connector.models.Folder')
                body.folder_ids = {self.id};
            elseif isa(self, 'agora_connector.models.Series')
                body.series_ids = {self.id};
            elseif isa(self, 'agora_connector.models.Dataset')
                body.dataset_ids = {self.id};
            end    
            body.aex = true;            
        end
    end
end

