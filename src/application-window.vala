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

    /**
     * Class for the application window.
     */
    [GtkTemplate (ui = "/mx/unam/GQPE/gqpe.ui")]
    public class ApplicationWindow : Gtk.ApplicationWindow {

        /* UI items. */
        private enum Items {
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

        /* Directions. */
        private enum Direction {
            LEFT,
            RIGHT
        }

        /* CSS Resource. */
        private static const string CSS = "resource:///mx/unam/GQPE/gqpe.css";

        /* The head bar. */
        [GtkChild]
        private Gtk.HeaderBar header;
        /* The previous button. */
        [GtkChild]
        private Gtk.Button previous;
        /* The next button. */
        [GtkChild]
        private Gtk.Button next;
        /* The rotate left button. */
        [GtkChild]
        private Gtk.Button rotate_left;
        /* The rotate right button. */
        [GtkChild]
        private Gtk.Button rotate_right;
        /* The save button. */
        [GtkChild]
        private Gtk.Button save;
        /* The label button. */
        [GtkChild]
        private Gtk.Label label;
        /* The image. */
        [GtkChild]
        private Gtk.Image image;
        /* The album entry. */
        [GtkChild]
        private Gtk.Entry album;
        /* The caption entry. */
        [GtkChild]
        private Gtk.Entry caption;
        /* The comment text view. */
        [GtkChild]
        private Gtk.TextView comment;

        /* The current photograph. */
        private Photograph photograph;
        /* Photograph list. */
        private Gee.ArrayList<Photograph> photographs;
        /* Loader iterator. */
        private Gee.ListIterator<Photograph> loader;
        /* Photograp iterator. */
        private Gee.BidirListIterator<Photograph> iterator;
        /* The index of the current photograph. */
        private int index;

        /**
         * Constructs a new application window.
         * @param application the application.
         */
        public ApplicationWindow(Gtk.Application application) {
            GLib.Object(application: application);

            Gtk.Window.set_default_icon_name("gqpe");
            var provider = new Gtk.CssProvider();
            try {
                var file = GLib.File.new_for_uri(CSS);
                provider.load_from_file(file);
            } catch (GLib.Error e) {
                GLib.warning("There was a problem loading 'gqpe.css'");
            }
            Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(),
                                                      provider, 999);
        }

        /**
         * Callback for window destruction.
         */
        [GtkCallback]
        public void on_window_destroy() {
            application.quit();
        }

        /**
         * Callback for previous button clicked.
         */
        [GtkCallback]
        public void on_previous_clicked() {
            if (!iterator.has_previous())
                return;
            iterator.previous();
            index--;
            enable_ui(Items.NEXT);
            if (!iterator.has_previous())
                disable_ui(Items.PREVIOUS);
            update_ui();
        }

        /**
         * Callback for next button clicked.
         */
        [GtkCallback]
        public void on_next_clicked() {
            if (!iterator.has_next())
                return;
            iterator.next();
            index++;
            enable_ui(Items.PREVIOUS);
            if (!iterator.has_next())
                disable_ui(Items.NEXT);
            update_ui();
        }

        /**
         * Callback for rotate left button clicked.
         */
        [GtkCallback]
        public void on_rotate_left_clicked() {
            rotate(Direction.LEFT);
        }

        /**
         * Callback for rotate right button clicked.
         */
        [GtkCallback]
        public void on_rotate_right_clicked() {
            rotate(Direction.RIGHT);
        }

        /**
         * Callback for save button clicked.
         */
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

        /**
         * Callback for any entry activation.
         */
        [GtkCallback]
        public void on_data_activate() {
            if (save.sensitive)
                on_save_clicked();
            on_next_clicked();
        }

        /**
         * Callback for any data changed.
         */
        [GtkCallback]
        public void on_data_changed() {
            save.sensitive = true;
        }

        /**
         * Callback for window key presses.
         */
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

        /**
         * Opens an array of files.
         * @param files the array of files.
         */
        public void open_files(GLib.File[] files) {
            load_photographs(files);
            set_iterators();
        }

        /**
         * Shows the about dialog.
         */
        public void about() {
            string[] authors = {
                "Canek Peláez Valdés <canek@ciencias.unam.mx>"
            };
            Gtk.show_about_dialog(
                this,
                "authors",        authors,
                "comments",       _("A Gtk+ based quick photo editor"),
                "copyright",      "Copyright © 2013-2017 Canek Peláez Valdés",
                "license-type",   Gtk.License.GPL_3_0,
                "logo-icon-name", "gqpe",
                "version",        Config.PACKAGE_VERSION,
                "website",        "http://github.com/canek-pelaez/gqpe",
                "wrap-license",   true);
        }

        /* Loads the photograps. */
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
        }

        /* Initializes the iterators. */
        private void set_iterators() {
            if (photographs.size == 0) {
                disable_ui(Items.ALL);
            } else {
                iterator = photographs.bidir_list_iterator();
                loader = photographs.list_iterator();
                on_next_clicked();
                if (photographs.size == 1)
                    disable_ui(Items.NEXT);
                GLib.Idle.add(autoload_photographs);
            }
            disable_ui(Items.PREVIOUS);
        }

        /* Autoloads the photographs asynchronously. */
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

        /* Turns on and off UI items. */
        private void items_set_sensitive(Items flags, bool s) {
            if ((flags & Items.PREVIOUS) != 0)
                previous.sensitive = s;
            if ((flags & Items.NEXT) != 0)
                next.sensitive = s;
            if ((flags & Items.ROTATE_LEFT) != 0)
                rotate_left.sensitive = s;
            if ((flags & Items.ROTATE_RIGHT) != 0)
                rotate_right.sensitive = s;
            if ((flags & Items.SAVE) != 0)
                save.sensitive = s;
            if ((flags & Items.CAPTION) != 0) {
                caption.sensitive = s;
                comment.sensitive = s;
            }
        }

        /* Turns on UI items. */
        private void enable_ui(Items flags) {
            items_set_sensitive(flags, true);
        }

        /* Turns off UI items. */
        private void disable_ui(Items flags) {
            items_set_sensitive(flags, false);
        }

        /* Rotates the photograph. */
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
            enable_ui(Items.SAVE);
        }

        /* Updates the UI. */
        private void update_ui() {
            update_picture();
            update_data();
        }

        /* Updates the picture. */
        private void update_picture() {
            photograph = iterator.get();
            try {
                photograph.load();
            } catch (GLib.Error e) {
                var p = photograph.file.get_path();
                GLib.warning("Could not load '%s'".printf(p));
                disable_ui(Items.PICTURE);
            }
            enable_ui(Items.PICTURE);
        }

        /* Updates the data. */
        private void update_data() {
            var basename = photograph.file.get_basename();
            var markup = "<b>%s</b>".printf(basename);
            label.set_markup(markup);
            header.subtitle = "%d / %d".printf(index, photographs.size);
            image.set_from_pixbuf(photograph.pixbuf);
            album.text = photograph.album;
            caption.text = photograph.caption;
            comment.buffer.text = photograph.comment;
            caption.grab_focus();
            disable_ui(Items.SAVE);
        }
    }
}
