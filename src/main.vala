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

    public class Main {

        private static string UI = GLib.Path.build_filename(Config.PKGDATADIR, "gqpe.ui");

        private Gtk.Window window;
        private Gtk.Button previous;
        private Gtk.Button next;
        private Gtk.Button rotate_left;
        private Gtk.Button rotate_right;
        private Gtk.Button save;
        private Gtk.Frame frame;
        private Gtk.Label label;
        private Gtk.Image image;
        private Gtk.Entry entry;

        private Gee.ArrayList<Photograph> photographs;
        private Gee.BidirListIterator<Photograph> iterator;
        private Gee.ListIterator<Photograph> loader;
        private int total;
        private int index;

        public Main(Gee.ArrayList<Photograph> photographs) {
            this.photographs = photographs;
            total = photographs.size;

            var builder = new Gtk.Builder();
            try {
                builder.add_from_file(UI);
            } catch (GLib.Error e) {
                GLib.error("Could not open UI file %s", UI);
            }

            window = builder.get_object("window") as Gtk.Window;
            window.destroy.connect(Gtk.main_quit);
            window.key_press_event.connect((k) => { return key_pressed(k); });

            previous = builder.get_object("previous") as Gtk.Button;
            previous.clicked.connect(() => { move_to_previous(); });
            next = builder.get_object("next") as Gtk.Button;
            next.clicked.connect(() => { move_to_next(); });
            rotate_left = builder.get_object("rotate_left") as Gtk.Button;
            rotate_left.clicked.connect(() => { rotate_photograph_left(); });
            rotate_right = builder.get_object("rotate_right") as Gtk.Button;
            rotate_right.clicked.connect(() => { rotate_photograph_right(); });
            save = builder.get_object("save") as Gtk.Button;
            save.clicked.connect(() => { save_photograph_metadata(); });

            frame = builder.get_object("frame") as Gtk.Frame;
            label = builder.get_object("label") as Gtk.Label;
            image = builder.get_object("image") as Gtk.Image;
            entry = builder.get_object("entry") as Gtk.Entry;
            entry.activate.connect(() => { picture_done(); });
            entry.changed.connect(() => { save.sensitive = true; });
        }

        public void start() {
            previous.sensitive = false;
            if (total == 0) {
                next.sensitive = false;
                rotate_left.sensitive = rotate_right.sensitive = false;
                save.sensitive = entry.sensitive = false;
            } else {
                iterator = photographs.bidir_list_iterator();
                loader = photographs.list_iterator();
                move_to_next();
                if (total == 1)
                    next.sensitive = false;
            }
            GLib.Idle.add(autoload_photographs);
            window.show_all();
        }

        private bool autoload_photographs() {
            if (!loader.has_next())
                return false;
            loader.next();
            var photograph = loader.get();
            photograph.load();
            return true;
        }

        private bool key_pressed(Gdk.EventKey e) {
            if (total == 0)
                return false;
            if (e.keyval == Gdk.Key.Left &&
                (e.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                rotate_photograph_left();
                return true;
            }
            if (e.keyval == Gdk.Key.Right &&
                (e.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                rotate_photograph_right();
                return true;
            }
            if (e.keyval == Gdk.Key.Page_Down) {
                move_to_next();
                return true;
            }
            if (e.keyval == Gdk.Key.Page_Up) {
                move_to_previous();
                return true;
            }
            if (e.keyval == Gdk.Key.Escape) {
                Gtk.main_quit();
                return true;
            }
            return false;
        }

        private void update_picture() {
            var photograph = iterator.get();
            var basename = File.new_for_path(photograph.filename).get_basename();
            label.set_markup(_("<b>%s (%d of %d)</b>").printf(basename, index, total));
            photograph.load();
            image.set_from_pixbuf(photograph.pixbuf);
            entry.set_text(photograph.caption);
            entry.grab_focus();
            save.sensitive = false;
        }

        private void move_to_previous() {
            if (!iterator.has_previous())
                return;
            iterator.previous();
            index--;
            next.sensitive = true;
            if (!iterator.has_previous())
                previous.sensitive = false;
            update_picture();
        }

        private void move_to_next() {
            if (!iterator.has_next())
                return;
            iterator.next();
            index++;
            previous.sensitive = true;
            if (!iterator.has_next())
                next.sensitive = false;
            update_picture();
        }

        private void rotate_photograph_left() {
            var photograph = iterator.get();
            photograph.rotate_left();
            image.set_from_pixbuf(photograph.pixbuf);
        }

        private void rotate_photograph_right() {
            var photograph = iterator.get();
            photograph.rotate_right();
            image.set_from_pixbuf(photograph.pixbuf);
        }

        private void save_photograph_metadata() {
            var photograph = iterator.get();
            photograph.save_metadata();
        }

        private void picture_done() {
            if (!save.sensitive)
                return;
            save_photograph_metadata();
            move_to_next();
        }
    }

    int main(string[] args) {
        Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain(Config.GETTEXT_PACKAGE);

        Gtk.init(ref args);

        Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;

        var photographs = new Gee.ArrayList<Photograph>();
        foreach (var filename in args[1:args.length]) {
            if (!GLib.FileUtils.test(filename, GLib.FileTest.EXISTS)) {
                GLib.warning("The filename '%s' does not exists".printf(filename));
                continue;
            }
            var file = GLib.File.new_for_path(filename);
            var info = file.query_info("standard::*", GLib.FileQueryInfoFlags.NONE);
            var ctype = info.get_content_type();
            if (ctype != "image/jpeg" && ctype != "image/png") {
                GLib.warning("The filename '%s' is not a picture".printf(filename));
                continue;
            }
            photographs.add(new Photograph(filename));
        }
        photographs.sort();

        var gqpe = new Main(photographs);
        gqpe.start();

        Gtk.main();

        return 0;
    }
}
