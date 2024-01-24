classdef (Abstract, HandleCompatible) WorkbookMixin
    properties(Abstract,Constant)
        BASE_URL;
    end

    methods
        function wb = workbooks(self)
            try
                wb = self.get_v2();
            catch
                wb = self.get_v1();
            end
            if ~isempty(wb)
                for i = 1:length(wb)
                    wb(i) = wb(i).decode_masks();
                end
            end
        end
    end

    methods (Hidden)
        function wb = get_v1(self)
            import agora_connector.models.Workbook
            wb = [];
            url = [self.BASE_URL, num2str(self.id), '/userdata/?type=contour'];           
            response_contour = self.http_client.get(url);
            if ~isempty(response_contour)
                url = [self.BASE_URL, num2str(self.id), '/userdata/?type=map'];  
                response_mask = self.http_client.get(url);  
            end
            for i = 1:length(response_contour)
                response_contour(i).data.mMasks = [];
                if isfield(response_contour(i).data, 'mWorkbookId')
                    contour_workbook = response_contour(i).data.mWorkbookId;
                else
                    contour_workbook = 1;
                end
                for j = 1:length(response_mask)
                    if isfield(response_mask(j).data, 'mWorkbookId')
                        mask_workbook = response_mask(j).data.mWorkbookId;
                    else
                        response_mask = 1;
                    end
                    if contour_workbook == mask_workbook
                        response_contour(i).data.mMasks = response_mask(j).data.mMasks;
                        break;
                    end
                end
            end
            if ~isempty(response_contour)
                instance = Workbook(self.http_client);
                wbv1 = instance.fill_from_data_array(response_contour);
                if ~isempty(wbv1)
                    for i = 1:length(wbv1)
                        wb = self.to_v2(wbv1);
                    end
                    wb = instance.fill_from_data_array(wb);
                end
            end
        end
        function wb = get_v2(self)
            import agora_connector.models.Workbook

            url = [self.BASE_URL_V2, num2str(self.id), '/workbook/'];           
            response = self.http_client.get(url);
            if ~isempty(response)
                instance = Workbook(self.http_client);
                wb = instance.fill_from_data_array(response);                
            end
        end

    end

    methods(Abstract)
        type = get_content_type(self);
    end

    methods (Static, Hidden)
        function wbv2 = to_v2(wb)
            for i = 1:length(wb)               
                wbv2(i).http_client = wb(i).http_client;
                if isprop(wb(i), 'id')
                    wbv2(i).id = wb(i).id;
                end
                if isprop(wb(i), 'data')                    
                    if isfield(wb(i).data, 'contourGroups')
                        wbv2(i).contour.contourGroups = wb(i).data.contourGroups;
                    end
                    if isfield(wb(i).data, 'objectButtons')
                        wbv2(i).contour.objectButtons = wb(i).data.objectButtons;
                    end
                    if isfield(wb(i).data, 'landmarkGroups')
                        wbv2(i).contour.landmarkGroups = wb(i).data.landmarkGroups;
                    end
                end                
                wbv2(i).dataset = wb(i).datasets(1);
                wbv2(i).type = 1;
                if isfield(wb(i).data, 'description')
                    wbv2(i).description = wb(i).data.description;
                end
                if isfield(wb(i).data, 'mMasks')
                    wbv2(i).mask.mMasks = wb(i).data.mMasks;
                end
                if isfield(wb(i).data, 'name')
                    wbv2(i).name = wb(i).data.name;
                end
                wbv2(i).user = [];
                wbv2(i).created_date = '';
                wbv2(i).modified_date = '';
            end
        end
    end
end

