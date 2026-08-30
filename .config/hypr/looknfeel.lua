-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- A small rounding so windows and shell popups aren't sharp-cornered (the
-- shell's own corner radius follows this same value).
hl.config({
  decoration = {
    rounding = 8,
  },
})

-- Slight transparency on unfocused windows to help the focused one stand out.
--
-- Deliberately a window rule on Omarchy's `default-opacity` tag rather than
-- `decoration.inactive_opacity`. A global setting can't be opted out of:
-- window-rule opacity is a *multiplier* unless every value is suffixed
-- `override`, and Omarchy's own exemptions (browsers, mpv, vlc, OBS, Steam,
-- qemu, picture-in-picture, image viewers) are all plain `opacity = "1 1"`
-- multipliers. A global 0.9 reached every one of them.
o.window({ tag = "default-opacity" }, { opacity = "1.0 0.9" })

-- Browsers need saying explicitly: Omarchy drops them from the tag above and
-- lands them on `opacity = "1.0 0.985"`, too subtle to read as a fade at all.
-- Keying off its tags rather than a class list leaves that list upstream's to
-- maintain -- and any browser Omarchy doesn't know keeps `default-opacity` and
-- fades through the rule above anyway.
o.window({ tag = "chromium-based-browser" }, { opacity = "1.0 override 0.9 override" })
o.window({ tag = "firefox-based-browser" }, { opacity = "1.0 override 0.9 override" })

-- ...except while something is playing video. Deliberately matches any window
-- rather than just browsers: the wake lock below is the whole signal, so this
-- needs no list of browsers and covers ones that don't exist yet. Last match
-- wins, so it has to stay below the two rules above.
o.window({ tag = "video-playing" }, { opacity = "1.0 override 1.0 override" })

-- Chromium holds a wake lock while playing video, and not for audio alone --
-- the same thing that stops the screen locking mid-film. Hyprland reports it
-- as `inhibiting_idle`, but there's no window-rule match for it and no event
-- to hook, so poll and translate it into a tag the rule above can match.
local VIDEO_TAG = "video-playing"

local function has_tag(window, name)
  for _, tag in ipairs(window.tags or {}) do
    -- Dynamic tags come back suffixed with `*`.
    if tag == name or tag == name .. "*" then
      return true
    end
  end

  return false
end

-- `hyprctl reload` re-runs this file in the same Lua state, so without this the
-- timers would stack up one per reload.
if _G.__osiris_video_watcher then
  _G.__osiris_video_watcher:set_enabled(false)
end

_G.__osiris_video_watcher = hl.timer(function()
  for _, window in ipairs(hl.get_windows()) do
    local playing = window.inhibiting_idle
    if playing ~= has_tag(window, VIDEO_TAG) then
      hl.dispatch(hl.dsp.window.tag({
        tag = (playing and "+" or "-") .. VIDEO_TAG,
        window = "address:" .. window.address,
      }))
    end
  end
end, { timeout = 1000, type = "repeat" })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })
