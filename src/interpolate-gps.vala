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
     * Interpolate GPS application.
     */
    public class InterpolateGPS {

        /* Wheter to force a range. */
        private static bool range;
        /* Wheter to be verbose. */
        private static bool verbose;

        /* The input directory. */
        private static string input;
        /* The photographs. */
        private static Photograph[] photographs;

        /* The option context. */
        private const string CONTEXT =
            _("INPUT - Interpolate GPS coordinates.");

        /* Returns the options. */
        private static GLib.OptionEntry[] get_options() {
            GLib.OptionEntry[] options = {
                { "range", 'r', 0, GLib.OptionArg.NONE, &range,
                  _("Force a range"), null },
                { "verbose", 'v', 0, GLib.OptionArg.NONE, &verbose,
                  _("Be verbose"), null },
                { null }
            };
            return options;
        }

        /*Loads the photos from the input directory. */
        private static void load_photos() throws GLib.Error {
            stdout.printf(_("Loading photos…\n"));
            int c = 0;
            var root = GLib.File.new_for_path(input);
            Gee.ArrayQueue<File> queue = new Gee.ArrayQueue<File>();
            queue.offer(root);
            var photos = new Gee.TreeSet<Photograph>();
            while (!queue.is_empty) {
                var dir = queue.poll();
                var e = dir.enumerate_children(FileAttribute.STANDARD_NAME, 0);
                FileInfo file_info;
                while ((file_info = e.next_file ()) != null) {
                    var path = string.join(GLib.Path.DIR_SEPARATOR_S,
                                           dir.get_path(),
                                           file_info.get_name());
                    var file = File.new_for_path(path);
                    if (GLib.FileUtils.test(path, GLib.FileTest.IS_DIR)) {
                        queue.offer(file);
                        continue;
                    }
                    try {
                        var photo = new Photograph(file);
                        photos.add(photo);
                        stderr.printf(_("Loaded %d photos…  \r\b"), c++);
                    } catch (GLib.Error e) {
                        var m = _("There was an error processing %s: %s. ");
                        stderr.printf(m, path, e.message);
                        stderr.printf(_("Skipping.\n"));
                    }
                }
            }
            int i = 0;
            photographs = new Photograph[photos.size];
            foreach (var photo in photos)
                photographs[i++] = photo;
            stdout.printf(_("Loaded %d photos…      \n"), c++);
        }

        /* Recursively interpolates the coordinates for a range. */
        private static void interpolate_coordinates(double[] lats,
                                                    double[] lons,
                                                    int a, int b) {
            if (a+1 >= b)
                return;
            int m = (a + b) / 2;
            double lat, lon;
            Util.middle(lats[a], lons[a], lats[b], lons[b], out lat, out lon);
            lats[m] = lat;
            lons[m] = lon;
            interpolate_coordinates(lats, lons, a, m);
            interpolate_coordinates(lats, lons, m, b);
        }

        /* Interpolates the coordinates for a range. */
        private static int interpolate_range(int i, int j) throws GLib.Error {
            var p = photographs[i];
            var q = photographs[j];
            double distance = Util.distance(p.latitude, p.longitude,
                                            q.latitude, q.longitude);
            var difference = p.datetime.difference(q.datetime);
            if (!range && (distance > 1000 || difference > GLib.TimeSpan.DAY))
                return 0;
            int n = j - i - 1;
            int m = 2;
            while (m < n)
                m *= 2;
            m += 2;
            double[] lats = new double[m];
            double[] lons = new double[m];
            lats[0] = p.latitude;
            lons[0] = p.longitude;
            lats[m-1] = q.latitude;
            lons[m-1] = q.longitude;
            interpolate_coordinates(lats, lons, 0, m-1);
            int c = 0;
            for (int x = i+1; x < j; x++) {
                int y = (int)(((double)(x-i)) / n) + 1;
                stderr.printf(_("Updating %s…\n"),
                              photographs[x].path);
                c++;
                photographs[x].set_coordinates(lats[y], lons[y]);
                photographs[x].save_metadata();
            }
            return c;
        }

        /* Interpolates a directory of photos. */
        private static int interpolate_photos() throws GLib.Error {
            load_photos();
            int j = -1;
            bool left = false, middle = false;
            int c = 0;
            for (int i = 0; i < photographs.length; i++) {
                var p = photographs[i];
                if (p.has_geolocation) {
                    if (left && middle) {
                        c += interpolate_range(j, i);
                        j = i;
                        middle = false;
                    } else if (!left) {
                        j = i;
                        left = true;
                    } else {
                        j = i;
                    }
                } else {
                    if (left && !middle) {
                        middle = true;
                    }
                }
            }
            return c;
        }

        public static int main(string[] args) {
            GLib.Intl.setlocale(LocaleCategory.ALL, "");
            verbose = false;
            try {
                var opt = new GLib.OptionContext(CONTEXT);
                opt.set_help_enabled(true);
                opt.add_main_entries(get_options(), null);
                opt.parse(ref args);
            } catch (GLib.Error e) {
                stderr.printf("%s\n", e.message);
                Util.error(_("Run ‘%s --help’ for a list of options"), args[0]);
            }

            if (args.length < 2) {
                Util.error(_("Missing files or directory"));
            } else if (args.length == 2) {
                input = args[1];
                if (!GLib.FileUtils.test(input, GLib.FileTest.IS_DIR))
                    Util.error(_("%s is not a directory"), input);
                try {
                    int c = interpolate_photos();
                    stderr.printf(_("%d photographs updated\n"), c);
                } catch (GLib.Error e) {
                    Util.error(_("There was an error while interpolating: %s"));
                }
            } else {
                photographs = new Photograph[args.length-1];
                int c = 0;
                for (int i = 1; i < args.length; i++) {
                    var file = GLib.File.new_for_path(args[i]);
                    try {
                        photographs[i-1] = new Photograph(file);
                        stderr.printf(_("Loaded %d photos…  \r\b"), c++);
                    } catch (GLib.Error e) {
                        var m = _("There was an error processing %s: %s. ");
                        stderr.printf(m, args[i], e.message);
                        stderr.printf(_("Skipping.\n"));
                    }
                }
                stderr.printf(_("Loaded %d photos…  \n"), c);
                int n = photographs.length;
                if (!photographs[0].has_geolocation ||
                    !photographs[n-1].has_geolocation)
                    Util.error(
                        _("First and last photograph must have GPS data"));
                try {
                    c = interpolate_range(0, n-1);
                } catch (GLib.Error e) {
                    Util.error(
                        _("There was an error while interpolating: %s"));
                }
                stderr.printf(_("%d photographs updated\n"), c);
            }

            return 0;
        }
    }
}
