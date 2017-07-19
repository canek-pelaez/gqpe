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

        /* The application menu. */
        private const string MENU = "/mx/unam/GQPE/application-menu.ui";

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

            var action = new GLib.SimpleAction("prev", null);
            action.activate.connect(window.on_previous_clicked);
            add_action(action);
            string[] accels = { "Page_Up" };
            set_accels_for_action("app.prev", accels);

            action = new GLib.SimpleAction("next", null);
            action.activate.connect(window.on_next_clicked);
            add_action(action);
            accels = { "Page_Down" };
            set_accels_for_action("app.next", accels);

            action = new GLib.SimpleAction("rotate-left", null);
            action.activate.connect(window.on_rotate_left_clicked);
            add_action(action);
            accels = { "bracketleft" };
            set_accels_for_action("app.rotate-left", accels);

            action = new GLib.SimpleAction("rotate-right", null);
            action.activate.connect(window.on_rotate_right_clicked);
            add_action(action);
            accels = { "bracketright" };
            set_accels_for_action("app.rotate-right", accels);

            action = new GLib.SimpleAction("zoom-in", null);
            action.activate.connect(window.on_zoom_in_clicked);
            add_action(action);
            accels = { "<Ctrl>KP_Add" };
            set_accels_for_action("app.zoom-in", accels);

            action = new GLib.SimpleAction("zoom-out", null);
            action.activate.connect(window.on_zoom_out_clicked);
            add_action(action);
            accels = { "<Ctrl>KP_Subtract" };
            set_accels_for_action("app.zoom-out", accels);

            action = new GLib.SimpleAction("zoom-fit", null);
            action.activate.connect(window.on_zoom_fit_clicked);
            add_action(action);
            accels = { "<Ctrl>KP_Multiply" };
            set_accels_for_action("app.zoom-fit", accels);

            action = new GLib.SimpleAction("save", null);
            action.activate.connect(window.on_data_activated);
            add_action(action);
            accels = { "<Ctrl>Return" };
            set_accels_for_action("app.save", accels);

            action = new GLib.SimpleAction("about", null);
            action.activate.connect(about);
            add_action(action);

            action = new GLib.SimpleAction("quit", null);
            action.activate.connect(quit);
            add_action(action);
            accels = { "<Ctrl>Q", "Escape" };
            set_accels_for_action("app.quit", accels);

            var builder = new Gtk.Builder.from_resource(MENU);
            var menu = builder.get_object("menu") as GLib.MenuModel;

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
         * @param files the array of files to open.
         * @param hint the hing.
         */
        public override void open(GLib.File[] files, string hint) {
            if (window == null)
                window = new ApplicationWindow(this);
            window.open_files(files);
            activate();
        }

        /**
         * Shows the about dialog.
         */
        public void about() {
            string[] authors = {
                "Canek Peláez Valdés <canek@ciencias.unam.mx>"
            };
            Gtk.show_about_dialog(
                window,
                "authors",        authors,
                "comments",       _("A Gtk+ based quick photo editor"),
                "copyright",      "Copyright © 2013-2017 Canek Peláez Valdés",
                "license-type",   Gtk.License.GPL_3_0,
                "logo-icon-name", "gqpe",
                "version",        Config.PACKAGE_VERSION,
                "website",        ("https://canek@aztlan.fciencias.unam.mx/" +
                                   "gitlab/canek/gqpe.git"),
                "wrap-license",   true);
        }
    }
}
