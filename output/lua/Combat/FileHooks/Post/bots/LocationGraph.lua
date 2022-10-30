-- Currently just the closest ResourcePoint having location (that is not a techpoint location)
function LocationGraph:InitializeTechpointNaturalRTLocations()
    PROFILE("LocationGraph:InitializeTechpointNaturalRTLocations")

    for i = 1, #self.techPointLocations do

        local techPointLocation = self.techPointLocations[i]

        local naturalLocationsSet = UnorderedSet()

        local locations = {}

        for i = 1, #self.resourcePointLocations do

            local rtLocation = self.resourcePointLocations[i]

            if rtLocation ~= techPointLocation --[[ not self.techPointLocations:Contains(rtLocation) ]] then

                local gatewayInfo = self:GetGatewayDistance(techPointLocation, rtLocation)

                -- Simple euclidean distance to handle locations that are adjacent to the techpoint
                local dist = gatewayInfo.distance
                   + self:GetExplorePointForLocationName(techPointLocation):GetDistance(gatewayInfo.enterGatePos)
                   + self:GetExplorePointForLocationName(rtLocation):GetDistance(gatewayInfo.exitGatePos)

                table.insert(locations, { rtLocation, dist })

            end

        end

        table.sort(locations, function(a, b) return a[2] < b[2] end)

        -- Closest two resource locations are considered naturals
        if locations[1] then
            naturalLocationsSet:Add(locations[1][1])
        end

        if locations[2] then
            naturalLocationsSet:Add(locations[2][1])
        end

        self.techPointLocationsNaturals[techPointLocation] = naturalLocationsSet

    end

end
