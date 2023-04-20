function url = validate_url(url)
% check if the url has a scheme. If not then add it
u = agora_connector.utils.urlparse(url);
if ~strcmpi(u.scheme, 'http:') && ~strcmpi(u.scheme, 'https:')
    url = ['http://', url];
    u = agora_connector.utils.urlparse(url);
end

if ~isempty(u.path)
    url = [u.scheme, u.authority];
end
