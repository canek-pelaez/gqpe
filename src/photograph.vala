/* photograph.vala
 * 
 * This file is part of gqpe.
 *
 * This file is part of gqpe.
 *
 * Copyright © 2013-2017 Canek Peláez Valdés
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */
namespace GQPE {

    public enum Orientation {
        LANDSCAPE         = 1,
        REVERSE_LANDSCAPE = 3,
        PORTRAIT          = 6,
        REVERSE_PORTRAIT  = 8
    }

    public class Photograph : GLib.Object, Gee.Comparable<Photograph> {

        private class Tag {
            public static const string ORIENTATION =
                "Exif.Image.Orientation";
            public static const string TH_ORIENTATION =
                "Exif.Thumbnail.Orientation";
            public static const string SUBJECT =
                "Xmp.dc.subject";
            public static const string CAPTION =
                "Iptc.Application2.Caption";
            public static const string DESCRIPTION =
                "Exif.Image.ImageDescription";
        }

        public string album { get; set; }
        public string caption { get; set; }
        public string comment { get; set; }

        public GLib.File file { get; private set; }
        public Gdk.Pixbuf pixbuf { get; private set; }

        private Orientation orientation;
        private GExiv2.Metadata metadata;

        public Photograph(GLib.File file) {
            this.file = file;
        }

        public void load() throws GLib.Error {
            if (pixbuf != null)
                return;

            metadata = new GExiv2.Metadata();
            metadata.open_path(file.get_path());

            pixbuf = new Gdk.Pixbuf.from_file(file.get_path());
            if (metadata.has_tag(Tag.ORIENTATION)) {
                var rot = Gdk.PixbufRotation.NONE;
                switch (metadata.get_tag_long(Tag.ORIENTATION)) {
                case Orientation.LANDSCAPE:
                    orientation = Orientation.LANDSCAPE;
                    break;
                case Orientation.REVERSE_LANDSCAPE:
                    orientation = Orientation.REVERSE_LANDSCAPE;
                    rot = Gdk.PixbufRotation.UPSIDEDOWN;
                    break;
                case Orientation.PORTRAIT:
                    orientation = Orientation.PORTRAIT;
                    rot = Gdk.PixbufRotation.CLOCKWISE;
                    break;
                case Orientation.REVERSE_PORTRAIT:
                    orientation = Orientation.REVERSE_PORTRAIT;
                    rot = Gdk.PixbufRotation.COUNTERCLOCKWISE;
                    break;
                }
                if (rot != Gdk.PixbufRotation.NONE)
                    pixbuf = pixbuf.rotate_simple(rot);
            }
            double scale = 500.0 / double.max(pixbuf.width, pixbuf.height);
            pixbuf = pixbuf.scale_simple((int)(pixbuf.width*scale),
                                         (int)(pixbuf.height*scale),
                                         Gdk.InterpType.BILINEAR);
            album = (metadata.has_tag(Tag.SUBJECT)) ?
                metadata.get_tag_string(Tag.SUBJECT).strip() : "";
            caption = (metadata.has_tag(Tag.CAPTION)) ?
                metadata.get_tag_string(Tag.CAPTION).strip() : "";
            comment = (metadata.has_tag(Tag.DESCRIPTION)) ?
                metadata.get_tag_string(Tag.DESCRIPTION).strip() : "";

            album.strip();
            caption.strip();
            comment.strip();
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
        }

        public void save_metadata() throws GLib.Error {
            if (album == "")
                metadata.clear_tag(Tag.SUBJECT);
            else
                metadata.set_tag_string(Tag.SUBJECT, album);
            if (caption == "")
                metadata.clear_tag(Tag.CAPTION);
            else
                metadata.set_tag_string(Tag.CAPTION, caption);
            if (comment != "")
                metadata.clear_tag(Tag.DESCRIPTION);
            else
                metadata.set_tag_string(Tag.DESCRIPTION, comment);
            metadata.set_tag_long(Tag.ORIENTATION, orientation);
            metadata.save_file(file.get_path());
            if (metadata.has_tag(Tag.TH_ORIENTATION))
                metadata.set_tag_long(Tag.TH_ORIENTATION, orientation);
            metadata.save_file(file.get_path());
        }

        public int compare_to(Photograph photograph) {
            if (file.get_path() < photograph.file.get_path())
                return -1;
            if (file.get_path() > photograph.file.get_path())
                return 1;
            return 0;
        }
    }
}
