/* move.vala
 *
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
     * Store application.
     */
    public class Store {

        private static string input;
        private static string output;
        private static bool location;
        private static bool quiet;

        /* The options. */
        private const GLib.OptionEntry[] options = {
            { "location", 'l', 0, GLib.OptionArg.NONE, ref location,
              "Use location look up for descriptions and album names", null },
            { "quiet", 'q', 0, GLib.OptionArg.NONE, ref quiet,
              "Be quiet", null },
            { null }
        };

        /* The option context. */
        private const string CONTEXT =
            "INPUTDIR OUTPUTDIR - Move images to a normalized location.";

        private static string get_location(Photograph photo) {
            return "Tlacochiztlahuaca";
        }

        private static string get_album(Photograph photo) {
            if (photo.album != null && photo.album != "")
                return photo.album;
            var dt = photo.datetime;
            var r = "%s %d".printf(dt.format("%A"), dt.get_day_of_month());
            if (location && photo.has_geolocation)
                r += ", near %s".printf(get_location(photo));
            return r;
        }

        private static void mkdir(string path) throws GLib.Error {
            if (!FileUtils.test(path, FileTest.EXISTS)) {
                var d = File.new_for_path(path);
                d.make_directory();
            }
        }

        private static void move_photo(string path) throws GLib.Error {
            var file = GLib.File.new_for_commandline_arg(path);
            Photograph photo;
            try {
                photo = new Photograph(file);
            } catch (GLib.Error e) {
                if (!quiet) {
                    stderr.printf("There was an error processing %s: %s. ",
                                  path, e.message);
                    stderr.printf("Skipping.\n");
                }
                return;
            }
            var dt = photo.datetime;
            var year = "%04d".printf(dt.get_year());
            var month = "%02d".printf(dt.get_month());
            var album = Util.normalize(get_album(photo));
            var basename = GLib.Path.get_basename(photo.file.get_path());
            var name = Util.normalize_basename(basename);
            var dest = string.join(GLib.Path.DIR_SEPARATOR_S, output, year);
            mkdir(dest);
            dest = string.join(GLib.Path.DIR_SEPARATOR_S, dest, month);
            mkdir(dest);
            dest = string.join(GLib.Path.DIR_SEPARATOR_S, dest, album);
            mkdir(dest);
            dest = string.join(GLib.Path.DIR_SEPARATOR_S, output, year, month,
                               album, name);
            var dn = GLib.Path.get_dirname(dest);
            var bn = GLib.Path.get_basename(dest);
            var n = Util.get_name(bn);
            var e = Util.get_extension(bn);
            int c = 1;
            while (FileUtils.test(dest, FileTest.EXISTS))
                dest = string.join(GLib.Path.DIR_SEPARATOR_S, dn,
                                   "%s-%d.%s".printf(n, c++, e));
            photo.file.copy(GLib.File.new_for_commandline_arg(dest),
                            FileCopyFlags.OVERWRITE);
            dt = Util.get_file_datetime(path);
            Util.set_file_datetime(dest, dt);
            stderr.printf("%s → %s\n", path, dest);
        }

        private static void move_photos() throws GLib.Error {
            var root = File.new_for_path(input);
            if (!FileUtils.test(output, FileTest.EXISTS)) {
                var o = File.new_for_path(output);
                o.make_directory();
            }
            Gee.ArrayQueue<File> queue = new Gee.ArrayQueue<File>();
            queue.offer(root);
            while (!queue.is_empty) {
                var dir = queue.poll();
                var e = dir.enumerate_children(FileAttribute.STANDARD_NAME, 0);
                FileInfo file_info;
                while ((file_info = e.next_file ()) != null) {
                    var path = string.join(GLib.Path.DIR_SEPARATOR_S,
                                           dir.get_path(),
                                           file_info.get_name());
                    if (GLib.FileUtils.test(path, GLib.FileTest.IS_DIR))
                        queue.offer(File.new_for_path(path));
                    else
                        move_photo(path);
                }
            }
        }

        /* Loads the photograph. */
        // private static Photograph get_photograph(string path) {
        //     Photograph photo = null;
        //     if (!FileUtils.test(path, FileTest.EXISTS)) {
        //         stderr.printf("No such file: ‘%s’\n", path);
        //         return photo;
        //     }
        //     var file = GLib.File.new_for_commandline_arg(path);
        //     try {
        //         photo = new Photograph(file);
        //     } catch (GLib.Error e) {
        //         stderr.printf("Error loading: ‘%s’\n", path);
        //         return photo;
        //     }
        //     return photo;
        // }

        // /* Returns the tags box. */
        // private static string get_tags_box(string path) {
        //     var photo = get_photograph(path);
        //     if (photo == null)
        //         return "";
        //     var box = new PrettyBox(80, Color.RED);
        //     box.set_title(GLib.Filename.display_basename(path), Color.CYAN);
        //     if (photo.title != null && photo.title != "")
        //         box.add_body_key_value("Title", photo.title);
        //     if (photo.album != null && photo.album != "")
        //         box.add_body_key_value("Album", photo.album);
        //     if (photo.comment != null && photo.comment != "")
        //         box.add_body_key_value("Comment", photo.comment);
        //     if (photo.datetime != null) {
        //         var dt = photo.datetime.format("%Y/%m/%d %H:%M:%S ");
        //         var s = (photo.timezone_offset < 0) ? "-" : "+";
        //         var mul = (photo.timezone_offset < 0) ? -1 : 1;
        //         dt += "[%s%04d]".printf(s, photo.timezone_offset * mul);
        //         box.add_body_key_value("Datetime", dt);
        //     }
        //     box.add_body_key_value("Orientation",
        //                            photo.orientation.to_string());
        //     if (photo.has_geolocation) {
        //         box.add_body_key_value("Latitude",
        //                                "%2.11f".printf(photo.latitude));
        //         box.add_body_key_value("Longitude",
        //                                "%2.11f".printf(photo.longitude));
        //         box.add_body_key_value("GPS tag", "%ld".printf(photo.gps_tag));
        //         box.add_body_key_value("GPS version", photo.gps_version);
        //         box.add_body_key_value("GPS datum", photo.gps_datum);
        //     }
        //     return box.to_string();
        // }

        // /* Prints the tags with a format. */
        // private static void print_with_format(string[] args) {
        //     for (int i = 1; i < args.length; i++) {
        //         var photo = get_photograph(args[i]);
        //         if (photo == null)
        //             continue;
        //         var b = photo.file.get_basename();
        //         var t = (photo.title != null) ? photo.title : "";
        //         var a = (photo.album != null) ? photo.album : "";
        //         var d = (photo.comment != null) ? photo.comment : "";
        //         var dt = (photo.datetime != null) ?
        //             photo.datetime.format_iso8601() : "";
        //         var z = "%d".printf(photo.timezone_offset);
        //         var o = photo.orientation.to_string();
        //         var y = !photo.has_geolocation ? "" :
        //             "%2.11f".printf(photo.latitude);
        //         var x = !photo.has_geolocation ? "" :
        //             "%2.11f".printf(photo.longitude);
        //         var s = print_format
        //             .replace("%b", b)
        //             .replace("%t", t)
        //             .replace("%a", a)
        //             .replace("%D", d)
        //             .replace("%T", dt)
        //             .replace("%z", z)
        //             .replace("%o", o)
        //             .replace("%Y", y)
        //             .replace("%X", x)
        //             .replace("\\n", "\n")
        //             .replace("\\t", "\t");
        //         stderr.printf("%s", s);
        //     }
        // }

        // /* Prints the tags. */
        // private static void print_tags(string[] args) {
        //     var tags = "";
        //     for (int i = 1; i < args.length; i++)
        //         tags += get_tags_box(args[i]);
        //     stderr.printf("%s", tags);
        // }

        // /* Shifts time. */
        // private static void do_shift_time(string[] args) {
        //     for (int i = 1; i < args.length; i++) {
        //         var photo = get_photograph(args[i]);
        //         if (photo == null)
        //             continue;
        //         photo.timezone_offset += shift_time;
        //         save(photo);
        //     }
        // }

        // /* Handles the tag. */
        // private static void handle_tag(string path) {
        //     var photo = get_photograph(path);
        //     if (photo == null)
        //         return;
        //     if (album != null)
        //         photo.album = album;
        //     if (title != null)
        //         photo.title = title;
        //     if (comment != null)
        //         photo.comment = comment;
        //     if (orientation != -1)
        //         photo.orientation = (Orientation)orientation;
        //     if (datetime != null)
        //         photo.datetime = datetime;
        //     if (offset != int.MAX)
        //         photo.timezone_offset = offset;
        //     if (photo.has_geolocation) {
        //         var lat = photo.latitude;
        //         var lon = photo.longitude;
        //         if (latitude != double.MAX)
        //             lat = latitude;
        //         if (longitude != double.MAX)
        //             lon = longitude;
        //         photo.set_coordinates(lat, lon);
        //     } else if (latitude != double.MAX && longitude != double.MAX) {
        //         photo.set_coordinates(latitude, longitude);
        //     }
        //     if (!quiet)
        //         stderr.printf("Updating %s...\n",
        //                       GLib.Filename.display_basename(path));
        //     save(photo);
        //     if (!quiet)
        //         stderr.printf("%s updated.\n",
        //                       GLib.Filename.display_basename(path));
        // }

        // /* Saves the photograph. */
        // private static void save(Photograph photo) {
        //     try {
        //         photo.save_metadata();
        //     } catch (GLib.Error error) {
        //         stderr.printf("There was an error saving %s: %s\n",
        //                       photo.file.get_path(), error.message);
        //     }
        // }

        // /* Whether there will be properties edited. */
        // private static bool edit_properties() {
        //     return album != null || title != null ||
        //         comment != null || orientation != -1 ||
        //         latitude != double.MAX || longitude != double.MAX ||
        //         datetime != null || offset != int.MAX;
        // }

        public static int main(string[] args) {
            GLib.Intl.setlocale();
            location = quiet = false;
            try {
                var opt = new GLib.OptionContext(CONTEXT);
                opt.set_help_enabled(true);
                opt.add_main_entries(options, null);
                opt.parse(ref args);
            } catch (GLib.Error e) {
                stderr.printf("%s\n", e.message);
                stderr.printf("Run ‘%s --help’ for a list of options.\n",
                              args[0]);
                GLib.Process.exit(1);
            }

            if (args.length != 3) {
                stderr.printf("Exactly one output and one " +
                              "input directory needed.\n");
                GLib.Process.exit(1);
            }

            input = args[1];
            output = args[2];

            if (!GLib.FileUtils.test(input, GLib.FileTest.IS_DIR)) {
                stderr.printf("%s is not a directory\n", input);
                GLib.Process.exit(1);
            }

            try {
                move_photos();
            } catch (GLib.Error e) {
                stderr.printf("There was an error while moving: %s\n",
                              e.message);
                GLib.Process.exit(1);
            }

            return 0;
        }
    }
}
