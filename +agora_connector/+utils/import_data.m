function import_package = import_data(http_client, paths, target_folder_id, json_import_file, wait)
import agora_connector.models.ImportPackage

if nargin < 3
    target_folder_id = [];
end
if nargin < 4
    json_import_file = [];
end
if nargin < 5
    wait = true;
end

if ~isempty(json_import_file) && ~exists(json_import_file, 'file')
    error('json_import_file does not exist');
end

import_package = ImportPackage(http_client);
import_package = import_package.create();
disp(['ImportPackage ID=', num2str(import_package.id)]);

import_package.upload(paths, target_folder_id, json_import_file, wait);