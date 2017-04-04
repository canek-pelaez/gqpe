/* application-main.vala
 *
 * This file is part of gqpe.
 *
 * Copyright 2017 Canek Peláez Valdés
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
     * Class for the main entry point for the program.
     */
    public class ApplicationMain {

        /**
         * Main entry point for the program.
         * @param args the program command line arguments.
         */
        public static int main(string[] args) {
            Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
            Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain(Config.GETTEXT_PACKAGE);
            GLib.Environment.set_application_name("GQPE");
            Gtk.init(ref args);

            var settings = Gtk.Settings.get_default();
            settings.gtk_application_prefer_dark_theme = true;

            var gqpe = new Application();
            return gqpe.run(args);
        }
    }
}
