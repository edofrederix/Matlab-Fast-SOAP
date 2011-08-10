%
% Matlab Fast SOAP - a faster Matlab replacement for the default SOAP
% functions
%   
% parseSoapResponse, part of Matlab Fast SOAP
%

%
% Written by:
% 
% Edo Frederix
% The Johns Hopkins University / Eindhoven University of Technology
% Department of Mechanical Engineering
% edofrederix@jhu.edu, edofrederix@gmail.com
%

%
% This file is part of Matlab Fast SOAP.
% 
% Matlab Fast SOAP is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by the
% Free Software Foundation, either version 3 of the License, or (at your
% option) any later version.
% 
% Matlab Fast SOAP is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along
% with Matlab Fast SOAP. If not, see <http://www.gnu.org/licenses/>.
%

function s = parseSoapResponse(response)

    matches = regexpi(response, '<soap:Body>(?<content>.*)</soap:Body>', 'names');
  
    s = fetchXML(matches.content);
    
end

%==========================================================================
function s = fetchXML(xml)
    tic
    [match matches] = regexpi(xml, '<(?<tag>[a-z0-9]*)[^>]*>(?<val>.*?)<[/]\1>', 'match', 'names');
    toc
    
    if isempty(matches)
        s = xml;
    else 
        s = struct();
        if numel(matches) == 1
            s.(matches.tag) = fetchXML(matches.val); 
        else
            if footprint(match{1}) == footprint(match{2})
                s.(matches(1).tag) = regexpi(xml, footprint(match{1}), 'names');
            else
                for i=1:numel(matches)        
                    s(i).(matches(i).tag) = fetchXML(matches(i).val);   
                end
            end
        end
    end
end

%==========================================================================
function fp = footprint(xml)
    tok = regexpi(xml, '<([a-z0-9]*)[^>]*>(.*?)<[/]\1>', 'tokens');
    
    if isempty(tok)
        fp = 'value';
    else 
        fp = '';
        for i=1:numel(tok)        
            new = footprint(tok{i}{2});
            if strcmp(new, 'value')
                new = sprintf('(?<%s>.*?)', tok{i}{1});
            end
            fp = sprintf('%s<%s>%s</%s>', fp, tok{i}{1}, new, tok{i}{1});
        end
    end
end