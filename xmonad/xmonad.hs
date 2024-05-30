import XMonad

import XMonad.Util.EZConfig
import XMonad.Util.Parser
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


currentScreenBrightness :: IORef Float
currentScreenBrightness = IO.unsafePerformIO $ newIORef 1
{-# NOINLINE currentScreenBrightness #-}

changeBrightness :: Float -> X ()
changeBrightness delta = do
  brightness <- liftIO $ readIORef currentScreenBrightness
  liftIO $ modifyIORef' currentScreenBrightness (clamp (0.1, 10) . (+delta))
  spawn $ "xgamma -gamma " ++ show (clamp (0.1, 10) $ brightness + delta)


myModMask :: KeyMask
myModMask = mod4Mask

main = xmonad $ def
  { modMask = myModMask
  , terminal = "kitty"
  , focusedBorderColor = "#ffffff"}

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
      unGrab <* spawn ("scrot -fs ~/Pictures/Screenshots/" ++ iso8601Show time ++ ".png"))

  , ((myModMask .|. shiftMask, xK_z), spawn "shutdown -h now")
  , ((myModMask .|. shiftMask, xK_x), spawn "reboot")

  , ((myModMask, xK_p), spawn "SHELL=bash dmenu_run")

  , ((noModMask, brightnessUpKey), changeBrightness 0.1)
  , ((noModMask, brightnessDownKey), changeBrightness (-0.1))

  , ((myModMask .|. shiftMask, xK_s), spawn "sleep 0.5 && xset dpms force off")
  ]
