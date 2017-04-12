/* photograph.vala
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

    /**
     * Class for photographs.
     */
    public class Photograph : GLib.Object, Gee.Comparable<Photograph> {

        /**
         * The album of the photograph.
         */
        public string album { get; set; }

        /**
         * The caption (title) of the photograph.
         */
        public string caption { get; set; }

        /**
         * The comment of the photograph.
         */
        public string comment { get; set; }

        /**
         * The latitude coordinate.
         */
        public double latitude {
            get { return _latitude; }
            set { _latitude = value; has_geolocation = true; }
        }
        private double _latitude;

        /**
         * The longitude coordinate.
         */
        public double longitude {
            get { return _longitude; }
            set { _longitude = value; has_geolocation = true; }
        }
        private double _longitude;

        /**
         * The file for the photograph.
         */
        public GLib.File file { get; private set; }

        /**
         * The pixbuf for the photograph.
         */
        public Gdk.Pixbuf pixbuf { get; private set; }

        /**
         * Wether the photograph has geolocation.
         */
        public bool has_geolocation { get; private set; }

        /* The photograph orientation. */
        private Orientation orientation;
        /* The photograph metadata. */
        private GExiv2.Metadata metadata;
        /* Private the original pixbuf. */
        private Gdk.Pixbuf original;
        /* The scale of the pixbuf. */
        private double scale;

        /**
         * Creates a new photograph.
         * @param file the file with the photograph.
         */
        public Photograph(GLib.File file) {
            this.file = file;
        }

        /**
         * Loads the pixbuf of the photograph.
         * @param width the width.
         * @param height the height.
         * @throws GLib.Error if there is an error while loading.
         */
        public void load(double width, double height) throws GLib.Error {
            if (original != null) {
                resize(width, height);
                update_data();
                return;
            }

            original = new Gdk.Pixbuf.from_file(file.get_path());
            metadata = new GExiv2.Metadata();
            metadata.open_path(file.get_path());

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
                    original = original.rotate_simple(rot);
            }

            if (metadata.has_tag(Tag.LATITUDE)     &&
                metadata.has_tag(Tag.LONGITUDE)    &&
                metadata.has_tag(Tag.LATITUDE_REF) &&
                metadata.has_tag(Tag.LONGITUDE_REF)) {
                string lat = metadata.get_tag_string(Tag.LATITUDE);
                string lon = metadata.get_tag_string(Tag.LONGITUDE);
                latitude  = decimals_to_double(lat);
                longitude = decimals_to_double(lon);
                if (metadata.get_tag_string(Tag.LATITUDE_REF) == "S")
                    latitude *= -1.0;
                if (metadata.get_tag_string(Tag.LONGITUDE_REF) == "W")
                    longitude *= -1.0;
                has_geolocation = true;
            }

            resize(width, height);
            update_data();
        }

        /**
         * Resizes the photograph so it fills the given width and height.
         * @param width the width.
         * @param height the height.
         */
        public void resize(double width, double height) {
            double W = original.width;
            double H = original.height;
            double s1 = width / W;
            double s2 = height / H;
            scale = (H * s1 <= height) ? s1 : s2;
            pixbuf = original.scale_simple((int)(original.width*scale),
                                           (int)(original.height*scale),
                                           Gdk.InterpType.BILINEAR);
        }

        /**
         * Scales the photograph to a factor.
         * @param factor the factor to use for scaling.
         */
        public void scale_by_factor(double factor) {
            if ((factor == 1.0) ||
                (factor > 1.0 &&
                 (original.width  * scale > 2000.0 ||
                  original.height * scale > 2000.0)) ||
                (factor < 1.0 &&
                 (original.width  * scale < 200.0 ||
                  original.height * scale < 200.0)))
                return;
            scale *= factor;
            pixbuf = original.scale_simple((int)(original.width*scale),
                                           (int)(original.height*scale),
                                           Gdk.InterpType.BILINEAR);
        }

        /**
         * Rotates the photograph 90° to the left.
         */
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

        /**
         * Rotates the photograph 90° to the right.
         */
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

        /**
         * Saves the metadata of the photograph.
         * @throws GLib.Error if there is an error while loading.
         */
        public void save_metadata() throws GLib.Error {
            update_text_tags();
            update_geolocation_tags();
            metadata.save_file(file.get_path());
        }

        /* Updates the data from the metadata. */
        private void update_data() {
            album = (metadata.has_tag(Tag.SUBJECT)) ?
                metadata.get_tag_string(Tag.SUBJECT).strip() : "";
            caption = (metadata.has_tag(Tag.CAPTION)) ?
                metadata.get_tag_string(Tag.CAPTION).strip() : "";
            comment = (metadata.has_tag(Tag.DESCRIPTION)) ?
                metadata.get_tag_string(Tag.DESCRIPTION).strip() : "";
        }

        /* Updates the text tags. */
        private void update_text_tags() throws GLib.Error {
            metadata.clear_tag(Tag.SUBJECT);
            metadata.set_tag_string(Tag.SUBJECT, album);
            metadata.clear_tag(Tag.CAPTION);
            metadata.set_tag_string(Tag.CAPTION, caption);
            metadata.clear_tag(Tag.DESCRIPTION);
            metadata.set_tag_string(Tag.DESCRIPTION, comment);
            metadata.set_tag_long(Tag.ORIENTATION, orientation);
            metadata.save_file(file.get_path());
            if (metadata.has_tag(Tag.THUMB_ORIENTATION))
                metadata.set_tag_long(Tag.THUMB_ORIENTATION, orientation);
        }

        /* Updates the geolocation tags. */
        private void update_geolocation_tags() {
            if (!has_geolocation)
                return;
            var lat = (latitude  < 0.0) ? latitude  * -1.0 : latitude;
            var lon = (longitude < 0.0) ? longitude * -1.0 : longitude;
            var lat_ref = (latitude  < 0.0) ? "S" : "N";
            var lon_ref = (longitude < 0.0) ? "W" : "E";
            var slat = double_to_decimals(lat);
            var slon = double_to_decimals(lon);
            metadata.set_tag_string(Tag.LATITUDE, slat);
            metadata.set_tag_string(Tag.LONGITUDE, slon);
            metadata.set_tag_string(Tag.LATITUDE_REF, lat_ref);
            metadata.set_tag_string(Tag.LONGITUDE_REF, lon_ref);
        }

        /**
         * Compares the photograph with the one received.
         * @param photograph the photograph to compare to.
         * @return an integer less than zero if the photograph is less than the
         *         one received; zero if they are both the same; and an integer
         *         greater than zero otherwise.
         */
        public int compare_to(Photograph photograph) {
            if (file.get_path() < photograph.file.get_path())
                return -1;
            if (file.get_path() > photograph.file.get_path())
                return 1;
            return 0;
        }

        /* Converts a double to GPS decimals. */
        private string double_to_decimals(double d) {
            double i = Math.floor(d);
            double r = (d - i)*30000.0;
            double m = Math.floor(r);
            /* m*12 == (m/30000)*360000 */
            double s = (d - i)*360000.0 - (m*12.0);
            string decs = "%d/1 %d/500 %d/100".printf((int)i, (int)m, (int)s);
            return decs;
        }

        /* Converts a GPS decimal to a double. */
        private double decimal_to_double(string decimal) {
            assert(decimal.index_of("/") != -1);
            string[] s = decimal.split("/");
            double num = double.parse(s[0]);
            double den = double.parse(s[1]);
            return num / den;
        }

        /* Converts GPS decimals to a double. */
        private double decimals_to_double(string decimals) {
            string[] s = decimals.split(" ");
            double[] d = { 0.0, 0.0, 0.0 };
            for (int i = 0; i < s.length; i++)
                d[i] = decimal_to_double(s[i]);
            return d[0] + d[1] / 60.0 + d[2] / 3600.0;
        }
    }
}
