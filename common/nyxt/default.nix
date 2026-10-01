{ ... }:
{
  programs.nyxt = {
    enable = true;
    config = ''
      (in-package #:nyxt-user)

      (define-configuration browser
        ((theme (make-instance 'theme:theme
                              :background-color "#2e3440"
                              :primary-color "#3b4252"
                              :secondary-color "#434c5e"
                              :action-color "#88c0d0"
                              :highlight-color "#ebcb8b"
                              :success-color "#a3be8c"
                              :warning-color "#bf616a"
                              :codeblock-color "#3b4252"
                              :text-color "#eceff4"
                              :contrast-text-color "#2e3440"))))
    '';
  };
}
