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

-- Browsers drop the tag above upstream, but land on `opacity = "1.0 0.985"` --
-- still a multiplier, so still short of opaque and still at the mercy of any
-- global setting. Pin them absolutely instead. Matching Omarchy's own tags
-- leaves the browser class list upstream's to maintain rather than ours.
o.window({ tag = "chromium-based-browser" }, { opacity = "1.0 override 1.0 override" })
o.window({ tag = "firefox-based-browser" }, { opacity = "1.0 override 1.0 override" })

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
