/* application.vala
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

    /**
     * Class for the application.
     */
    public class Application : Gtk.Application {

        /* The window. */
        private ApplicationWindow window;

        /**
         * Creates a new application.
         */
        public Application() {
            application_id = "mx.unam.GQPE";
            flags |= GLib.ApplicationFlags.HANDLES_OPEN;
        }

        /**
         * Starts up the application.
         */
        public override void startup() {
            base.startup();

            var action = new GLib.SimpleAction("save", null);
            action.activate.connect(() => window.on_data_activate());
            add_action(action);
            string[] accels = { "<Ctrl>Return" };
            set_accels_for_action("app.save", accels);

            action = new GLib.SimpleAction("about", null);
            action.activate.connect(() => window.about());
            add_action(action);

            action = new GLib.SimpleAction("quit", null);
            action.activate.connect(() => this.quit());
            add_action(action);

            var menu = new GLib.Menu();
            menu.append(_("Save"), "app.save");
            menu.append(_("About"), "app.about");
            menu.append(_("Quit"), "app.quit");
            set_app_menu(menu);
        }

        /**
         * Activates the application.
         */
        public override void activate() {
            base.activate();
            if (window == null)
                window = new ApplicationWindow(this);
            window.present();
        }

        /**
         * Opens files for the application.
         */
        public override void open(GLib.File[] files, string hint) {
            if (window == null)
                window = new ApplicationWindow(this);
            window.open_files(files);
            activate();
        }
    }
}
