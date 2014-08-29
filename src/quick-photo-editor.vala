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
 * along with gqpq.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace GQPE {

    public class Main {

        private Gtk.Window window;
        private Gtk.Frame frame;
        private Gtk.Button previous;
        private Gtk.Button next;
        private Gtk.Button rotate_left;
        private Gtk.Button rotate_right;
        private Gtk.Button save;
        private PhotoImage image;
        private Gtk.Entry entry;

        private Gee.ArrayList<string> filenames;
        private Gee.BidirListIterator<string> iterator;
        private int total;
        private int index;

        public Main(Gee.ArrayList<string> filenames) {
            this.filenames = filenames;
            total = filenames.size;

            window = new Gtk.Window();
            window.window_position = Gtk.WindowPosition.CENTER_ALWAYS;
            window.destroy.connect(Gtk.main_quit);
            window.key_press_event.connect((k) => { return key_pressed(k); });

            window.set_titlebar(create_headerbar());
            window.add(create_main_area());
        }

        private Gtk.Box create_main_area() {
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 6);
            box.margin = 6;

            frame = new Gtk.Frame("");
            frame.shadow_type = Gtk.ShadowType.ETCHED_OUT;
            box.pack_start(frame, true, true);

            image = new PhotoImage();
            image.margin = 6;
            image.set_size_request(500, 375);
            frame.add(image);

            var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
            box.pack_start(sep, false, false);

            entry = new Gtk.Entry();
            entry.activate.connect(() => { picture_done(); });
            entry.changed.connect(() => { save.sensitive = true; });
            box.pack_start(entry, false, false);

            return box;
        }

        private Gtk.HeaderBar create_headerbar() {
            var header = new Gtk.HeaderBar();
            header.title = "Quick Photo Editor";
            header.show_close_button = true;
            header.spacing = 6;

            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.get_style_context().add_class("linked");
            header.pack_start(box);

            previous = new Gtk.Button.from_icon_name("go-previous-symbolic",
                                                 Gtk.IconSize.SMALL_TOOLBAR);
            previous.clicked.connect(() => { move_to_previous(); });
            box.pack_start(previous);
            next = new Gtk.Button.from_icon_name("go-next-symbolic",
                                                 Gtk.IconSize.SMALL_TOOLBAR);
            next.clicked.connect(() => { move_to_next(); });
            box.pack_start(next);

            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.get_style_context().add_class("linked");
            header.pack_start(box);

            rotate_left = new Gtk.Button.from_icon_name("object-rotate-left-symbolic",
                                                        Gtk.IconSize.SMALL_TOOLBAR);
            rotate_left.clicked.connect(() => { image.rotate_left(); });
            box.pack_start(rotate_left);
            rotate_right = new Gtk.Button.from_icon_name("object-rotate-right-symbolic",
                                                         Gtk.IconSize.SMALL_TOOLBAR);
            rotate_right.clicked.connect(() => { image.rotate_right(); });
            box.pack_start(rotate_right);

            save = new Gtk.Button.from_icon_name("document-save-symbolic",
                                                 Gtk.IconSize.SMALL_TOOLBAR);
            save.clicked.connect(() => { image.save_metadata(); });
            header.pack_end(save);

            return header;
        }

        public void start() {
            previous.sensitive = false;
            if (total == 0) {
                next.sensitive = false;
                rotate_left.sensitive = rotate_right.sensitive = false;
                save.sensitive = entry.sensitive = false;
            } else {
                iterator = filenames.bidir_list_iterator();
                move_to_next();
                if (total == 1)
                    next.sensitive = false;
            }
            window.show_all();
        }

        private bool key_pressed(Gdk.EventKey e) {
            if (total == 0)
                return false;
            if (e.keyval == Gdk.Key.Left &&
                (e.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                image.rotate_left();
                return true;
            }
            if (e.keyval == Gdk.Key.Right &&
                (e.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                image.rotate_right();
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
            string filename = iterator.get();
            string basename = File.new_for_path(filename).get_basename();
            var label = (Gtk.Label)frame.label_widget;
            label.set_markup(_("<b>%s (%d of %d)</b>").printf(basename, index, total));
            image.update_filename(filename);
            entry.set_text(image.caption);
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

        private void picture_done() {
            if (!save.sensitive)
                return;
            image.save_metadata();
            move_to_next();
        }
    }

    int main(string[] args) {
        Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain(Config.GETTEXT_PACKAGE);

        Gtk.init(ref args);

        Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;

        var filenames = new Gee.ArrayList<string>();
        foreach (var arg in args[1:args.length])
            filenames.add(arg);
        filenames.sort();

        var gqpe = new Main(filenames);
        gqpe.start();

        Gtk.main();

        return 0;
    }
}
