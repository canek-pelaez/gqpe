/* tag.vala
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
     * Tags application.
     */
    public class Tags {

        /* The title argument. */
        private static string title;
        /* The album argument. */
        private static string album;
        /* The comment argument. */
        private static string comment;
        /* The orientation argument. */
        private static string s_orientation;
        /* The orientation value. */
        private static int orientation;
        /* The datetime argument. */
        private static string s_datetime;
        /* The datetime value. */
        private static GLib.DateTime datetime;
        /* The offset argument. */
        private static string s_offset;
        /* The offset value. */
        private static int offset;
        /* The latitude argument. */
        private static string s_latitude;
        /* The latitude value. */
        private static double latitude;
        /* The longitude argument. */
        private static string s_longitude;
        /* The longitude value. */
        private static double longitude;
        /* The shift_time argument. */
        private static int shift_time;

        /* The options. */
        private const GLib.OptionEntry[] options = {
            { "title", 't', 0, GLib.OptionArg.STRING, ref title,
              "Set the title", "TITLE" },
            { "comment", 'c', 0, GLib.OptionArg.STRING, ref comment,
              "Set the comment", "COMMENT" },
            { "album", 'a', 0, GLib.OptionArg.STRING, ref album,
              "Set the album", "ALBUM" },
            { "datetime", 'd', 0, GLib.OptionArg.STRING, ref s_datetime,
              "Set the datetime", "DATETIME" },
            { "offset", 'z', 0, GLib.OptionArg.STRING, ref s_offset,
              "Set the timezone offset", "OFFSET" },
            { "orientation", 'o', 0, GLib.OptionArg.STRING, ref s_orientation,
              "Set the orientation", "ORIENTATION" },
            { "latitude", 'y', 0, GLib.OptionArg.STRING, ref s_latitude,
              "Set the latitude", "LATITUDE" },
            { "longitude", 'x', 0, GLib.OptionArg.STRING, ref s_longitude,
              "Set the longitude", "LONGITUDE" },
            { "shift-time", 's', 0, GLib.OptionArg.INT, ref shift_time,
              "Shift the time in this amount of hours", "HOURS" },
            { null }
        };

        /* The option context. */
        private const string CONTEXT =
            "[FILENAME...] - Edit and show the image tags";

        /* The option context. */
        private const string DESCRIPTION =
            """With no flags the tags are printed.""";

        /* Loads the photograph. */
        private static Photograph get_photograph(string path) {
            Photograph photo = null;
            if (!FileUtils.test(path, FileTest.EXISTS)) {
                stderr.printf("No such file: ‘%s’", path);
                return photo;
            }
            var file = GLib.File.new_for_commandline_arg(path);
            try {
                photo = new Photograph(file);
            } catch (GLib.Error e) {
                stderr.printf("Error loading: ‘%s’", path);
                return photo;
            }
            return photo;
        }

        /* Returns the tags box. */
        private static string get_tags_box(string path) {
            var photo = get_photograph(path);
            if (photo == null)
                return "";
            var box = new PrettyBox(80, Color.RED);
            box.set_title(GLib.Filename.display_basename(path), Color.CYAN);
            if (photo.title != null && photo.title != "")
                box.add_body_key_value("Title", photo.title);
            if (photo.album != null && photo.album != "")
                box.add_body_key_value("Album", photo.album);
            if (photo.comment != null && photo.comment != "")
                box.add_body_key_value("Comment", photo.comment);
            if (photo.datetime != null) {
                var dt = photo.datetime.format("%Y/%m/%d %H:%M:%S ");
                var s = (photo.timezone_offset < 0) ? "-" : "+";
                var mul = (photo.timezone_offset < 0) ? -1 : 1;
                dt += "[%s%04d]".printf(s, photo.timezone_offset * mul);
                box.add_body_key_value("Datetime", dt);
            }
            box.add_body_key_value("Orientation",
                                   photo.orientation.to_string());
            if (photo.has_geolocation) {
                box.add_body_key_value("Latitude",
                                       "%2.11f".printf(photo.latitude));
                box.add_body_key_value("Longitude",
                                       "%2.11f".printf(photo.longitude));
                box.add_body_key_value("GPS tag", "%ld".printf(photo.gps_tag));
                box.add_body_key_value("GPS version", photo.gps_version);
                box.add_body_key_value("GPS datum", photo.gps_datum);
            }
            return box.to_string();
        }

        /* Prints the tags. */
        private static void print_tags(string[] args) {
            string tags = "";
            for (int i = 1; i < args.length; i++)
                tags += get_tags_box(args[i]);
            stderr.printf("%s", tags);
        }

        /* Shifts time. */
        private static void do_shift_time(string[] args) {
            for (int i = 1; i < args.length; i++) {
                var photo = get_photograph(args[i]);
                if (photo == null)
                    continue;
                photo.timezone_offset += shift_time;
                save(photo);
            }
        }

        /* Handles the tag. */
        private static void handle_tag(string path) {
            var photo = get_photograph(path);
            if (photo == null)
                return;
            if (album != null)
                photo.album = album;
            if (title != null)
                photo.title = title;
            if (comment != null)
                photo.comment = comment;
            if (orientation != -1)
                photo.orientation = (Orientation)orientation;
            if (datetime != null)
                photo.datetime = datetime;
            if (offset != int.MAX)
                photo.timezone_offset = offset;
            if (photo.has_geolocation) {
                var lat = photo.latitude;
                var lon = photo.longitude;
                if (latitude != double.MAX)
                    lat = latitude;
                if (longitude != double.MAX)
                    lon = longitude;
                photo.set_coordinates(lat, lon);
            } else if (latitude != double.MAX && longitude != double.MAX) {
                photo.set_coordinates(latitude, longitude);
            }
            save(photo);
        }

        /* Saves the photograph. */
        private static void save(Photograph photo) {
            try {
                photo.save_metadata();
            } catch (GLib.Error error) {
                stderr.printf("There was an error saving %s: %s\n",
                              photo.file.get_path(), error.message);
            }
        }

        /* Whether there will be properties edited. */
        private static bool edit_properties() {
            return album != null || title != null ||
                comment != null || orientation != -1 ||
                latitude != double.MAX || longitude != double.MAX ||
                datetime != null;
        }

        public static int main(string[] args) {
            orientation = -1;
            offset = int.MAX;
            latitude = longitude = double.MAX;
            try {
                var opt = new GLib.OptionContext(CONTEXT);
                opt.set_help_enabled(true);
                opt.add_main_entries(options, null);
                opt.set_description(DESCRIPTION);
                opt.parse(ref args);
            } catch (GLib.Error e) {
                stderr.printf(e.message + "\n");
                stderr.printf("Run ‘%s --help’ for a list of options.\n",
                              args[0]);
                GLib.Process.exit(1);
            }

            if (args.length < 2) {
                stderr.printf("Missing files");
                return 1;
            }

            if (shift_time != 0 && edit_properties()) {
                stderr.printf("You cannot shift time and " +
                              "edit at the same time");
                return 1;
            }

            if (s_orientation != null) {
                orientation = Orientation.parse_orientation(s_orientation);
                if (orientation < 0) {
                    stderr.printf("Invalid orientation: %s\n", s_orientation);
                    return 1;
                }
            }

            if (s_datetime != null) {
                datetime = new GLib.DateTime.from_iso8601(s_datetime, null);
                if (datetime == null)
                    datetime = new GLib.DateTime.from_iso8601(
                        s_datetime, new TimeZone.utc());
                if (datetime == null) {
                    stderr.printf("Invalid datetime: %s\n", s_datetime);
                    return 1;
                }
            }

            if (s_offset != null &&
                !int.try_parse(s_offset, out offset)) {
                stderr.printf("Invalid timezone offset: %s\n", s_offset);
                return 1;
            }

            if (s_latitude != null &&
                !double.try_parse(s_latitude, out latitude)) {
                stderr.printf("Invalid latitude: %s\n", s_latitude);
                return 1;
            }
            if (s_longitude != null &&
                !double.try_parse(s_longitude, out longitude)) {
                stderr.printf("Invalid longitude: %s\n", s_longitude);
                return 1;
            }

            if (latitude != double.MAX && longitude == double.MAX)
                stderr.printf("Latitude will only be set on " +
                              "photos with GPS data\n");
            if (latitude == double.MAX && longitude != double.MAX)
                stderr.printf("Longitude will only be set on " +
                              "photos with GPS data\n");

            if (shift_time != 0) {
                do_shift_time(args);
                return 0;
            }

            if (!edit_properties()) {
                print_tags(args);
                return 0;
            }

            for (int i = 1; i < args.length; i++)
                handle_tag(args[i]);

            return 0;
        }
    }
}
