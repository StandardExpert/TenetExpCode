function deltaRT = GetDeltaRT(allRTArray)
for ii = 1 : size(allRTArray,2)-1
    deltaRT(:,ii) = allRTArray(:,ii+1) - allRTArray(:,ii);
end
end