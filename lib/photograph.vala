/*
 * This file is part of gqpe.
 *
 * Copyright © 2013-2021 Canek Peláez Valdés
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
         * The title of the photograph.
         */
        public string title { get; set; }

        /**
         * The album of the photograph.
         */
        public string album { get; set; }

        /**
         * The comment of the photograph.
         */
        public string comment { get; set; }

        /**
         * The date and time of the photograph.
         */
        public GLib.DateTime datetime { get; set; }

        /**
         * The timezone offset.
         */
        public int timezone_offset { get; set; }

        /**
         * The photograph orientation.
         */
        public Orientation orientation {
            get; set; default = Orientation.LANDSCAPE;
        }

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
        public long gps_tag { get; set; }

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
         * The photograph path.
         */
        public string path { owned get { return file.get_path(); } }

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
            get_metadata();
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
            set_metadata();
            metadata.save_file(file.get_path());
            modified = false;
        }

        /**
         * Sets the coordinates of the photograph.
         * @param latitude the latitude in radians.
         * @param longitude the longitude in radians.
         */
        public void set_coordinates(double latitude, double longitude) {
            has_geolocation = true;
            this.latitude = latitude;
            this.longitude = longitude;
            if (gps_tag == 0)
                gps_tag = DEFAULT_GPS_TAG;
            if (gps_version == null)
                gps_version = DEFAULT_GPS_VERSION;
            if (gps_datum == null)
                gps_datum = DEFAULT_GPS_DATUM;
        }

        /**
         * Compares the photograph with the one received, by datetime.
         * @param photograph the photograph to compare to.
         * @return an integer less than zero if the photograph is from before
         *         the one received; zero if they both have the same datetime;
         *         and an integer greater than zero otherwise.
         */
        public int compare_to(Photograph photograph) {
            int r = datetime.compare(photograph.datetime);
            if (r != 0)
                return r;
            return path.collate(photograph.path);
        }

        /**
         * Copies the GPS data from the received photograph.
         * @param photo the photograph.
         */
        public void copy_gps_data(Photograph photo) {
            latitude = photo.latitude;
            longitude = photo.longitude;
            gps_tag = photo.gps_tag;
            gps_version = photo.gps_version;
            gps_datum = photo.gps_datum;
            has_geolocation = photo.has_geolocation;
        }

        /**
         * Copies the metadata from the received photograph.
         * @param photo the photograph.
         * @param no_gps whether to skip the GPS data.
         * @param no_datetime whether to skip the datetime data.
         */
        public void copy_metadata(Photograph photo,
                                  bool no_gps = false,
                                  bool no_datetime = false) {
            title = photo.title;
            album = photo.album;
            comment = photo.comment;
            orientation = photo.orientation;
            if (!no_datetime) {
                datetime = photo.datetime;
                timezone_offset = photo.timezone_offset;
            }
            if (!no_gps) {
                latitude = photo.latitude;
                longitude = photo.longitude;
                gps_tag = photo.gps_tag;
                gps_version = photo.gps_version;
                gps_datum = photo.gps_datum;
                has_geolocation = photo.has_geolocation;
            }
        }

        /* Calculates the timezone. */
        private GLib.TimeZone get_time_zone() throws GLib.Error {
            return new GLib.TimeZone.offset(timezone_offset * 60 * 60);
        }

        /* Gets the date and time from full data. */
        private void get_dt_full(GLib.TimeZone tz,
                                 int year, int month, int day,
                                 int hour, int minute, int second)
            throws GLib.Error {
            datetime = new GLib.DateTime(tz,
                                         year, month, day,
                                         hour, minute, second);
        }

        /* Reads the date and time. */
        private void get_dt() throws GLib.Error {
            var dt = metadata.try_get_tag_string(
                Tag.DATETIME.tag()).strip();
            var s = dt.split(" ");
            var d = s[0].split(":");
            var t = s[1].split(":");
            get_dt_full(get_time_zone(),
                        int.parse(d[0]), int.parse(d[1]),
                        int.parse(d[2]), int.parse(t[0]),
                        int.parse(t[1]), int.parse(t[2]));
        }

        /* Reads the date and time from GPS. */
        private void get_dt_gps() throws GLib.Error {
            var dt = get_gps_datetime();
            get_dt_full(get_time_zone(),
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
        }

        /* Reads the timezone offset from the metadata. */
        private int get_tz_offset() throws GLib.Error {
            return (int)(metadata.has_tag(Tag.TIMEZONE_OFFSET.tag()) ?
                         metadata.try_get_tag_long(Tag.TIMEZONE_OFFSET.tag())
                         : 0);
        }

        /* Reads the data from the metadata. */
        private void get_metadata() throws GLib.Error {
            title = (metadata.has_tag(Tag.TITLE.tag())) ?
                metadata.try_get_tag_string(Tag.TITLE.tag()).strip() : "";
            album = (metadata.has_tag(Tag.ALBUM.tag())) ?
                metadata.try_get_tag_string(Tag.ALBUM.tag()).strip() : "";
            comment = (metadata.has_tag(Tag.DESCRIPTION.tag())) ?
                metadata.try_get_tag_string(Tag.DESCRIPTION.tag()).strip()
                : "";
            if (metadata.has_tag(Tag.DATETIME.tag())) {
                timezone_offset = get_tz_offset();
                get_dt();
            } else if (has_geolocation) {
                timezone_offset = get_tz_offset();
                get_dt_gps();
            } else {
                datetime = Util.get_file_datetime(file.get_path());
                timezone_offset = 0;
            }
            check_gps_datetime();
            orientation = (Orientation)(
                metadata.has_tag(Tag.ORIENTATION.tag()) ?
                metadata.try_get_tag_long(Tag.ORIENTATION.tag()) :
                Orientation.LANDSCAPE);
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
                gps_tag =
                    (metadata.has_tag(Tag.GPS_TAG.tag()) ?
                     metadata.try_get_tag_long(Tag.GPS_TAG.tag()) :
                     DEFAULT_GPS_TAG);
                gps_version =
                    (metadata.has_tag(Tag.GPS_VERSION.tag()) ?
                     metadata.try_get_tag_string(Tag.GPS_VERSION.tag()) :
                     DEFAULT_GPS_VERSION);
                gps_datum =
                    (metadata.has_tag(Tag.GPS_DATUM.tag()) ?
                     metadata.try_get_tag_string(Tag.GPS_DATUM.tag()) :
                     DEFAULT_GPS_DATUM);
                has_geolocation = true;
            }
        }

        /* Sets the metadata. */
        private void set_metadata() throws GLib.Error {
            metadata.clear_tag(Tag.TITLE.tag());
            metadata.try_set_tag_string(Tag.TITLE.tag(), title);
            metadata.clear_tag(Tag.ALBUM.tag());
            metadata.try_set_tag_string(Tag.ALBUM.tag(), album);
            metadata.clear_tag(Tag.DESCRIPTION.tag());
            metadata.try_set_tag_string(Tag.DESCRIPTION.tag(), comment);
            metadata.clear_tag(Tag.DATETIME.tag());
            metadata.try_set_tag_string(Tag.DATETIME.tag(),
                                        datetime.format("%Y:%m:%d %H:%M:%S"));
            metadata.clear_tag(Tag.TIMEZONE_OFFSET.tag());
            metadata.try_set_tag_long(Tag.TIMEZONE_OFFSET.tag(),
                                      timezone_offset);
            metadata.try_set_tag_long(Tag.ORIENTATION.tag(), orientation);
            metadata.save_file(file.get_path());
            if (metadata.has_tag(Tag.THUMB_ORIENTATION.tag()))
                metadata.try_set_tag_long(Tag.THUMB_ORIENTATION.tag(),
                                          orientation);
            set_geolocation_metadata();
        }

        /* Updates the geolocation metadata. */
        private void set_geolocation_metadata() throws GLib.Error {
            if (!has_geolocation)
                return;
            var lat = Math.fabs(latitude);
            var lon = Math.fabs(longitude);
            var lat_ref = (latitude  < 0.0) ? "S" : "N";
            var lon_ref = (longitude < 0.0) ? "W" : "E";
            var slat = double_to_decimals(lat);
            var slon = double_to_decimals(lon);
            metadata.clear_tag(Tag.LATITUDE.tag());
            metadata.try_set_tag_string(Tag.LATITUDE.tag(), slat);
            metadata.clear_tag(Tag.LONGITUDE.tag());
            metadata.try_set_tag_string(Tag.LONGITUDE.tag(), slon);
            metadata.clear_tag(Tag.LATITUDE_REF.tag());
            metadata.try_set_tag_string(Tag.LATITUDE_REF.tag(), lat_ref);
            metadata.clear_tag(Tag.LONGITUDE_REF.tag());
            metadata.try_set_tag_string(Tag.LONGITUDE_REF.tag(), lon_ref);
            metadata.clear_tag(Tag.GPS_TAG.tag());
            metadata.try_set_tag_long(Tag.GPS_TAG.tag(), gps_tag);
            metadata.clear_tag(Tag.GPS_VERSION.tag());
            metadata.try_set_tag_string(Tag.GPS_VERSION.tag(), gps_version);
            metadata.clear_tag(Tag.GPS_DATUM.tag());
            metadata.try_set_tag_string(Tag.GPS_DATUM.tag(), gps_datum);
            metadata.clear_tag(Tag.GPS_DATE.tag());
            var gps_date = "%d/1 %d/1 %d/1".printf(datetime.get_year(),
                                                   datetime.get_month(),
                                                   datetime.get_day_of_month());
            metadata.try_set_tag_string(Tag.GPS_DATE.tag(), gps_date);
            metadata.clear_tag(Tag.GPS_TIME.tag());
            var gps_time = "%d/1 %d/1 %d/1".printf(datetime.get_hour(),
                                                   datetime.get_minute(),
                                                   datetime.get_second());
            metadata.try_set_tag_string(Tag.GPS_TIME.tag(), gps_time);
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
