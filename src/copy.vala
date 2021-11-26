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

        /* The input photograph. */
        private static string input;
        /* The output photograph. */
        private static string output;

        /* The option context. */
        private const string CONTEXT = _("INPUT OUTPUT - Copy the image tags.");

        public static int main(string[] args) {
            GLib.Intl.setlocale(LocaleCategory.ALL, "");
            try {
                var opt = new GLib.OptionContext(CONTEXT);
                opt.set_help_enabled(true);
                opt.parse(ref args);
            } catch (GLib.Error e) {
                stderr.printf("%s\n", e.message);
                stderr.printf(_("Run ‘%s --help’ for a list of options.\n"),
                              args[0]);
                GLib.Process.exit(1);
            }

            if (args.length != 3) {
                string m;
                m = _("Exactly one input and one output file needed.\n");
                stderr.printf(m);
                GLib.Process.exit(1);
            }

            input = args[1];
            output = args[2];

            try {
                var pin =
                    new Photograph(GLib.File.new_for_commandline_arg(input));
                var pout =
                    new Photograph(GLib.File.new_for_commandline_arg(output));
                pout.copy_metadata(pin);
                pout.save_metadata();
            } catch (GLib.Error e) {
                stderr.printf(_("An error ocurred while copying %s:"),
                              e.message);
            }

            return 0;
        }
    }
}
