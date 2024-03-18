import XMonad

import XMonad.Util.EZConfig
import XMonad.Util.Ungrab

import System.Random

import Data.IORef
import Data.Char

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


myModMask :: KeyMask
myModMask = mod4Mask

main = xmonad $ def
  { modMask = myModMask
  , terminal = "kitty"
  , focusedBorderColor = "#ffffff"}

  `additionalKeys`
  [ ((myModMask, xK_b)  , spawn "brave")

  , ((shiftMask, xK_Alt_L), changeKeyboardLayout)
  , ((mod1Mask, xK_Shift_L), changeKeyboardLayout)

  , ((noModMask, xK_Print), do 
      str <- take 32 . filter isAlphaNum . randoms @Char <$> newStdGen
      unGrab <* spawn ("scrot -s /home/chell/Pictures/Screenshots/" ++ str ++ ".png"))

  , ((myModMask, xK_z), spawn "shutdown -h now")
  , ((myModMask, xK_x), spawn "reboot")

  , ((myModMask, xK_p), spawn "SHELL=bash dmenu_run")
  ]