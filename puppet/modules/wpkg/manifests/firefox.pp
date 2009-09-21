# From http://www.mozilla.com/en-US/firefox/all.html

# Class name must match a package id in an XML in files/packages

class wpkg::firefox3 {

  file {
    "$wpkg_base/software/firefox":
      ensure => directory;
  }

  download {
    "firefox":
      url => "http://download.mozilla.org/?product=firefox-3.5.3&os=win&lang=ca",
      creates => "Firefox Setup 3.5.3.exe";
  }

}
