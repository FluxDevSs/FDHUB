local PlaceId = {
    [286090429] = "https://raw.githubusercontent.com/FluxDevSs/FDHUB/refs/heads/main/arsenal.lua",
    [8363462734] = "https://raw.githubusercontent.com/FluxDevSs/FDHUB/refs/heads/main/arsenal.lua"
}

local url = PlaceId[game.PlaceId]
if url then
    loadstring(game:HttpGet(url))()
else
    game.Players.LocalPlayer:Kick("FDHub Dosent Support This Game")
end
