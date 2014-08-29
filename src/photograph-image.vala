/*
 * This file is part of gqpe.
 *
 * Copyright 2013 Canek Peláez Valdés
 *
 * gqpe is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * gqpe is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with gqpq.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace GQPE {

    public class PhotoImage : Gtk.Image {

        public string filename { get; private set; }
        public string caption { get; private set; }
        public Orientation orientation { get; private set; }

        private GExiv2.Metadata metadata;

        public PhotoImage(string filename) throws GLib.Error {
            update_filename(filename);
        }

        public void update_filename(string filename) throws GLib.Error {
            if (this.filename == filename)
                return;

            this.filename = filename;
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
                case Orientation.LANDSCAPE:
                    orientation = Orientation.LANDSCAPE;
                    break;
                case Orientation.REVERSE_LANDSCAPE:
                    pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.UPSIDEDOWN);
                    orientation = Orientation.REVERSE_LANDSCAPE;
                    break;
                case Orientation.PORTRAIT:
                    pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.CLOCKWISE);
                    orientation = Orientation.PORTRAIT;
                    break;
                case Orientation.REVERSE_PORTRAIT:
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

        public void rotate_left() {
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

        public void rotate_right() {
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

        public void save_metadata() throws GLib.Error {
            metadata.set_tag_string("Iptc.Application2.Caption", caption);
            metadata.set_tag_long("Exif.Image.Orientation", orientation);
            if (metadata.has_tag("Exif.Thumbnail.Orientation"))
                metadata.set_tag_long("Exif.Thumbnail.Orientation", orientation);
            metadata.save_file(filename);
        }
    }
}
