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
        /* The shift time argument. */
        private static int shift_time;
        /* Whether to reset the datetime. */
        private static bool reset_time;
        /* The print format argument. */
        private static string print_format;
        /* Whether to only print missing GPS data. */
        private static bool missing_gps;
        /* Whether to be quiet. */
        private static bool quiet;
        /* The photographs. */
        private static Gee.TreeSet<Photograph> photos;

        /* The option context. */
        private const string CONTEXT =
            _("[FILENAME…] - Edit and show the image tags.");

        /* Returns option context. */
        private static string get_description() {
            return _(
"""With no flags the tags are printed. An empty string as parameter
removes an individual tag. You cannot mix -s, -r, or -m with
other options.

Format for printing:

  %p: The file path
  %P: The file directory name
  %b: The file basename
  %t: The title
  %a: The album
  %D: The description
  %T: The date and time
  %z: The timezone offset
  %o: The orientation
  %Y: The latitude
  %X: The longitude

Also, any standard C escape character can be used: "\n" for new
line, "\t" for tab, etc.
""");
        }

        /* Returns the options. */
        private static GLib.OptionEntry[] get_options() {
            GLib.OptionEntry[] options = {
                { "title", 't', 0, GLib.OptionArg.STRING, ref title,
                  _("Set the title"), "TITLE" },
                { "album", 'a', 0, GLib.OptionArg.STRING, ref album,
                  _("Set the album"), "ALBUM" },
                { "comment", 'c', 0, GLib.OptionArg.STRING, ref comment,
                  _("Set the comment"), "COMMENT" },
                { "datetime", 'd', 0, GLib.OptionArg.STRING, ref s_datetime,
                  _("Set the date and time"), "DATETIME" },
                { "offset", 'z', 0, GLib.OptionArg.STRING, ref s_offset,
                  _("Set the timezone offset"), "OFFSET" },
                { "orientation", 'o', 0, GLib.OptionArg.STRING,
                  ref s_orientation, _("Set the orientation"), "ORIENTATION" },
                { "latitude", 'y', 0, GLib.OptionArg.STRING, ref s_latitude,
                  _("Set the latitude"), "LATITUDE" },
                { "longitude", 'x', 0, GLib.OptionArg.STRING, ref s_longitude,
                  _("Set the longitude"), "LONGITUDE" },
                { "shift-time", 's', 0, GLib.OptionArg.INT, &shift_time,
                  _("Shift the time in this amount of hours"), "HOURS" },
                { "reset-time", 'r', 0, GLib.OptionArg.NONE, &reset_time,
                  _("Reset the file timestamp to the photograph one"),
                  "HOURS" },
                { "print", 'p', 0, GLib.OptionArg.STRING, ref print_format,
                  _("Print the tags with format"), "FORMAT" },
                { "missing-gps", 'm', 0, GLib.OptionArg.NONE, &missing_gps,
                  _("Only print the path of images without GPS data"), null },
                { "quiet", 'q', 0, GLib.OptionArg.NONE, &quiet,
                  _("Be quiet"), null },
                { null }
            };
            return options;
        }

        /* Loads the photograph. */
        private static Photograph get_photograph(string path) {
            Photograph photo = null;
            if (!FileUtils.test(path, FileTest.EXISTS)) {
                stderr.printf(_("No such file: ‘%s’\n"), path);
                return photo;
            }
            var file = GLib.File.new_for_commandline_arg(path);
            try {
                photo = new Photograph(file);
            } catch (GLib.Error e) {
                stderr.printf(_("Error loading: ‘%s’\n"), path);
                return photo;
            }
            return photo;
        }

        /* Print the path of images without GPS data. */
        private static void print_missing_gps() {
            foreach (var photo in photos) {
                if (!photo.has_geolocation)
                    stdout.printf("%s\n", photo.path);
            }
        }

        /* Shifts time. */
        private static void do_shift_time() {
            foreach (var photo in photos) {
                stderr.printf(_("Shifting time for %s…\n"), photo.path);
                photo.datetime = photo.datetime.add_hours(shift_time);
                save(photo);
            }
        }

        /* Resets time. */
        private static void do_reset_time() {
            foreach (var photo in photos) {
                var dt = Util.get_file_datetime(photo.path);
                if (dt.compare(photo.datetime) == 0)
                    continue;
                stderr.printf(_("Resetting time for %s…\n"), photo.path);
                Util.set_file_datetime(photo.path, photo.datetime);
            }
        }

        /* Prints the tags with a format. */
        private static void print_with_format() {
            foreach (var photo in photos) {
                var p = photo.path;
                var P = GLib.Path.get_dirname(p);
                var b = photo.file.get_basename();
                var t = (photo.title != null) ? photo.title : "";
                var a = (photo.album != null) ? photo.album : "";
                var d = (photo.comment != null) ? photo.comment : "";
                var dt = (photo.datetime != null) ?
                    photo.datetime.format_iso8601() : "";
                var z = "%d".printf(photo.timezone_offset);
                var o = photo.orientation.to_string();
                var y = !photo.has_geolocation ? "" :
                    "%2.11f".printf(photo.latitude);
                var x = !photo.has_geolocation ? "" :
                    "%2.11f".printf(photo.longitude);
                var s = print_format
                    .replace("%p", p)
                    .replace("%P", P)
                    .replace("%b", b)
                    .replace("%t", t)
                    .replace("%a", a)
                    .replace("%D", d)
                    .replace("%T", dt)
                    .replace("%z", z)
                    .replace("%o", o)
                    .replace("%Y", y)
                    .replace("%X", x)
                    .replace("\\n", "\n")
                    .replace("\\t", "\t");
                stdout.printf("%s", s);
            }
        }

        /* Returns the tags box. */
        private static string get_tags_box(Photograph photo) {
            var path = photo.path;
            var box = new PrettyBox(80, Color.RED);
            box.set_title(GLib.Filename.display_basename(path), Color.CYAN);
            if (photo.title != null && photo.title != "")
                box.add_body_key_value(_("Title"), photo.title);
            if (photo.album != null && photo.album != "")
                box.add_body_key_value(_("Album"), photo.album);
            if (photo.comment != null && photo.comment != "")
                box.add_body_key_value(_("Comment"), photo.comment);
            if (photo.datetime != null) {
                var dt = photo.datetime.format("%Y/%m/%d %H:%M:%S ");
                var s = (photo.timezone_offset < 0) ? "-" : "+";
                var offset = (photo.timezone_offset < 0) ?
                    -photo.timezone_offset : photo.timezone_offset;
                dt += "[%s%04d]".printf(s, offset);
                box.add_body_key_value(_("Date and time"), dt);
            }
            box.add_body_key_value(_("Orientation"),
                                   photo.orientation.to_string());
            if (photo.has_geolocation) {
                box.add_body_key_value(_("Latitude"),
                                       "%2.11f".printf(photo.latitude));
                box.add_body_key_value(_("Longitude"),
                                       "%2.11f".printf(photo.longitude));
                box.add_body_key_value(_("GPS tag"), "%ld".printf(photo.gps_tag));
                box.add_body_key_value(_("GPS version"), photo.gps_version);
                box.add_body_key_value(_("GPS datum"), photo.gps_datum);
            }
            return box.to_string();
        }

        /* Prints the tags. */
        private static void print_tags() {
            var tags = "";
            foreach (var photo in photos)
                tags += get_tags_box(photo);
            stdout.printf("%s", tags);
        }

        /* Handles the tag. */
        private static void handle_tag(Photograph photo) {
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
            if (!quiet)
                stderr.printf(_("Updating %s…\n"),
                              GLib.Filename.display_basename(photo.path));
            save(photo);
            if (!quiet)
                stderr.printf(_("%s updated.\n"),
                              GLib.Filename.display_basename(photo.path));
        }

        /* Handles the tags. */
        private static void handle_tags() {
            foreach (var photo in photos)
                handle_tag(photo);
        }

        /* Saves the photograph. */
        private static void save(Photograph photo) {
            try {
                photo.save_metadata();
            } catch (GLib.Error error) {
                stderr.printf(_("There was an error saving %s: %s\n"),
                              photo.path, error.message);
            }
        }

        /* Whether there will be properties edited. */
        private static bool edit_properties() {
            return title != null || album != null || comment != null ||
                datetime != null || offset != int.MAX || orientation != -1 ||
                latitude != double.MAX || longitude != double.MAX;
        }

        public static int main(string[] args) {
            GLib.Intl.setlocale(LocaleCategory.ALL, "");
            reset_time = missing_gps = quiet = false;
            orientation = -1;
            offset = int.MAX;
            latitude = longitude = double.MAX;
            try {
                var opt = new GLib.OptionContext(CONTEXT);
                opt.set_help_enabled(true);
                opt.add_main_entries(get_options(), null);
                opt.set_description(get_description());
                opt.parse(ref args);
            } catch (GLib.Error e) {
                stderr.printf("%s\n", e.message);
                Util.error(_("Run ‘%s --help’ for a list of options"), args[0]);
            }

            if (args.length < 2)
                Util.error(_("Missing image files"));

            int mix = 0;
            mix += edit_properties() ? 1 : 0;
            mix += shift_time != 0 ? 1 : 0;
            mix += print_format != null ? 1 : 0;
            mix += reset_time ? 1 : 0;
            mix += missing_gps ? 1 : 0;

            if (mix > 1) {
                var m =
                    _("You cannot mix -s, -r, -p, or -m with other options");
                Util.error(m);
            }

            if (s_orientation != null) {
                orientation = Orientation.parse_orientation(s_orientation);
                if (orientation < 0)
                    Util.error(_("Invalid orientation: %s"), s_orientation);
            }

            if (s_datetime != null) {
                datetime = new GLib.DateTime.from_iso8601(s_datetime, null);
                if (datetime == null) {
                    var tz = new TimeZone.utc();
                    datetime = new GLib.DateTime.from_iso8601(s_datetime, tz);
                }
                if (datetime == null)
                    Util.error(_("Invalid date and time: %s"), s_datetime);
            }

            if (s_offset != null && !int.try_parse(s_offset, out offset))
                Util.error(_("Invalid timezone offset: %s"), s_offset);

            if (s_latitude != null && !double.try_parse(s_latitude,
                                                        out latitude))
                Util.error(_("Invalid latitude: %s"), s_latitude);

            if (s_longitude != null && !double.try_parse(s_longitude,
                                                         out longitude))
                Util.error(_("Invalid longitude: %s"), s_longitude);

            if (latitude != double.MAX && longitude == double.MAX)
                Util.error(
                    _("Latitude will only be set on photos with GPS data"));
            if (latitude == double.MAX && longitude != double.MAX)
                Util.error(
                    _("Longitude will only be set on photos with GPS data"));

            photos = new Gee.TreeSet<Photograph>();
            stderr.printf(_("Loading photos…\n"));
            int c = 0;
            for (int i = 1; i < args.length; i++) {
                var photo = get_photograph(args[i]);
                if (photo != null) {
                    photos.add(photo);
                    stderr.printf(_("Loaded %d photos…  \r\b"), c++);
                }
            }
            if (c == 0)
                Util.error(_("No photos Loaded.     \n"));
            else
                stderr.printf(_("Loaded %d photos…    \n"), c);

            if (missing_gps)
                print_missing_gps();
            else if (shift_time != 0)
                do_shift_time();
            else if (reset_time)
                do_reset_time();
            else if (print_format != null)
                print_with_format();
            else if (!edit_properties())
                print_tags();
            else
                handle_tags();

            return 0;
        }
    }
}
