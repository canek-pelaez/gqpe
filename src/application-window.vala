/* application-window.vala
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

    [GtkTemplate (ui = "/mx/unam/GQPE/gqpe.ui")]
    public class ApplicationWindow : Gtk.ApplicationWindow {

        private enum UIItemFlags {
            PREVIOUS     = 1 << 0,
            NEXT         = 1 << 1,
            ROTATE_LEFT  = 1 << 2,
            ROTATE_RIGHT = 1 << 3,
            SAVE         = 1 << 4,
            ALBUM        = 1 << 5,
            CAPTION      = 1 << 6,
            COMMENT      = 1 << 7,
            NAVIGATION   = 0x03,
            PICTURE      = 0xF6,
            ALL          = 0x3f
        }

        private enum Direction {
            LEFT,
            RIGHT
        }

        private static const string RESOURCE =
            "resource:///mx/unam/GQPE/gqpe.css";

        [GtkChild]
        private Gtk.HeaderBar header;
        [GtkChild]
        private Gtk.Button previous;
        [GtkChild]
        private Gtk.Button next;
        [GtkChild]
        private Gtk.Button rotate_left;
        [GtkChild]
        private Gtk.Button rotate_right;
        [GtkChild]
        private Gtk.Button save;
        [GtkChild]
        private Gtk.Label label;
        [GtkChild]
        private Gtk.Image image;
        [GtkChild]
        private Gtk.Entry album;
        [GtkChild]
        private Gtk.Entry caption;
        [GtkChild]
        private Gtk.TextView comment;

        private Photograph photograph;
        private Gee.ListIterator<Photograph> loader;
        private Gee.ArrayList<Photograph> photographs;
        private Gee.BidirListIterator<Photograph> iterator;
        private int total;
        private int index;

        public ApplicationWindow(Gtk.Application application) {
            GLib.Object(application: application);

            Gtk.Window.set_default_icon_name("gqpe");
            var provider = new Gtk.CssProvider();
            try {
                var file = GLib.File.new_for_uri(RESOURCE);
                provider.load_from_file(file);
            } catch (GLib.Error e) {
                GLib.warning("There was a problem loading 'gqpe.css'");
            }
            Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(),
                                                      provider, 999);
        }

        [GtkCallback]
        public void on_window_destroy() {
            application.quit();
        }

        [GtkCallback]
        public void on_previous_clicked() {
            if (!iterator.has_previous())
                return;
            iterator.previous();
            index--;
            enable_ui(UIItemFlags.NEXT);
            if (!iterator.has_previous())
                disable_ui(UIItemFlags.PREVIOUS);
            update_picture();
        }

        [GtkCallback]
        public void on_next_clicked() {
            if (!iterator.has_next())
                return;
            iterator.next();
            index++;
            enable_ui(UIItemFlags.PREVIOUS);
            if (!iterator.has_next())
                disable_ui(UIItemFlags.NEXT);
            update_picture();
        }

        [GtkCallback]
        public void on_rotate_left_clicked() {
            rotate(Direction.LEFT);
        }

        [GtkCallback]
        public void on_rotate_right_clicked() {
            rotate(Direction.RIGHT);
        }

        [GtkCallback]
        public void on_save_clicked() {
            try {
                photograph.album = album.text;
                photograph.caption = caption.text;
                photograph.comment = comment.buffer.text;
                photograph.save_metadata();
            } catch (GLib.Error e) {
                var f = photograph.file.get_path();
                GLib.warning("There was an error saving the " +
                             "metadata of '%s'".printf(f));
            }
            save.sensitive = false;
        }

        [GtkCallback]
        public void on_data_activate() {
            if (save.sensitive)
                on_save_clicked();
            on_next_clicked();
        }

        [GtkCallback]
        public void on_data_changed() {
            save.sensitive = true;
        }

        [GtkCallback]
        public bool on_window_key_press(Gdk.EventKey e) {
            if (e.keyval == Gdk.Key.bracketleft) {
                on_rotate_left_clicked();
                return true;
            }
            if (e.keyval == Gdk.Key.bracketright) {
                on_rotate_right_clicked();
                return true;
            }
            if (e.keyval == Gdk.Key.Page_Up) {
                on_previous_clicked();
                return true;
            }
            if (e.keyval == Gdk.Key.Page_Down) {
                on_next_clicked();
                return true;
            }
            if (e.keyval == Gdk.Key.Escape) {
                application.quit();
                return true;
            }
            return false;
        }

        public void open_files(GLib.File[] files) {
            load_photographs(files);
            set_iterators();
        }

        private void load_photographs(GLib.File[] files) {
            photographs = new Gee.ArrayList<Photograph>();
            foreach (var file in files) {
                FileInfo info = null;
                try {
                    info = file.query_info("standard::*",
                                           GLib.FileQueryInfoFlags.NONE);
                } catch (GLib.Error e) {
                    var p = file.get_path();
                    var m = "Could not get info from '%s'".printf(p);
                    GLib.warning(m);
                    continue;
                }
                var ctype = info.get_content_type();
                if (ctype != "image/jpeg" && ctype != "image/png") {
                    var p = file.get_path();
                    var m = "The file '%s' is not a picture".printf(p);
                    GLib.warning(m);
                    continue;
                }
                photographs.add(new Photograph(file));
            }
            photographs.sort();
            total = photographs.size;
        }

        private void set_iterators() {
            if (total == 0) {
                disable_ui(UIItemFlags.ALL);
            } else {
                iterator = photographs.bidir_list_iterator();
                loader = photographs.list_iterator();
                on_next_clicked();
                if (total == 1)
                    disable_ui(UIItemFlags.NEXT);
                GLib.Idle.add(autoload_photographs);
            }
            disable_ui(UIItemFlags.PREVIOUS);
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
                GLib.warning("Could not load '%s'".printf(p));
                loader.remove();
            }
            return true;
        }

        private void items_set_sensitive(UIItemFlags flags, bool s) {
            if ((flags & UIItemFlags.PREVIOUS) != 0)
                previous.sensitive = s;
            if ((flags & UIItemFlags.NEXT) != 0)
                next.sensitive = s;
            if ((flags & UIItemFlags.ROTATE_LEFT) != 0)
                rotate_left.sensitive = s;
            if ((flags & UIItemFlags.ROTATE_RIGHT) != 0)
                rotate_right.sensitive = s;
            if ((flags & UIItemFlags.SAVE) != 0)
                save.sensitive = s;
            if ((flags & UIItemFlags.CAPTION) != 0) {
                caption.sensitive = s;
                comment.sensitive = s;
            }
        }

        private void enable_ui(UIItemFlags flags) {
            items_set_sensitive(flags, true);
        }

        private void disable_ui(UIItemFlags flags) {
            items_set_sensitive(flags, false);
        }

        private void rotate(Direction direction) {
            switch (direction) {
            case Direction.LEFT:
                photograph.rotate_left();
                break;
            case Direction.RIGHT:
                photograph.rotate_right();
                break;
            }
            image.set_from_pixbuf(photograph.pixbuf);
            enable_ui(UIItemFlags.SAVE);
        }

        private void update_picture() {
            photograph = iterator.get();
            try {
                photograph.load();
            } catch (GLib.Error e) {
                var p = photograph.file.get_path();
                GLib.warning("Could not load '%s'".printf(p));
                disable_ui(UIItemFlags.PICTURE);
            }
            new_photograph();
            enable_ui(UIItemFlags.PICTURE);
        }

        private void new_photograph() {
            var basename = photograph.file.get_basename();
            var markup = "<b>%s</b>".printf(basename);
            label.set_markup(markup);
            header.subtitle = "%d / %d".printf(index, total);
            image.set_from_pixbuf(photograph.pixbuf);
            album.text = photograph.album;
            caption.text = photograph.caption;
            comment.buffer.text = photograph.comment;
            caption.grab_focus();
            disable_ui(UIItemFlags.SAVE);
        }
    }
}
