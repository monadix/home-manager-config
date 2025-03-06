import XMonad
import XMonad.Hooks.EwmhDesktops
import XMonad.Util.EZConfig
import XMonad.Util.Parser
import XMonad.Util.SpawnOnce
import XMonad.Util.Ungrab

import System.Random

import Data.Char
import Data.IORef
import Data.Maybe
import Data.Ord
import Data.Time.Clock
import Data.Time.Format.ISO8601

import qualified GHC.IO as IO

keyboardLayouts :: [String]
keyboardLayouts = ["us", "ru"]

currentKeyboardLayout :: IORef Int
currentKeyboardLayout = IO.unsafePerformIO $ newIORef 0
{-# NOINLINE currentKeyboardLayout #-}

changeKeyboardLayout :: X ()
changeKeyboardLayout = do
  layout <- liftIO $ readIORef currentKeyboardLayout
  spawn $ "setxkbmap " ++ keyboardLayouts !! layout
  liftIO $ modifyIORef' currentKeyboardLayout ((`mod` length keyboardLayouts) . succ)


changeBrightness :: Float -> X ()
changeBrightness delta = do
  spawn $ "xbacklight -inc " ++ show delta 


myStartupHook :: X ()
myStartupHook = do 
  spawnOnce "feh --bg-fill --no-fehbg ~/.wallpapers/nixos-nord-dark.png"


myModMask :: KeyMask
myModMask = mod4Mask

main = xmonad . ewmh $ def
  { modMask = myModMask
  , terminal = "kitty"
  , normalBorderColor = "#4C566A"
  , focusedBorderColor = "#D8DEE9"
  , borderWidth = 1
  , startupHook = myStartupHook
  }

  `additionalKeys`
  let 

    mustParseKey = fromMaybe (error "cannot parse key") . runParser parseKey :: String -> KeySym

    brightnessUpKey   = mustParseKey "<XF86MonBrightnessUp>"
    brightnessDownKey = mustParseKey "<XF86MonBrightnessDown>"

  in 
  [ ((myModMask, xK_b), spawn "brave")

  , ((shiftMask, xK_Alt_L), changeKeyboardLayout)
  , ((mod1Mask, xK_Shift_L), changeKeyboardLayout)

  , ((noModMask, xK_Print), do 
      time <- liftIO getCurrentTime
      unGrab <* spawn ("flameshot gui"))

  , ((myModMask .|. shiftMask, xK_z), spawn "shutdown -h now")
  , ((myModMask .|. shiftMask, xK_x), spawn "reboot")

  , ((myModMask, xK_p), spawn "SHELL=bash dmenu_run")

  , ((noModMask, brightnessUpKey), changeBrightness 1)
  , ((noModMask, brightnessDownKey), changeBrightness (-1))

  , ((myModMask .|. shiftMask, xK_s), spawn "sleep 0.2 && xset dpms force off")
  , ((myModMask .|. shiftMask, xK_l), spawn "xautolock -locknow")
  ]
