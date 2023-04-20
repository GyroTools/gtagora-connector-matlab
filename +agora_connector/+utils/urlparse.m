function results = urlparse(url1)
% urlParse parse a URL and return components
%   URLPARSE(URL) This small utility is an URI/URL decoder. Given a string, 
%   it returns a structure with parts composing the URI, according to 
%   https://en.wikipedia.org/wiki/Uniform_Resource_Identifier

% A URI syntax is:
%   URI = scheme:[//authority]path[?query][#fragment]
% where authority can be [userinfo@]host[:port].
%
% Example:
%  url1 = 'https://www.mathworks.com/matlabcentral/fileexchange/?term=example#total_results_az_footer';
%  res = urlParse(url1);
%  res = 

%         scheme: 'https:'
%      authority: '//www.mathworks.com'
%           path: '/matlabcentral/fileexchange/'
%          query: '?term=example'
%       fragment: '#total_results_az_footer'

%% URL parts expressions from <https://stackoverflow.com/questions/27745/getting-parts-of-a-url-regex>
urlScheme = '^(([^:?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?';

r = regexp( url1, urlScheme, 'tokens');
if ~isempty(r) && iscell(r{1})
  f = {'scheme','authority','path','query','fragment'};
  results = cell2struct(r{1}, f, 2);
else
  results = struct();
end
