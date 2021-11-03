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

    public class Tags {

        private static int shift_time;

        private const GLib.OptionEntry[] options = {
            { "shift-time", 's', 0, GLib.OptionArg.INT, ref shift_time,
              "Shift the time in this amount ofhours", "HOURS" },
            { null }
        };

        private const string CONTEXT =
            "[FILENAME...] - Edit and show the image tags";

        private const string DESCRIPTION =
            """With no flags the tags are printed.""";

        private static void handle_tag(string path) {
            // if (!FileUtils.test(path, FileTest.EXISTS)) {
            //     stderr.printf("No such file: ‘%s’", path);
            //     return;
            // }
            // var file = GLib.File.new_for_commandline_arg(path);
            // Photograph photo = null;
            // try {
            //     photo = new Photograph(file);
            // } catch (GLib.Error e) {
            //     stderr.printf("Error loading: ‘%s’", path);
            //     return;
            // }
        }

        public static int main(string[] args) {
            shift_time = int.MAX;

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

            for (int i = 1; i < args.length; i++)
                handle_tag(args[i]);

            return 0;
        }
    }
}
