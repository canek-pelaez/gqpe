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

    public class Application : Gtk.Application {

        private ApplicationWindow window;

        public Application() {
            application_id = "mx.unam.GQPE";
            flags |= GLib.ApplicationFlags.HANDLES_OPEN;
        }

        public override void startup() {
            base.startup();

            var action = new GLib.SimpleAction("save", null);
            action.activate.connect(save);
            add_action(action);
            string[] accels = { "<Ctrl>Return" };
            set_accels_for_action("app.save", accels);

            action = new GLib.SimpleAction("about", null);
            action.activate.connect(about);
            add_action(action);

            action = new GLib.SimpleAction("quit", null);
            action.activate.connect(quit);
            add_action(action);

            var menu = new GLib.Menu();
            menu.append(_("Save"), "app.save");
            menu.append(_("About"), "app.about");
            menu.append(_("Quit"), "app.quit");
            set_app_menu(menu);
        }

        public override void activate() {
            base.activate();
            if (window == null)
                window = new ApplicationWindow(this);
            window.present();
        }

        public override void open(GLib.File[] files, string hint) {
            if (window == null)
                window = new ApplicationWindow(this);
            window.open_files(files);
            activate();
        }

        private void save() {
            window.on_data_activate();
        }

        private void about() {
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
                "website",        "http://github.com/canek-pelaez/gqpe",
                "wrap-license",   true);
        }
    }
}
