/* interpolate-gps.vala
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
     * Interpolate GPS application.
     */
    public class InterpolateGPS {

        private static string input;
        private static bool verbose;

        private static Photograph[] photographs;

        /* The options. */
        private static GLib.OptionEntry[] options = {
            { "verbose", 'v', 0, GLib.OptionArg.NONE, &verbose,
              _("Be verbose"), null },
            { null }
        };

        /* The option context. */
        private const string CONTEXT =
            _("INPUTDIR - Interpolate GPS coordinates.");

        private static void load_photos() throws GLib.Error {
            stdout.printf(_("Loading photos...\n"));
            int c = 0;
            var root = File.new_for_path(input);
            Gee.ArrayQueue<File> queue = new Gee.ArrayQueue<File>();
            queue.offer(root);
            var photos = new Gee.TreeSet<Photograph>();
            while (!queue.is_empty) {
                stderr.printf(_("Loaded %d photos...  \r\b"), c++);
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
            stdout.printf(_("Loaded %d photos...      \n"), c++);
        }

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

        private static void interpolate_range(int i, int j) throws GLib.Error {
            var p = photographs[i];
            var q = photographs[j];
            if (Util.distance(p.latitude, p.longitude,
                              q.latitude, q.longitude) > 1000 ||
                p.datetime.difference(q.datetime) > GLib.TimeSpan.DAY)
                return;
            int n = j - i - 1;
            int m = 2;
            while (m < n)
                m *= 2;
            double[] lats = new double[m];
            double[] lons = new double[m];
            lats[0] = p.latitude;
            lons[0] = p.longitude;
            lats[m-1] = q.latitude;
            lons[m-1] = q.longitude;
            interpolate_coordinates(lats, lons, 0, m-1);
            for (int x = i; x <= j; x++) {
                int y = (int)((x-i) * (((double)m) / (j - i + 1))) + 1;
                photographs[y].set_coordinates(lats[y], lons[y]);
            }
        }

        private static void interpolate_photos() throws GLib.Error {
            load_photos();
            int j = -1;
            bool left = false, middle = false;
            for (int i = 0; i < photographs.length; i++) {
                var p = photographs[i];
                if (p.has_geolocation) {
                    if (left && middle) {
                        interpolate_range(j, i);
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
        }

        public static int main(string[] args) {
            GLib.Intl.setlocale(LocaleCategory.ALL, "");
            verbose = false;
            try {
                var opt = new GLib.OptionContext(CONTEXT);
                opt.set_help_enabled(true);
                opt.add_main_entries(options, null);
                opt.parse(ref args);
            } catch (GLib.Error e) {
                stderr.printf("%s\n", e.message);
                stderr.printf(_("Run ‘%s --help’ for a list of options.\n"),
                              args[0]);
                GLib.Process.exit(1);
            }

            if (args.length != 2) {
                stderr.printf(_("Exactly one input directory needed.\n"));
                GLib.Process.exit(1);
            }

            input = args[1];

            if (!GLib.FileUtils.test(input, GLib.FileTest.IS_DIR)) {
                stderr.printf(_("%s is not a directory\n"), input);
                GLib.Process.exit(1);
            }

            try {
                interpolate_photos();
            } catch (GLib.Error e) {
                stderr.printf(_("There was an error while interpolating: %s\n"),
                              e.message);
                GLib.Process.exit(1);
            }

            return 0;
        }
    }
}
