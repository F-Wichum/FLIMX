function [roiFlat, binLevels, roiFull] = getAdaptiveBinROI(raw,roiX,roiY,targetPhotons,maxBinFactor,optimize4Codegen)
%=============================================================================================================
%
% @file     getAdaptiveBinROI.m
% @author   Matthias Klemm <Matthias_Klemm@gmx.net>
% @version  1.0
% @date     July, 2015
%
% @section  LICENSE
%
% Copyright (C) 2015, Matthias Klemm. All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification, are permitted provided that
% the following conditions are met:
%     * Redistributions of source code must retain the above copyright notice, this list of conditions and the
%       following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
%       the following disclaimer in the documentation and/or other materials provided with the distribution.
%     * Neither the name of FLIMX authors nor the names of its contributors may be used
%       to endorse or promote products derived from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
% WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
% INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
% HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
%
%
% @brief    A function to implement adataptive binning for a certain ROI
%
flat = int32(sum(raw,3));
[yR,xR,zR] = size(raw);
raw = reshape(raw,[yR*xR,zR]);
%rawClass = class(raw);
[dataYSz,dataXSz] = size(flat);
dataYSz = int32(dataYSz);
dataXSz = int32(dataXSz);
roiX = int32(roiX);
roiY = int32(roiY);
roiXLen = length(roiX);
roiYLen = length(roiY);
roiFlat = zeros(roiYLen,roiXLen,'int32');
binLevels = zeros(roiYLen,roiXLen,'int32');
if(nargout == 3)
    roiFull = zeros(roiYLen,roiXLen,zR,'uint32');
    roiFull = reshape(roiFull,roiYLen*roiXLen,1,zR);
end
nPixel = roiYLen*roiXLen;
%calculate coordinates of output grid
[pxYcoord, pxXcoord] = ind2sub([roiYLen,roiXLen],1:nPixel);
[binXcoord, binYcoord, binRho, binRhoU] = makeBinMask(maxBinFactor);
parfor px = 1:nPixel
    %coarse search
    maxBinLevelReached = false;
    binFactor = 0;
    binLevel = int32(0);
    val = int32(0);
    idx = int32(0);
    while(~maxBinLevelReached && val < targetPhotons && binFactor < maxBinFactor)
        binFactor = binFactor+1;
        binLevel = int32(find(binFactor == binRhoU,1,'first'));
        if(~isempty(binLevel))
            [idx,maxBinLevelReached] = getAdaptiveBinningIndex(roiY(pxYcoord(px)),roiX(pxXcoord(px)),binLevel(1),dataYSz,dataXSz,binXcoord, binYcoord, binRho, binRhoU);
            val = sum(flat(idx),'native');
        end
    end
    if(binFactor > 0)
        binLevel = int32(find(binFactor-1 == binRhoU,1,'first'));
        if(isempty(binLevel))
            binLevel = int32(0);
        end
        binLevel = binLevel(1);
    end
    val = int32(0);
    while(~maxBinLevelReached && val < targetPhotons)
        binLevel = binLevel+1;
        [idx,maxBinLevelReached] = getAdaptiveBinningIndex(roiY(pxYcoord(px)),roiX(pxXcoord(px)),binLevel,dataYSz,dataXSz,binXcoord, binYcoord, binRho, binRhoU);
        val = sum(flat(idx),'native');
    end  
    roiFlat(px) = val;%pxYcoord(px),pxXcoord(px)
    binLevels(px) = binLevel(1);
%     if(optimize4Codegen)
%         %% use this for codegen!
%         [iY,iX] = ind2sub([yR,xR],idx);
%         tmp = zeros(length(idx),zR,rawClass);
%         for i = 1:length(idx)
%             tmp(i,:) = raw(iY(i),iX(i),:);
%         end
%         %roiFull(pxYcoord(px),pxXcoord(px),:) = sum(tmp,1,'native');
%         roiFull(px,1,:) = sum(tmp,1,'native');
%     else
        %% use this for matlab execution!
        %roiFull(px,1,:) = sum(raw(bsxfun(@plus, idx, int32(yR) * int32(xR) * ((1:int32(zR))-1))),1,'native'); %slow
        roiFull(px,1,:) = sum(raw(idx, :),1,'native');
%     end
end
roiFull = reshape(roiFull,roiYLen,roiXLen,zR);
end
