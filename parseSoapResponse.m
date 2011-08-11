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

    matches = regexpi(response, '<soap:Body[^>]*>.*<(?<method>[a-z0-9]*)response[^>]*>(?<content>.*)</(?:[a-z0-9]*)response>.*</soap:Body>', 'names');
  
    s = fetchXML(matches.content);
    
end

%==========================================================================
function s = fetchXML(xml)

    regex = '<(?<tag>[a-z0-9]*)[^>]*>(?<val>.*?)<[/]\1>';
    [match matches] = regexpi(xml, regex, 'match', 'names');
    
    if isempty(matches)
        s = xml;
    else 
        % Check tags
        s = struct();
        if numel(matches) == 1
            s.(matches.tag) = fetchXML(matches.val); 
        else
            % Check footprint
            fp1 = footprint(match{1});
            fp2 = footprint(match{1});
            if strcmp(fp1, fp2)
                s.(matches(1).tag) = swapStruct(regexpi(xml, fp1, 'names'));
                
                % Check for remainder
                xml = regexprep(xml, fp1, '', 'ignorecase');
                if ~isempty(xml)
                    s = mergeStruct(s, fetchXML(xml));
                end 

            else
                for i=1:numel(matches)
                    s.(matches(i).tag) = fetchXML(matches(i).val);
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

%==========================================================================
function s1 = mergeStruct(s1, s2)
    if numel(s1) ~= numel(s2)
        error('Arguments are not consistent in structure field number.');
    end
    
    % Update s1 with s2
    keys = fieldnames(s2);
    for i = 1:numel(keys)
        key = keys{i};
        for j = 1:numel(s1)
            s1(j).(key) = s2(j).(key);
        end
    end
end

%==========================================================================
function s2 = swapStruct(s1)

    keys = fieldnames(s1);
    cl = cell(numel(keys), numel(s1));
    for i = 1:numel(s1)
        cl(:,i) = struct2cell(s1(i));
    end
    
    s2 = struct();
    for i = 1:numel(keys)
        c = char(cl(i,:));
        if strcmp(str2double(cl{1,1}), 'NaN')
            s2.(keys{i}) = c;
        else
            % Assuming numbers
            s2.(keys{i}) = sscanf(c', '%f');
        end
    end
end