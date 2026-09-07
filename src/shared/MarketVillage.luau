--!strict

-- Stable names are the contract between the guarded local builder and the
-- optional runtime presentation services. Positions remain builder-owned so
-- the world can be re-authored without changing gameplay code.
local MarketVillage = {
	RootName = "PipilabuMarketVillagePrototype",
	Build = "LAYOUT-0.2.0",
	PresentationEnabledAttribute = "PresentationEnabled",
	GroundingFolderName = "Grounding",
	FixturesFolderName = "AuthoredFixtures",
	ShopPlotsFolderName = "FutureShopPlots",
	NeighborLanesFolderName = "NeighborLanes",
	StewardshipDisplayName = "StewardshipDisplay",
	CareMarkersName = "CareMarkers",
	CareMarkerPrefix = "CareMark_",
	CareMarkerCount = 3,
	PeepilabuAnchorName = "PeepilabuQuestAnchor",
	ExtensionSeamsName = "ExtensionSeams",
	PlotNames = table.freeze({
		"Plot_West_01",
		"Plot_East_01",
		"Plot_West_02",
		"Plot_East_02",
	}),
}

return table.freeze(MarketVillage)
