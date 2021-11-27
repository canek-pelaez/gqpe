/* copy.vala
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
     * Copy application.
     */
    public class Copy {

        /* Whether to only copy GPS data. */
        private static bool gps_only;
        /* Whether to exclude GPS data. */
        private static bool exclude_gps;
        /* Whether to exclude date and time data. */
        private static bool exclude_datetime;
        /* The input photograph. */
        private static string input;
        /* The output photograph. */
        private static string output;

        /* The option context. */
        private const string CONTEXT = _("INPUT OUTPUT - Copy the image tags.");

        /* Returns the options. */
        private static GLib.OptionEntry[] get_options() {
            GLib.OptionEntry[] options = {
                { "exclude-gps", 'G', 0, GLib.OptionArg.NONE, &exclude_gps,
                  _("Do not copy GPS data."), null },
                { "exclude-datetime", 'T', 0, GLib.OptionArg.NONE, &exclude_gps,
                  _("Do not copy date and time data."), null },
                { "gps-only", 'g', 0, GLib.OptionArg.NONE, &gps_only,
                  _("Only copy GPS data."), null },
                { null }
            };
            return options;
        }

        private static void copy_tags() throws GLib.Error {
            var i = new Photograph(GLib.File.new_for_commandline_arg(input));
            var o = new Photograph(GLib.File.new_for_commandline_arg(output));
            if (gps_only)
                o.copy_gps_data(i);
            else
                o.copy_metadata(i, exclude_gps, exclude_datetime);
            o.save_metadata();
        }

        public static int main(string[] args) {
            gps_only = exclude_gps = exclude_datetime = false;
            GLib.Intl.setlocale(LocaleCategory.ALL, "");
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
                Util.error(_("Exactly one input and one output file needed"));

            if (gps_only) {
                if (exclude_gps)
                    Util.error(_("You cannot mix -g and -G"));
                if (exclude_datetime)
                    Util.error(_("You cannot mix -g and -T"));
            }

            input = args[1];
            output = args[2];

            try {
                copy_tags();
            } catch (GLib.Error e) {
                stderr.printf(_("An error ocurred while copying %s:"),
                              e.message);
            }

            return 0;
        }
    }
}
