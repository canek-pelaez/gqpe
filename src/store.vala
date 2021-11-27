/* store.vala
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

        /* City fields. */
        private enum CityField {
            ID,
            NAME,
            COUNTRY,
            POPULATION,
            LATITUDE,
            LONGITUDE;
        }

        /* The input directory. */
        private static string input;
        /* The output directory. */
        private static string output;
        /* Whether to look up the location. */
        private static bool location;
        /* Whether to update the photographs. */
        private static bool update;
        /* Whether to be quiet. */
        private static bool quiet;
        /* The cities dictionary. */
        private static Gee.TreeMap<int, City> cities;

        /* The option context. */
        private const string CONTEXT =
            _("INPUTDIR OUTPUTDIR - Store images to a normalized location.");

        /* Returns the options. */
        private static GLib.OptionEntry[] get_options()  {
            GLib.OptionEntry[] options = {
                { "location", 'l', 0, GLib.OptionArg.NONE, &location,
                  _("Use location look up"), null },
                { "update", 'u', 0, GLib.OptionArg.NONE, &update,
                  _("Update the metadata of the photograph"), null },
                { "quiet", 'q', 0, GLib.OptionArg.NONE, &quiet,
                  _("Be quiet"), null },
                { null }
            };
            return options;
        }

        /* Loads the cities from the database. */
        private static void load_cities() {
            cities = new Gee.TreeMap<int, City>();
            string[] data_dirs =  GLib.Environment.get_system_data_dirs();
            for (int i = 0; i < data_dirs.length; i++) {
                var path = string.join(GLib.Path.DIR_SEPARATOR_S, data_dirs[i],
                                       Config.PACKAGE_NAME, "cities.csv");
                if (!FileUtils.test(path, FileTest.EXISTS))
                    continue;
                File file = GLib.File.new_for_path(path);
                try {
                    var fin = new GLib.DataInputStream(file.read());
                    string line;
                    while ((line = fin.read_line(null)) != null) {
                        if (line.has_prefix("#"))
                            continue;
                        var fields = line.split(",");
                        if (fields.length != 6) {
                            stderr.printf(_("Invalid city record: %s"), line);
                            continue;
                        }
                        var city = new City(
                            int.parse(fields[CityField.ID]),
                            fields[CityField.NAME],
                            fields[CityField.COUNTRY],
                            int.parse(fields[CityField.POPULATION]),
                            double.parse(fields[CityField.LATITUDE]),
                            double.parse(fields[CityField.LONGITUDE]));
                        cities[city.id] = city;
                    }
                    if (!cities.is_empty)
                        return;
                } catch (GLib.Error e) {
                    stderr.printf(_("An error ocurred while parsing %s"), path);
                }
            }
            stderr.printf(_("Cities database not found"));
        }

        /* Gets the nearest location to a photograph. */
        private static string get_location(Photograph photo) {
            if (cities == null || cities.is_empty)
                return "";
            City c = null;
            double d = double.MAX;
            foreach (var city in cities.values) {
                double nd = Util.distance(city.latitude, city.longitude,
                                          photo.latitude, photo.longitude);
                if (nd > d)
                    continue;
                c = city;
                d = nd;
            }
            return c.name;
        }

        /* Sets the album for a photo. */
        private static void set_album(Photograph photo) {
            if (photo.album != null && photo.album != "")
                return;
            var dt = photo.datetime;
            /* Translators: Month name and day*/
            var r = _("%s %d").printf(dt.format("%A"), dt.get_day_of_month());
            if (location && photo.has_geolocation) {
                var l = get_location(photo);
                r = _("%s, near %s").printf(r, l);
            }
            photo.album = Util.capitalize(r);
        }

        /* Sets the title for a photo. */
        private static void set_title(Photograph photo) {
            if (photo.title != null && photo.title != "")
                return;
            var bn = GLib.Path.get_basename(photo.path);
            photo.title = Util.capitalize(Util.normalize(Util.get_name(bn)));
        }

        /* Makes the directory if necessary. */
        private static void mkdir(string path) throws GLib.Error {
            if (!FileUtils.test(path, FileTest.EXISTS)) {
                var d = File.new_for_path(path);
                d.make_directory();
            }
        }

        /* Stores a photo. */
        private static void store_photo(string path) throws GLib.Error {
            var file = GLib.File.new_for_commandline_arg(path);
            Photograph photo;
            try {
                photo = new Photograph(file);
            } catch (GLib.Error e) {
                if (!quiet) {
                    stderr.printf(_("There was an error processing %s: %s. "),
                                  path, e.message);
                    stderr.printf(_("Skipping.\n"));
                }
                return;
            }
            set_album(photo);
            set_title(photo);
            var dt = photo.datetime;
            var year = "%04d".printf(dt.get_year());
            var month = "%02d".printf(dt.get_month());
            var album = Util.normalize(photo.album);
            var title = Util.normalize_basename(
                GLib.Path.get_basename(photo.path));
            var dest = string.join(GLib.Path.DIR_SEPARATOR_S, output, year);
            mkdir(dest);
            dest = string.join(GLib.Path.DIR_SEPARATOR_S, dest, month);
            mkdir(dest);
            dest = string.join(GLib.Path.DIR_SEPARATOR_S, dest, album);
            mkdir(dest);
            dest = string.join(GLib.Path.DIR_SEPARATOR_S, output, year, month,
                               album, title);
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
                var p = new Photograph(GLib.File.new_for_commandline_arg(dest));
                p.copy_metadata(photo);
                p.save_metadata();
            }
            stderr.printf("%s → %s\n", path, dest);
        }

        /* Stores the photographs. */
        private static void store_photos() throws GLib.Error {
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
                        store_photo(path);
                }
            }
        }

        public static int main(string[] args) {
            GLib.Intl.setlocale(LocaleCategory.ALL, "");
            location = update = quiet = false;
            try {
                var opt = new GLib.OptionContext(CONTEXT);
                opt.set_help_enabled(true);
                opt.add_main_entries(get_options(), null);
                opt.parse(ref args);
            } catch (GLib.Error e) {
                stderr.printf("%s\n", e.message);
                Util.error(_("Run ‘%s --help’ for a list of options"), args[0]);
            }

            if (args.length != 3)
                Util.error(
                    _("Exactly one output and one input directory needed"));

            if (location)
                load_cities();

            input = args[1];
            output = args[2];

            if (!GLib.FileUtils.test(input, GLib.FileTest.IS_DIR))
                Util.error(_("%s is not a directory\n"), input);

            try {
                store_photos();
            } catch (GLib.Error e) {
                Util.error(_("There was an error while storing: %s\n"),
                           e.message);
            }

            return 0;
        }
    }
}
