classdef CatalogEventData < event.EventData
% CatalogEventData - Event data for Catalog mutation events
%
%   Carries information about which item was added, removed, or modified.

    properties
        ItemName (1,1) string
        ItemIndex (1,1) double
        ItemData
    end

    methods
        function obj = CatalogEventData(itemName, itemIndex, itemData)
            arguments
                itemName (1,1) string
                itemIndex (1,1) double
                itemData = []
            end
            obj.ItemName = itemName;
            obj.ItemIndex = itemIndex;
            obj.ItemData = itemData;
        end
    end
end
