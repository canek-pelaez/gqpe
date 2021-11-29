Gtk+ Quick Photo Editor
=======================

Gtk+ Quick Photo Editor (GQPE for short) is a small image tag editor.

GQPE only cares for the following tags:

* `Xmp.dc.subject`
* `Iptc.Application2.Caption`
* `Exif.Image.ImageDescription`
* `Exif.GPSInfo.GPSLatitude`
* `Exif.GPSInfo.GPSLongitude`
* `Exif.GPSInfo.GPSLatitudeRef`
* `Exif.GPSInfo.GPSLongitudeRef`
* `Exif.Image.Orientation`

This program is intended to set those tags as fast as possible. The program
shows the picture and a map for its geolocation, and allows the user to rotate
it and to enter the `Xmp.dc.subject`, `Iptc.Application2.Caption`, and
`Exif.Image.ImageDescription` tags. It also allows to click on the map to set
the geolocation coordinates of the picture.

While it can be used with the mouse, that's not the way is intended
to be used: All the available manipulations are possible using only
the keyboard:

* `Ctrl`+`[` and `Ctrl`+`]` will rotate the picture to the left and right,
  respectively.

* Enter in any text entry (if not empty) or `Ctrl-Enter` will update the
  relevant tags in the picture and move to the next one. You need to do this (or
  click on the save button) to update the tags in the picture, otherwise all the
  changes are ignored.

* `PageUp` and `PageDown` will move to the next or the previous picture,
  respectively, without updating the current one.

* `Esc` will terminate the program.

The idea is to select a bunch of pictures in Nautilus, open them with this
program, and quickly update their information.

With the `Xmp.dc.subject` and `Iptc.Application2.Caption` correctly set, you can
import them in [Shotwell](https://wiki.gnome.org/Apps/Shotwell), which also uses
the `Iptc.Application2.Caption` as title, and `Xmp.dc.subject` as tag (inside
Shotwell).

Besides the main GUI application, GQPE comes with a few command line utilities:

* `gqpe-tags` shows and edit the image tags via the command line, including
  options to shift the image time; set the image file date and time to the one
  in the image tags; print the tags with a format; or only print the image files
  without GPS data.
* `gqpe-copy` copies the tags from one image file to another, including options
  to ignore GPS data or date and time, or to only copy GPS data.
* `gqpe-store` stores the image files to a normalized location.
* `gqpe-interpolate-gps` interpolates the GPS coordinates in a set of image
  files.

All the command line utilities have man pages.

Requirements
------------

You need the following to compile GQPE:

* `champlain-0.12`
* `clutter-gtk-1.0`
* `gexiv2`
* `gtk+-3.18`
* `gee-0.8`

The program is written in [Vala](https://wiki.gnome.org/Projects/Vala), but you
only need Vala if you don't use tarballs.

Homepage
--------

[https://aztlan.fciencias.unam.mx/gitlab/canek/gqpe](https://aztlan.fciencias.unam.mx/gitlab/canek/gqpe)
