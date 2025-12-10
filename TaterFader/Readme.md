Readme!!
-- grandMA3 Plugin: TaterFader
    -- Description: Fades Group Master to specified intensity over specified duration. The plugin will popup an error if a group has no executor assigned.
    -- If you do not want the error popup, change the variable labled errorPopupEnabled to 0. It will still print to console.
    -- Author: LXTater
    -- https://github.com/LXTater/MA3TaterPlugins/TaterFader
    -- Version: 1.6.5
    -- MA3 Version 2.3.2.0
    -- Thank you forums user stevegiovanazzi
    -- Utilizing his clock to determine values + this is basically a more feature rich version of his original code  https://forum.malighting.com/forum/thread/69307-group-master-command-line-fade/?postID=84711#post84711
	--


    --[[ How to Use:
        Import the plugin into your plugin data pool. Anywhere will work.
        Edit any settings that you wish.
        Make sure the group you wish to fade has an executor assigned to it.
            Assign Group X at Page y.z, etc
        Either in command line, with a macro, or as a cue command
        Call the function with the following parameters:
        TaterFader(Group Name or Number, Intensity, Duration)
            Example: TaterFader(1, 50, 5)  -- This will fade group 1 to 50% over 5 seconds.

            You can run multiple fades at once with this function. In testing, I have really only tried 5 or 6 groups at once.
            Technically unlimited amounts can run at a time, not sure how resource intensive that might be.

        
        
        
        --Extra Notes
        Still working on adding more features, but the core functionality is there.

        --Dimmer Curve notes:
        !!! Dimmer Curves are NOT WORKING! Everything is commented out, if you see something that I missed lmk lol. I suck at math. !!!!


        Dimmer Curves work mathmatically, however, having issues with calling multiples. For now, don't mess with dim curves
        For now, dimmer curves are a hidden setting. You can call dimmer curves with an additional parameter when calling the function.
        Example: TaterFader(1, 50, 5, "square")  -- This will fade group 1 to 50% over 5 seconds using a square dimmer curve.

    ]]

    --TaterFader Settings --
    -- Please only change these if needed/desired.
    -- Default settings listed here:
    --[[
    --DEFAULT: local errorPopupEnabled = 1             
   -- DEFAULT: local errorPopupTimeout = 8000


    ]]--

    local errorPopupEnabled = 1 -- 1 = Enable Error Popup 0 = Disable Error Popup.
    local errorPopupTimeout = 8000 -- Set timeout for error popup in milliseconds.
    local defaultDuration = 3 -- Default duration for fade in seconds if user does not specify.
    local defaultIntensity = 100 -- Default intensity for fade if user does not specify. 0-100%



    --ADVANCED SETTINGS--
    -- These settings are more advanced, and have not been tested on all version of MA3 software. I reccomend leaving these as default, unless you have time to mess around.

    --fadeSmoothness : Higher number = smoother fade, but more CPU usage. Lower number = choppier fade, but less CPU usage.
    local fadeSmoothness = 120
    --local defaultDimCurve = "linear" -- Set default dimmer curve (linear, square, invsquare,scurve)


    --DEFAULT: local fadeSmoothness = 120