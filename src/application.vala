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

        private enum Direction {
            LEFT,
            RIGHT
        }

        private ApplicationWindow window;
        private Gee.ArrayList<Photograph> photographs;
        private Gee.BidirListIterator<Photograph> iterator;
        private Gee.ListIterator<Photograph> loader;
        private int total;
        private int index;

        public Application() {
            application_id = "mx.unam.GQPE";
            flags |= GLib.ApplicationFlags.HANDLES_OPEN;

            var action = new GLib.SimpleAction("about", null);
            action.activate.connect(() => about());
            add_action(action);

            action = new GLib.SimpleAction("quit", null);
            action.activate.connect(() => quit());
            add_action(action);
        }

        public override void startup() {
            base.startup();
            var menu = new GLib.Menu();
            menu.append(_("About"), "app.about");
            menu.append(_("Quit"), "app.quit");
            set_app_menu(menu);
        }

        public override void activate() {
            base.activate();

            if (window == null)
                window = new ApplicationWindow(this);

            if (total == 0) {
                window.disable(UIItemFlags.NEXT         |
                               UIItemFlags.ROTATE_LEFT  |
                               UIItemFlags.ROTATE_RIGHT |
                               UIItemFlags.SAVE         |
                               UIItemFlags.CAPTION);
            } else {
                iterator = photographs.bidir_list_iterator();
                loader = photographs.list_iterator();
                next();
                if (total == 1)
                    window.disable(UIItemFlags.NEXT);
                GLib.Idle.add(autoload_photographs);
            }

            window.disable(UIItemFlags.PREVIOUS);
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
            window.disable(UIItemFlags.ROTATE_LEFT  |
                           UIItemFlags.ROTATE_RIGHT |
                           UIItemFlags.SAVE         |
                           UIItemFlags.CAPTION);
        }

        private void update_picture() {
            window.enable(UIItemFlags.ROTATE_LEFT  |
                          UIItemFlags.ROTATE_RIGHT |
                          UIItemFlags.CAPTION);
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
            window.set_filename(basename, index, total);
            window.set_pixbuf(photograph.pixbuf);
            window.set_caption(photograph.caption);
            window.disable(UIItemFlags.SAVE);
        }

        public void previous() {
            if (!iterator.has_previous())
                return;
            iterator.previous();
            index--;
            window.enable(UIItemFlags.NEXT);
            if (!iterator.has_previous())
                window.disable(UIItemFlags.PREVIOUS);
            update_picture();
        }

        public void next() {
            if (!iterator.has_next())
                return;
            iterator.next();
            index++;
            window.enable(UIItemFlags.PREVIOUS);
            if (!iterator.has_next())
                window.disable(UIItemFlags.NEXT);
            update_picture();
        }

        private void rotate(Direction direction) {
            var photograph = iterator.get();
            switch (direction) {
            case Direction.LEFT:
                photograph.rotate_left();
                break;
            case Direction.RIGHT:
                photograph.rotate_right();
                break;
            }
            window.set_pixbuf(photograph.pixbuf);
            window.enable(UIItemFlags.SAVE);
        }

        public void rotate_left() {
            rotate(Direction.LEFT);
        }

        public void rotate_right() {
            rotate(Direction.RIGHT);
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
            if (window.saving_allowed())
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
