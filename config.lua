Config = {}

-- General Settings
Config.Command = 'echo' -- Command to open UI
Config.MaxDistance = 50.0 -- Maximum echo distance
Config.MinDistance = 5.0 -- Minimum echo distance
Config.MaxEchoStrength = 100 -- Maximum echo strength (0-100)
Config.MinEchoStrength = 0 -- Minimum echo strength (0-100)

-- Default Values
Config.DefaultDistance = 20.0
Config.DefaultEchoStrength = 50
Config.DefaultDelay = 500 -- Echo delay in milliseconds
Config.DefaultDecay = 0.5 -- Echo decay factor

-- UI Settings
Config.UIKey = 'F7' -- Key to toggle UI (optional)
Config.EnableSelfEcho = true -- Allow players to hear their own echo
Config.EchoFadeTime = 1000 -- Time for echo to fade in milliseconds
Config.VoiceChannels = {0, 1, 2} -- Available voice channels for echo

-- Permission Settings (set to false to disable)
Config.UsePermissions = false
Config.AllowedJobs = {'police', 'ambulance', 'mechanic'}
Config.AllowedRanks = {'boss', 'admin'}

-- Audio Settings
Config.EchoTypes = {
    {name = 'Hall', value = 'hall'},
    {name = 'Cave', value = 'cave'},
    {name = 'Stadium', value = 'stadium'},
    {name = 'Custom', value = 'custom'}
}