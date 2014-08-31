/*
 * This file is part of gqpe.
 *
 * Copyright 2013 Canek Peláez Valdés
 *
 * gqpe is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * gqpe is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with gqpq. If not, see <http://www.gnu.org/licenses/>.
 */

namespace GQPE {

    public class Application : Gtk.Application {

        private ApplicationWindow window;
        private Gee.ArrayList<Photograph> photographs;
        private Gee.BidirListIterator<Photograph> iterator;
        private Gee.ListIterator<Photograph> loader;
        private int total;
        private int index;

        public Application() {
            application_id = "mx.unam.GQPE";
            flags |= GLib.ApplicationFlags.HANDLES_OPEN;

            var action = new GLib.SimpleAction("previous", null);
            action.activate.connect(() => previous());
            add_action(action);

            action = new GLib.SimpleAction("next", null);
            action.activate.connect(() => next());
            add_action(action);

            action = new GLib.SimpleAction("rotate-left", null);
            action.activate.connect(() => rotate_left());
            add_action(action);

            action = new GLib.SimpleAction("rotate-right", null);
            action.activate.connect(() => rotate_right());
            add_action(action);

            action = new GLib.SimpleAction("save", null);
            action.activate.connect(() => save());
            add_action(action);

            action = new GLib.SimpleAction("about", null);
            action.activate.connect(() => about());
            add_action(action);

            action = new GLib.SimpleAction("quit", null);
            action.activate.connect(() => quit());
            add_action(action);
        }

        public override void startup() {
            base.startup();

            var nav = new GLib.Menu();
            nav.append(_("Previous picture"), "app.previous");
            nav.append(_("Next picture"), "app.next");

            var pic = new GLib.Menu();
            pic.append(_("Rotate left"), "app.rotate-left");
            pic.append(_("Rotate right"), "app.rotate-right");

            var app = new GLib.Menu();
            app.append(_("Save picture"), "app.save");
            app.append(_("About"), "app.about");
            app.append(_("Quit"), "app.quit");

            var menu = new GLib.Menu();
            menu.append_section(null, nav);
            menu.append_section(null, pic);
            menu.append_section(null, app);
            set_app_menu(menu);
        }

        public override void activate() {
            base.activate();

            if (window == null)
                window = new ApplicationWindow(this);

            if (total == 0) {
                window.next.sensitive = false;
                window.rotate_left.sensitive = false;
                window.rotate_right.sensitive = false;
                window.save.sensitive = false;
                window.caption.sensitive = false;
            } else {
                iterator = photographs.bidir_list_iterator();
                loader = photographs.list_iterator();
                next();
                if (total == 1)
                    window.next.sensitive = false;
                GLib.Idle.add(autoload_photographs);
            }

            window.previous.sensitive = false;
            window.present();
        }

        public override void open(GLib.File[] files, string hint) {
            photographs = new Gee.ArrayList<Photograph>();
            foreach (var file in files) {
                FileInfo info = null;
                try {
                    info = file.query_info("standard::*",
                                           GLib.FileQueryInfoFlags.NONE);
                } catch (GLib.Error e) {
                    var p = file.get_path();
                    var m = "There was a problem getting info from '%s'".printf(p);
                    GLib.warning(m);
                    continue;
                }
                var ctype = info.get_content_type();
                if (ctype != "image/jpeg" && ctype != "image/png") {
                    var p = file.get_path();
                    var m = "The filename '%s' is not a picture".printf(p);
                    GLib.warning(m);
                    continue;
                }
                photographs.add(new Photograph(file));
            }
            photographs.sort();
            total = photographs.size;
            activate();
        }

        private bool autoload_photographs() {
            if (!loader.has_next())
                return false;
            loader.next();
            var photograph = loader.get();
            try {
                photograph.load();
            } catch (GLib.Error e) {
                var p = photograph.file.get_path();
                GLib.warning("There was an error loading '%s'".printf(p));
                loader.remove();
            }
            return true;
        }

        private void disable_picture() {
            window.rotate_left.sensitive = false;
            window.rotate_right.sensitive = false;
            window.save.sensitive = false;
            window.caption.sensitive = false;
        }

        private void update_picture() {
            window.rotate_left.sensitive = true;
            window.rotate_right.sensitive = true;
            window.caption.sensitive = true;
            var photograph = iterator.get();
            try {
                photograph.load();
            } catch (GLib.Error e) {
                var p = photograph.file.get_path();
                GLib.warning("There was an error loading '%s'".printf(p));
                disable_picture();
                return;
            }
            var basename = photograph.file.get_basename();
            var markup = _("<b>%s (%d of %d)</b>").printf(basename, index, total);
            window.label.set_markup(markup);
            window.image.set_from_pixbuf(photograph.pixbuf);
            window.caption.set_text(photograph.caption);
            window.caption.grab_focus();
            window.save.sensitive = false;
        }

        public void previous() {
            if (!iterator.has_previous())
                return;
            iterator.previous();
            index--;
            window.next.sensitive = true;
            if (!iterator.has_previous())
                window.previous.sensitive = false;
            update_picture();
        }

        public void next() {
            if (!iterator.has_next())
                return;
            iterator.next();
            index++;
            window.previous.sensitive = true;
            if (!iterator.has_next())
                window.next.sensitive = false;
            update_picture();
        }

        public void rotate_left() {
            var photograph = iterator.get();
            photograph.rotate_left();
            window.image.set_from_pixbuf(photograph.pixbuf);
            window.save.sensitive = true;
        }

        public void rotate_right() {
            var photograph = iterator.get();
            photograph.rotate_right();
            window.image.set_from_pixbuf(photograph.pixbuf);
            window.save.sensitive = true;
        }

        public void save() {
            var photograph = iterator.get();
            try {
                photograph.save_metadata();
            } catch (GLib.Error e) {
                var f = photograph.file.get_path();
                GLib.warning("There was an error saving the metadata of '%s'".printf(f));
            }
        }

        public void picture_done() {
            if (!window.save.sensitive)
                return;
            save();
            next();
        }

        private void about() {
            string[] authors = { "Canek Peláez Valdés <canek@ciencias.unam.mx>" };
            Gtk.show_about_dialog(
                window,
                "authors", authors,
                "comments", _("A Gtk+ based quick photo editor"),
                "copyright", "Copyright 2013 Canek Peláez Valdés",
                "license-type", Gtk.License.GPL_3_0,
                "logo-icon-name", "gqpe",
                "version", Config.PACKAGE_VERSION,
                "website", "http://github.com/canek-pelaez/gqpe",
                "wrap-license", true);
        }
    }
}
