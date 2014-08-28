/*
 * This file is part of quick-photo-editor.
 *
 * Copyright 2013 Canek Peláez Valdés
 *
 * quick-photo-editor is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * quick-photo-editor is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with quick-photo-editor.  If not, see
 * <http://www.gnu.org/licenses/>.
 */

namespace GQPE {

    public enum ExifImageOrientation {
        LANDSCAPE = 1,
        REVERSE_LANDSCAPE = 3,
        PORTRAIT = 6,
        REVERSE_PORTRAIT = 8
    }

    public enum Orientation {
        PORTRAIT,
        LANDSCAPE,
        REVERSE_PORTRAIT,
        REVERSE_LANDSCAPE,
    }

    public class Photograph : Image {

        public string filename { get; private set; }
        public string caption { get; private set; }

        private Gdk.Pixbuf pixbuf;
        private Orientation orientation;
        private GExiv2.Metadata metadata;

        public Photograph(filename) {
            metadata = new GExiv2.Metadata();
            metadata.open_path(filename);

            var original = new Gdk.Pixbuf.from_file(filename);
            int width = original.width;
            int height = original.height;
            double scale = 600.0 / double.max(width, height);
            pixbuf = original.scale_simple((int)(width*scale),
                                           (int)(height*scale),
                                           Gdk.InterpType.BILINEAR);
            if (metadata.has_tag("Exif.Image.Orientation")) {
                switch (metadata.get_tag_long("Exif.Image.Orientation")) {
                case ExifImageOrientation.LANDSCAPE:
                    orientation = Orientation.LANDSCAPE;
                    break;
                case ExifImageOrientation.REVERSE_LANDSCAPE:
                    pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.UPSIDEDOWN);
                    orientation = Orientation.REVERSE_LANDSCAPE;
                    break;
                case ExifImageOrientation.PORTRAIT:
                    pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.CLOCKWISE);
                    orientation = Orientation.PORTRAIT;
                    break;
                case ExifImageOrientation.REVERSE_PORTRAIT:
                    pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.COUNTERCLOCKWISE);
                    orientation = Orientation.REVERSE_PORTRAIT;
                    break;
                }
            }
            set_from_pixbuf(pixbuf);
            if (metadata.has_tag("Iptc.Application2.Caption"))
                caption = metadata.get_tag_string("Iptc.Application2.Caption");
            else
                caption = "";
        }

        private void rotate_left() {
            switch (orientation) {
            case Orientation.PORTRAIT:
                orientation = Orientation.LANDSCAPE;
                break;
            case Orientation.LANDSCAPE:
                orientation = Orientation.REVERSE_PORTRAIT;
                break;
            case Orientation.REVERSE_PORTRAIT:
                orientation = Orientation.REVERSE_LANDSCAPE;
                break;
            case Orientation.REVERSE_LANDSCAPE:
                orientation = Orientation.PORTRAIT;
                break;
            }
            pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.COUNTERCLOCKWISE);
            set_from_pixbuf(pixbuf);
        }

        private void rotate_right() {
            switch (orientation) {
            case Orientation.PORTRAIT:
                orientation = Orientation.REVERSE_LANDSCAPE;
                break;
            case Orientation.REVERSE_LANDSCAPE:
                orientation = Orientation.REVERSE_PORTRAIT;
                break;
            case Orientation.REVERSE_PORTRAIT:
                orientation = Orientation.LANDSCAPE;
                break;
            case Orientation.LANDSCAPE:
                orientation = Orientation.PORTRAIT;
                break;
            }
            pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.CLOCKWISE);
            set_from_pixbuf(pixbuf);
        }

        public void save_metadata() {
            metadata.set_tag_string("Iptc.Application2.Caption", caption);
            int otag = ExifImageOrientation.LANDSCAPE;
            switch (orientation) {
            case Orientation.PORTRAIT:
                otag = ExifImageOrientation.PORTRAIT;
                break;
            case Orientation.LANDSCAPE:
                otag = ExifImageOrientation.LANDSCAPE;
                break;
            case Orientation.REVERSE_PORTRAIT:
                otag = ExifImageOrientation.REVERSE_PORTRAIT;
                break;
            case Orientation.REVERSE_LANDSCAPE:
                otag = ExifImageOrientation.REVERSE_LANDSCAPE;
                break;
            }
            metadata.set_tag_long("Exif.Image.Orientation", otag);
            if (metadata.has_tag("Exif.Thumbnail.Orientation"))
                metadata.set_tag_long("Exif.Thumbnail.Orientation", otag);
            metadata.save_file(filename);
        }
    }
}
