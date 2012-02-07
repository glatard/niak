function ssurf = niak_read_surf(file_name)
% Read a surface in the MNI .obj or Freesurfer format
%
% SYNTAX:
% SSURF = NIAK_READ_SURF_OBJ(FILE_NAME)
%
% _________________________________________________________________________
% INPUTS :
%
% FILE_NAME
%    (string or cell of strings) string: a single surface file. cell of 
%    strings : all the surfaces are concatenated.
%
% _________________________________________________________________________
% OUTPUTS :
%
% SSURF
%    (structure, with the following fields) 
%
%    COORD
%        (array 3 x v) node coordinates. v=#vertices.
%
%    NORMAL
%        (array, 3 x v) list of normal vectors, only .obj files.
%
%    TRI
%        (vector, t x 3) list of triangle elements. t=#triangles.
%
%    COLR
%        (vector or matrix) 4 x 1 vector of colours for the whole surface,
%        or 4 x v matrix of colours for each vertex, either uint8 in [0 255], 
%        or float in [0 1], only .obj files.
%
% _________________________________________________________________________
% COMMENTS:
%
% .obj file is the montreal neurological institute (MNI) specific ASCII or
% binary triangular mesh data structure. For FreeSurfer software, a slightly 
% different data input coding is used.
%
% (C) Keith Worsley, McGill University, 2008
% Slightly modified by Pierre Bellec, 
% Centre de recherche de l'institut de Gériatrie de Montréal,
% Département d'informatique et de recherche opérationnelle,
% Université de Montréal, 2012.
% Maintainer : pierre.bellec@criugm.qc.ca
% See licensing information in the code.
% Keywords : surface, reader

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%% Multiple surfaces
if iscellstr(file_name)
    k = length(file_name);
    ssurf.tri=[];
    ssurf.coord = [];
    ssurf.colr = [];
    ssurf.normal = [];
    for j=1:k
        s = niak_read_surf(file_name{j});
        ssurf.tri=[ssurf.tri; int32(s.tri)+size(ssurf.coord,2)];
        ssurf.coord = [ssurf.coord s.coord];
        if isfield(s,'colr') 
            if size(s.colr,2)==1
                ssurf.colr = s.colr;
            else
                ssurf.colr = [ssurf.colr s.colr];
            end
        end
        if isfield(s,'normal')
            ssurf.normal = [ssurf.normal s.normal];
        end
    end
    if isempty(ssurf.colr)
        ssurf = rmfield(ssurf,'colr');
    end
    if isempty(ssurf,'normal')
        ssurf = rmfield(ssurf,'normal');
    end
    return
end

%% Single surface
ab='a';
numfields = 4;
[pathstr,name,ext] = fileparts(file_name);
if strcmp(ext,'.obj')
    % It's a .obj file
    if ab(1)=='a'
        fid=fopen(file_name);
        FirstChar=fscanf(fid,'%1s',1);
        if FirstChar=='P' % ASCII
            fscanf(fid,'%f',5);
            v=fscanf(fid,'%f',1);
            ssurf.coord=fscanf(fid,'%f',[3,v]);
            if numfields>=2
                ssurf.normal=fscanf(fid,'%f',[3,v]);
                if numfields>=3
                    ntri=fscanf(fid,'%f',1);
                    ind=fscanf(fid,'%f',1);
                    if ind==0
                        ssurf.colr=fscanf(fid,'%f',4);
                    else
                        ssurf.colr=fscanf(fid,'%f',[4,v]);
                    end
                    if numfields>=4
                        fscanf(fid,'%f',ntri);
                        ssurf.tri=fscanf(fid,'%f',[3,ntri])'+1;
                    end
                end
            end
            fclose(fid);
        else
            fclose(fid);
            fid=fopen(file_name,'r','b');
            FirstChar=fread(fid,1);
            if FirstChar==uint8(112) % binary
                fread(fid,5,'float');
                v=fread(fid,1,'int');
                ssurf.coord=fread(fid,[3,v],'float');
                if numfields>=2
                    ssurf.normal=fread(fid,[3,v],'float');
                    if numfields>=3
                        ntri=fread(fid,1,'int');
                        ind=fread(fid,1,'int');
                        if ind==0
                            ssurf.colr=uint8(fread(fid,4,'uint8'));
                        else
                            ssurf.colr=uint8(fread(fid,[4,v],'uint8'));
                        end
                        if numfields>=4
                            fread(fid,ntri,'int');
                            ssurf.tri=fread(fid,[3,ntri],'int')'+1;
                        end
                    end
                end
                fclose(fid);
                ab='b';
            else
                fprintf(1,'%s\n',['Unable to read ' file_name ', first character ' char(FirstChar)]);
            end
        end
    else
        fid=fopen(file_name,'r','b');
        FirstChar=fread(fid,1);
        if FirstChar==uint8(112) % binary
            fread(fid,5,'float');
            v=fread(fid,1,'int');
            ssurf.coord=fread(fid,[3,v],'float');
            if numfields>=2
                ssurf.normal=fread(fid,[3,v],'float');
                if numfields>=3
                    ntri=fread(fid,1,'int');
                    ind=fread(fid,1,'int');
                    if ind==0
                        ssurf.colr=uint8(fread(fid,4,'uint8'));
                    else
                        ssurf.colr=uint8(fread(fid,[4,v],'uint8'));
                    end
                    if numfields>=4
                        fread(fid,ntri,'int');
                        ssurf.tri=fread(fid,[3,ntri],'int')'+1;
                    end
                end
            end
            fclose(fid);
        else
            fclose(fid);
            fid=fopen(file_name);
            FirstChar=fscanf(fid,'%1s',1);
            if FirstChar=='P' %ASCII
                fscanf(fid,'%f',5);
                v=fscanf(fid,'%f',1);
                ssurf.coord=fscanf(fid,'%f',[3,v]);
                if numfields>=2
                    ssurf.normal=fscanf(fid,'%f',[3,v]);
                    if numfields>=3
                        ntri=fscanf(fid,'%f',1);
                        ind=fscanf(fid,'%f',1);
                        if ind==0
                            ssurf.colr=fscanf(fid,'%f',4);
                        else
                            ssurf.colr=fscanf(fid,'%f',[4,v]);
                        end
                        if numfields>=4
                            fscanf(fid,'%f',ntri);
                            ssurf.tri=fscanf(fid,'%f',[3,ntri])'+1;
                        end
                    end
                end
                fclose(fid);
                ab='a';
            else
                fprintf(1,'%s\n',['Unable to read ' file_name ', first character ' char(FirstChar)]);
            end
        end
    end
else
    % Assume it's a FreeSurfer file
    fid = fopen(file_name, 'rb', 'b') ;
    b1 = fread(fid, 1, 'uchar') ;
    b2 = fread(fid, 1, 'uchar') ;
    b3 = fread(fid, 1, 'uchar') ;
    magic = bitshift(b1, 16) + bitshift(b2,8) + b3 ;
    if magic==16777214
        fgets(fid);
        fgets(fid);
        v = fread(fid, 1, 'int32') ;
        t = fread(fid, 1, 'int32') ;
        ssurf.coord = fread(fid, [3 v], 'float32') ;
        if numfields==4
            ssurf.tri = fread(fid, [3 t], 'int32')' + 1 ;
        end
        fclose(fid) ;
    else
        fprintf(1,'%s\n',['Unable to read ' file_name ', magic = ' num2str(magic)]);
    end
    ab='b';
end

return
end