function matrixData = CollectCellData2Mat(cellData)
matrixData = zeros(size(cellData,1),length(cellData{1}));
for ii = 1:size(cellData,1)
    matrixData(ii,:) = cellData{ii};
end
end