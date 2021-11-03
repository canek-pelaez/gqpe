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

        /* The default GPS tag. */
        private const long DEFAULT_GPS_TAG = 9208;
        /* The default GPS string. */
        private const string DEFAULT_GPS_VERSION = "2 0 0 0";
        /* The default GPS datum. */
        private const string DEFAULT_GPS_DATUM = "WGS-84";

        /**
         * The date and time of the photograph.
         */
        public GLib.DateTime date_time { get; set; }

        /**
         * The photograph orientation.
         */
        private Orientation orientation;

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
         * The GPS tag.
         */
        public string gps_tag { get; set; }

        /**
         * The GPS version.
         */
        public string gps_version { get; set; }

        /**
         * The GPS datum.
         */
        public string gps_datum { get; set; }

        /**
         * The file for the photograph.
         */
        public GLib.File file { get; private set; }

        /**
         * Wether the photograph has geolocation.
         */
        public bool has_geolocation { get; private set; }

        /* The photograph metadata. */
        private GExiv2.Metadata metadata;

        /**
         * Creates a new photograph.
         * @param file the file with the photograph.
         */
        public Photograph(GLib.File file) throws GLib.Error {
            this.file = file;

            metadata = new GExiv2.Metadata();
            metadata.open_path(file.get_path());

            // if (metadata.has_tag(Tag.ORIENTATION.to_string())) {
            //     orientation = (Orientation)
            //         metadata.try_get_tag_long(Tag.ORIENTATION.to_string());
            // } else {
            orientation = Orientation.LANDSCAPE;
            // }

            if (metadata.has_tag(Tag.LATITUDE.to_string())     &&
                metadata.has_tag(Tag.LONGITUDE.to_string())    &&
                metadata.has_tag(Tag.LATITUDE_REF.to_string()) &&
                metadata.has_tag(Tag.LONGITUDE_REF.to_string())) {
                string lat =
                    metadata.try_get_tag_string(Tag.LATITUDE.to_string());
                string lon =
                    metadata.try_get_tag_string(Tag.LONGITUDE.to_string());
                latitude  = decimals_to_double(lat);
                longitude = decimals_to_double(lon);
                if (metadata.try_get_tag_string(
                        Tag.LATITUDE_REF.to_string()) == "S")
                    latitude *= -1.0;
                if (metadata.try_get_tag_string(
                        Tag.LONGITUDE_REF.to_string()) == "W")
                    longitude *= -1.0;
                has_geolocation = true;
            }

            update_data();
        }

        /**
         * Rotates the photograph 90° to the left.
         */
        public void rotate_left() {
            // switch (orientation) {
            // case Orientation.PORTRAIT:
            //     orientation = Orientation.LANDSCAPE;
            //     break;
            // case Orientation.LANDSCAPE:
            //     orientation = Orientation.REVERSE_PORTRAIT;
            //     break;
            // case Orientation.REVERSE_PORTRAIT:
            //     orientation = Orientation.REVERSE_LANDSCAPE;
            //     break;
            // case Orientation.REVERSE_LANDSCAPE:
            //     orientation = Orientation.PORTRAIT;
            //     break;
            // }
        }

        /**
         * Rotates the photograph 90° to the right.
         */
        public void rotate_right() {
            // switch (orientation) {
            // case Orientation.PORTRAIT:
            //     orientation = Orientation.REVERSE_LANDSCAPE;
            //     break;
            // case Orientation.REVERSE_LANDSCAPE:
            //     orientation = Orientation.REVERSE_PORTRAIT;
            //     break;
            // case Orientation.REVERSE_PORTRAIT:
            //     orientation = Orientation.LANDSCAPE;
            //     break;
            // case Orientation.LANDSCAPE:
            //     orientation = Orientation.PORTRAIT;
            //     break;
            // }
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
        private void update_data() throws GLib.Error {
            try {
                if (metadata.has_tag(Tag.DATE_TIME.to_string())) {
                    var dt = metadata.try_get_tag_string(
                        Tag.DATE_TIME.to_string()).strip();
                    var s = dt.split(" ");
                    var d = s[0].split(":");
                    var t = s[1].split(":");
                    int year = int.parse(d[0]);
                    int month = int.parse(d[1]);
                    int day = int.parse(d[2]);
                    int hour = int.parse(t[0]);
                    int minute = int.parse(t[1]);
                    int second = int.parse(t[2]);
                    int offset = (int)(
                        metadata.has_tag(Tag.TIMEZONE_OFFSET.to_string()) ?
                        metadata.try_get_tag_long(
                            Tag.TIMEZONE_OFFSET.to_string()) : 0);
                    var tz = new GLib.TimeZone.offset(offset * 60 * 60);
                    date_time = new GLib.DateTime(tz, year, month, day,
                                                  hour, minute, second);
                } else {
                    date_time = new GLib.DateTime.now_utc();
                }
                album = (metadata.has_tag(Tag.SUBJECT.to_string())) ?
                    metadata.try_get_tag_string(
                        Tag.SUBJECT.to_string()).strip() : "";
                caption = (metadata.has_tag(Tag.CAPTION.to_string())) ?
                    metadata.try_get_tag_string(
                        Tag.CAPTION.to_string()).strip() : "";
                comment = (metadata.has_tag(Tag.DESCRIPTION.to_string())) ?
                    metadata.try_get_tag_string(
                        Tag.DESCRIPTION.to_string()).strip() : "";
            } catch (GLib.Error e) {
                GLib.warning(@"Error getting tag: $(e.message)");
            }
        }

        /* Updates the text tags. */
        private void update_text_tags() throws GLib.Error {
            metadata.clear_tag(Tag.SUBJECT.to_string());
            metadata.try_set_tag_string(Tag.SUBJECT.to_string(),
                                        album);
            metadata.clear_tag(Tag.CAPTION.to_string());
            metadata.try_set_tag_string(Tag.CAPTION.to_string(),
                                        caption);
            metadata.clear_tag(Tag.DESCRIPTION.to_string());
            metadata.try_set_tag_string(Tag.DESCRIPTION.to_string(),
                                        comment);
            metadata.try_set_tag_long(Tag.ORIENTATION.to_string(),
                                      orientation);
            metadata.save_file(file.get_path());
            if (metadata.has_tag(Tag.THUMB_ORIENTATION.to_string()))
                metadata.try_set_tag_long(Tag.THUMB_ORIENTATION.to_string(),
                                          orientation);
        }

        /* Updates the geolocation tags. */
        private void update_geolocation_tags() throws GLib.Error {
            if (!has_geolocation)
                return;
            var lat = Math.fabs(latitude);
            var lon = Math.fabs(longitude);
            var lat_ref = (latitude  < 0.0) ? "S" : "N";
            var lon_ref = (longitude < 0.0) ? "W" : "E";
            var slat = double_to_decimals(lat);
            var slon = double_to_decimals(lon);
            metadata.try_set_tag_string(Tag.LATITUDE.to_string(),
                                        slat);
            metadata.try_set_tag_string(Tag.LONGITUDE.to_string(),
                                        slon);
            metadata.try_set_tag_string(Tag.LATITUDE_REF.to_string(),
                                        lat_ref);
            metadata.try_set_tag_string(Tag.LONGITUDE_REF.to_string(),
                                        lon_ref);
            if (!metadata.has_tag(Tag.GPS_TAG.to_string()))
                metadata.try_set_tag_long(Tag.GPS_TAG.to_string(),
                                          DEFAULT_GPS_TAG);
            if (!metadata.has_tag(Tag.GPS_VERSION.to_string()))
                metadata.try_set_tag_string(Tag.GPS_VERSION.to_string(),
                                            DEFAULT_GPS_VERSION);
            if (!metadata.has_tag(Tag.GPS_DATUM.to_string()))
                metadata.try_set_tag_string(Tag.GPS_DATUM.to_string(),
                                            DEFAULT_GPS_DATUM);
            if (!metadata.has_tag(Tag.GPS_DATE.to_string()))
                metadata.try_set_tag_string(Tag.GPS_DATE.to_string(),
                                            get_gps_date());
            if (!metadata.has_tag(Tag.GPS_TIME.to_string()))
                metadata.try_set_tag_string(Tag.GPS_TIME.to_string(),
                                            get_gps_time());
        }

        /* Gets the GPS date. */
        private string get_gps_date() throws GLib.Error {
            var date = metadata.try_get_tag_string(Tag.DATE_TIME.to_string());
            return parse_triad(date.split(" ")[0]);
        }

        /* Gets the GPS time. */
        private string get_gps_time() throws GLib.Error {
            var date = metadata.try_get_tag_string(Tag.DATE_TIME.to_string());
            return parse_triad(date.split(" ")[1]);
        }

        /* Parse colon separated triad. */
        private string parse_triad(string triad) {
            var t = triad.split(":");
            int a = int.parse(t[0]);
            int b = int.parse(t[1]);
            int c = int.parse(t[2]);
            return "%d/1 %d/1 %d/1".printf(a, b, c);
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
            return "%d/1 %d/500 %d/100".printf((int)i, (int)m, (int)s);
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
