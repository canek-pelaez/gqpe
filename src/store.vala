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
        private static bool update;
        private static bool quiet;

        /* The options. */
        private const GLib.OptionEntry[] options = {
            { "location", 'l', 0, GLib.OptionArg.NONE, ref location,
              "Use location look up for descriptions and album names", null },
            { "update", 'u', 0, GLib.OptionArg.NONE, ref update,
              "Update the metadata of the photograph", null },
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
            if (update) {
                photo = new Photograph(GLib.File.new_for_commandline_arg(dest));
                photo.save_metadata();
            }
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

        public static int main(string[] args) {
            GLib.Intl.setlocale();
            location = update = quiet = false;
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
