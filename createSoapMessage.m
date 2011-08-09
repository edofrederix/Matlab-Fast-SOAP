%
% Matlab Fast SOAP - a faster Matlab replacement for the default SOAP
% functions
%   
% createSoapMessage, part of Matlab Fast SOAP
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

function m = createSoapMessage(tns, methodname, data, types, style)
    
    % No default behavior for first 5 arguments 
    if nargin < 4
        error('Provide at least 4 arguments')
    end
    
    % Check message style, default to rpc
    if nargin > 4 && ~ strcmpi(style, 'document') && ~ strcmpi(style, 'rpc')
        error('Provide a valid XML style (rpc or document is supported)');
    elseif nargin <= 4
        style = 'rpc';
    end
    
    % Start the envelope
    m = '<?xml version="1.0" encoding="utf-8"?>';
    m = sprintf('%s<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"', m);
    switch style
        case 'document'
            m = sprintf('%s>', m);
        case 'rpc'
            m = sprintf('%s xmlns:n="%s">', m, tns);
    end
    m = sprintf('%s<soap:Body soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">', m);
    switch style
        case 'document'
            m = sprintf('%s<%s xmlns="%s">', m, methodname, tns);
        case 'rpc'
            m = sprintf('%s<n:%s>', m, methodname);
    end
    
    % Add body
    m = sprintf('%s%s', m, createXML(data, types));
    
    % End the envelope
    switch style
        case 'document'
            m = sprintf('%s</%s>', m, methodname);
        case 'rpc'
            m = sprintf('%s</n:%s>', m, methodname);
    end
    m = sprintf('%s</soap:Body></soap:Envelope>', m);
end

%==========================================================================
function xml = createXML(values, types)

    xml = '';
    par = '';
    [wrap, parallel, keys] = checkKeys(values);
    for i = 1:numel(keys)
        
        key = keys{i};
        value = values.(key);
        type = types.(key);
        
        % Construct this element
        switch class(value)
            case 'struct'
                xml = [xml wrapXML(key, '', createXML(value, type))]; %#ok<*AGROW>
                
            case 'char'
                col = wrapXML(key, type, value);
                
            case 'double'
                col = wrapXML(key, type, num2str(value(:), '%1.10f'));
                
            case 'cell'
                for j=1:numel(value)
                    xml = [xml createXML(struct(key, value{j}), struct(key, type{j}))];
                end     
        end
        
        if ~isstruct(value)
            if ~parallel || (size(par,1) > 0 && size(col, 1) ~= size(par, 1))
                % Just prepend to document
                xml = [xml reshape(col', 1, numel(col))];
            else
                % Store parallel
                par = horzcat(par, col);
            end  
        end
    end
    
    % Wrap this layer, if specified
    if wrap
        if xml
            xml = sprintf('<%s>%s</%s>', wrap, xml, wrap);
        end
        if par
            par = wrapXML(wrap, '', par);
            xml = [xml reshape(par', 1, numel(par))];
        end
    elseif par
        xml = [xml reshape(par', 1, numel(par))];
    end    
end

%==========================================================================
function xml = wrapXML(tag, type, text)

    n = size(text,1);
    xml = horzcat( repmat(sprintf('<%s%s>', tag, checkType(type)), n, 1), ...
                   text, ...
                   repmat(sprintf('</%s>', tag), n, 1));

end

%==========================================================================
function [wrap, parallel, keysr] = checkKeys(values)

    keys = fieldnames(values);
    wrap = '';
    parallel = 0;
    
    for i = 1:numel(keys)
        key = keys{i};
        if strcmp(key, 'parallel')
            parallel = 1;
            values = rmfield(values, 'parallel');
        elseif strcmp(key, 'wrap')
            wrap = values.wrap;
            values = rmfield(values, 'wrap');
        else
            keysr{i} = key;
        end
    end             
    
end

%==========================================================================
function string = checkType(type)
    if ~isempty(strmatch('{http://www.w3.org/2001/XMLSchema}',type))
        string = sprintf(' xsi:type="xs:%s"', type(35:end));
    else
        string = '';
    end
end