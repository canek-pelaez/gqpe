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
        public GLib.DateTime datetime { get; set; }

        /**
         * The photograph orientation.
         */
        public Orientation orientation {
            get; set; default = Orientation.LANDSCAPE;
        }

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
        public double latitude { get; private set; }

        /**
         * The longitude coordinate.
         */
        public double longitude { get; private set; }

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
         * Whether the photograph has been modified.
         */
        public bool modified { get; private set; default = false; }

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

            if (metadata.has_tag(Tag.ORIENTATION.tag())) {
                orientation = (Orientation)
                    metadata.try_get_tag_long(Tag.ORIENTATION.tag());
            }

            if (metadata.has_tag(Tag.LATITUDE.tag())     &&
                metadata.has_tag(Tag.LONGITUDE.tag())    &&
                metadata.has_tag(Tag.LATITUDE_REF.tag()) &&
                metadata.has_tag(Tag.LONGITUDE_REF.tag())) {
                string lat =
                    metadata.try_get_tag_string(Tag.LATITUDE.tag());
                string lon =
                    metadata.try_get_tag_string(Tag.LONGITUDE.tag());
                latitude  = decimals_to_double(lat);
                longitude = decimals_to_double(lon);
                if (metadata.try_get_tag_string(
                        Tag.LATITUDE_REF.tag()) == "S")
                    latitude *= -1.0;
                if (metadata.try_get_tag_string(
                        Tag.LONGITUDE_REF.tag()) == "W")
                    longitude *= -1.0;
                has_geolocation = true;
            }

            update_data();
            this.notify.connect ((s, p) => modified = true);
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
        }

        /**
         * Saves the metadata of the photograph.
         * @throws GLib.Error if there is an error while loading.
         */
        public void save_metadata() throws GLib.Error {
            update_text_tags();
            update_geolocation_tags();
            metadata.save_file(file.get_path());
            modified = false;
        }

        public void set_coordinates(double latitude, double longitude) {
            has_geolocation = true;
            this.latitude = latitude;
            this.longitude = longitude;
            modified = true;
        }

        /* Calculates the timezone. */
        private GLib.TimeZone get_time_zone() throws GLib.Error {
            int offset = (int)(
                metadata.has_tag(Tag.TIMEZONE_OFFSET.tag()) ?
                metadata.try_get_tag_long(
                    Tag.TIMEZONE_OFFSET.tag()) : 0);
            return new GLib.TimeZone.offset(offset * 60 * 60);
        }

        /* Updates the date and time from full data. */
        private void update_datetime_full(GLib.TimeZone tz,
                                          int year, int month, int day,
                                          int hour, int minute, int second) {
            datetime = new GLib.DateTime(tz,
                                         year, month, day,
                                         hour, minute, second);
        }

        /* Updates the date and time. */
        private void update_datetime() throws GLib.Error {
            var dt = metadata.try_get_tag_string(
                Tag.DATETIME.tag()).strip();
            var s = dt.split(" ");
            var d = s[0].split(":");
            var t = s[1].split(":");
            update_datetime_full(get_time_zone(),
                                 int.parse(d[0]), int.parse(d[1]),
                                 int.parse(d[2]), int.parse(t[0]),
                                 int.parse(t[1]), int.parse(t[2]));
        }

        /* Updates the date and time from GPS. */
        private void update_datetime_gps() throws GLib.Error {
            var dt = get_gps_datetime();
            update_datetime_full(get_time_zone(),
                                 dt.get_year(), dt.get_month(),
                                 dt.get_day_of_month(), dt.get_hour(),
                                 dt.get_minute(), dt.get_second());
        }

        /* Checks the GPS datetime against the datetime. */
        private void check_gps_datetime() throws GLib.Error {
            var dt = get_gps_datetime();
            if (datetime.get_year()         != dt.get_year()         ||
                datetime.get_month()        != dt.get_month()        ||
                datetime.get_day_of_month() != dt.get_day_of_month() ||
                datetime.get_hour()         != dt.get_hour()         ||
                datetime.get_minute()       != dt.get_minute()       ||
                datetime.get_second()       != dt.get_second())
                set_gps_datetime(datetime);
        }

        /* Gets the GPS datetime. */
        private GLib.DateTime get_gps_datetime() throws GLib.Error {
            if (!has_geolocation)
                return new GLib.DateTime.from_unix_utc(0);
            var date = metadata.try_get_tag_string(Tag.GPS_DATE.tag()).strip();
            var time = metadata.try_get_tag_string(Tag.GPS_TIME.tag()).strip();
            double[] dd = decimals_to_doubles(date);
            double[] td = decimals_to_doubles(time);
            return new GLib.DateTime(get_time_zone(),
                                     (int)dd[0], (int)dd[1], (int)dd[2],
                                     (int)td[0], (int)td[1], (int)td[2]);
        }

        /* Sets the GPS datetime. */
        private void set_gps_datetime(GLib.DateTime datetime)
            throws GLib.Error {
            var date = "%d/1 %d/1 %d/1".printf(datetime.get_year(),
                                               datetime.get_month(),
                                               datetime.get_day_of_month());
            var time = "%d/1 %d/1 %d/1".printf(datetime.get_hour(),
                                               datetime.get_minute(),
                                               datetime.get_second());
            metadata.try_set_tag_string(Tag.GPS_DATE.tag(), date);
            metadata.try_set_tag_string(Tag.GPS_TIME.tag(), time);
            modified = true;
        }

        /* Updates the data from the metadata. */
        private void update_data() throws GLib.Error {
            try {
                if (metadata.has_tag(Tag.DATETIME.tag())) {
                    update_datetime();
                } else if (has_geolocation) {
                    update_datetime_gps();
                } else {
                    datetime = new GLib.DateTime.now_utc();
                }
                check_gps_datetime();
                album = (metadata.has_tag(Tag.SUBJECT.tag())) ?
                    metadata.try_get_tag_string(
                        Tag.SUBJECT.tag()).strip() : "";
                caption = (metadata.has_tag(Tag.CAPTION.tag())) ?
                    metadata.try_get_tag_string(
                        Tag.CAPTION.tag()).strip() : "";
                comment = (metadata.has_tag(Tag.DESCRIPTION.tag())) ?
                    metadata.try_get_tag_string(
                        Tag.DESCRIPTION.tag()).strip() : "";
            } catch (GLib.Error e) {
                GLib.warning(@"Error getting tag: $(e.message)");
            }
        }

        /* Updates the text tags. */
        private void update_text_tags() throws GLib.Error {
            metadata.clear_tag(Tag.SUBJECT.tag());
            metadata.try_set_tag_string(Tag.SUBJECT.tag(), album);
            metadata.clear_tag(Tag.CAPTION.tag());
            metadata.try_set_tag_string(Tag.CAPTION.tag(), caption);
            metadata.clear_tag(Tag.DESCRIPTION.tag());
            metadata.try_set_tag_string(Tag.DESCRIPTION.tag(), comment);
            metadata.try_set_tag_long(Tag.ORIENTATION.tag(), _orientation);
            metadata.save_file(file.get_path());
            if (metadata.has_tag(Tag.THUMB_ORIENTATION.tag()))
                metadata.try_set_tag_long(Tag.THUMB_ORIENTATION.tag(),
                                          _orientation);
            modified = true;
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
            metadata.try_set_tag_string(Tag.LATITUDE.tag(), slat);
            metadata.try_set_tag_string(Tag.LONGITUDE.tag(), slon);
            metadata.try_set_tag_string(Tag.LATITUDE_REF.tag(), lat_ref);
            metadata.try_set_tag_string(Tag.LONGITUDE_REF.tag(), lon_ref);
            if (!metadata.has_tag(Tag.GPS_TAG.tag()))
                metadata.try_set_tag_long(Tag.GPS_TAG.tag(), DEFAULT_GPS_TAG);
            if (!metadata.has_tag(Tag.GPS_VERSION.tag()))
                metadata.try_set_tag_string(Tag.GPS_VERSION.tag(),
                                            DEFAULT_GPS_VERSION);
            if (!metadata.has_tag(Tag.GPS_DATUM.tag()))
                metadata.try_set_tag_string(Tag.GPS_DATUM.tag(),
                                            DEFAULT_GPS_DATUM);
            if (!metadata.has_tag(Tag.GPS_DATE.tag()))
                metadata.try_set_tag_string(Tag.GPS_DATE.tag(), get_gps_date());
            if (!metadata.has_tag(Tag.GPS_TIME.tag()))
                metadata.try_set_tag_string(Tag.GPS_TIME.tag(), get_gps_time());
            modified = true;
        }

        /* Gets the GPS date. */
        private string get_gps_date() throws GLib.Error {
            var date = metadata.try_get_tag_string(Tag.DATETIME.tag());
            return parse_triad(date.split(" ")[0]);
        }

        /* Gets the GPS time. */
        private string get_gps_time() throws GLib.Error {
            var date = metadata.try_get_tag_string(Tag.DATETIME.tag());
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
            double[] d = decimals_to_doubles(decimals);
            return d[0] + d[1] / 60.0 + d[2] / 3600.0;
        }

        /* Converts decimals to an array of doubles. */
        private double[] decimals_to_doubles(string decimals) {
            string[] s = decimals.split(" ");
            double[] d = { 0.0, 0.0, 0.0 };
            for (int i = 0; i < s.length; i++)
                d[i] = decimal_to_double(s[i]);
            return d;
        }
    }
}
