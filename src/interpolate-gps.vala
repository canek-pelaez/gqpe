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

        private static void progress(ProgressState state, int number) {
            switch (state) {
            case INIT:
                stdout.printf(_("Loading photographs…\n"));
                break;
            case ADVANCE:
                stderr.printf(_("Loaded %d photographs…"), number, "\r\b");
                break;
            case END:
                stdout.printf(_("Loaded %d photographs.\n"), number);
                break;
            }
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

        private static void do_interpolating(string[] args) {
            try {
                var photos = (args.length == 2) ?
                    Util.load_photos_dir(args[1], (s, n) => progress(s, n)) :
                    Util.load_photos_array(args, 1, (s, n) => progress(s, n));
                photographs = new Photograph[photos.size];
                int i = 0;
                foreach (var photo in photos)
                    photographs[i++] = photo;
                int c = interpolate_photos();
                stderr.printf(_("%d photographs exported\n"), c);
            } catch (GLib.Error e) {
                Util.error(_("Error while exporting: %s"), e.message);
            }
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

            if (args.length < 2)
                Util.error(_("Missing files or directory"));
            else if (args.length == 2)
                if (!GLib.FileUtils.test(args[1], GLib.FileTest.IS_DIR))
                    Util.error(_("%s is not a directory"), args[1]);
            do_interpolating(args);

            return 0;
        }
    }
}
