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
        private enum Item {
            PREVIOUS     = 1 << 0,
            NEXT         = 1 << 1,
            ROTATE_LEFT  = 1 << 2,
            ROTATE_RIGHT = 1 << 3,
            SAVE         = 1 << 4,
            ALBUM        = 1 << 5,
            CAPTION      = 1 << 6,
            COMMENT      = 1 << 7,
            NAVIGATION   = 0x03,
            PICTURE      = 0xFC,
            ALL          = 0xff
        }

        /* Rotate direction. */
        private enum Rotate {
            LEFT,
            RIGHT
        }

        /* CSS Resource. */
        private static const string CSS = "resource:///mx/unam/GQPE/gqpe.css";
        /* Maximum length for the album. */
        private static const int ALBUM_LENGTH = 50;
        /* Maximum length for the caption. */
        private static const int CAPTION_LENGTH = 40;

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
        /* The image label. */
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
                GLib.warning("There was a problem loading 'gqpe.css': %s",
                             e.message);
            }
            Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(),
                                                     provider, 999);

            GLib.Idle.add(check_entries_length);
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
            enable_ui(Item.NEXT);
            if (!iterator.has_previous())
                disable_ui(Item.PREVIOUS);
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
            enable_ui(Item.PREVIOUS);
            if (!iterator.has_next())
                disable_ui(Item.NEXT);
            update_ui();
        }

        /**
         * Callback for rotate left button clicked.
         */
        [GtkCallback]
        public void on_rotate_left_clicked() {
            rotate(Rotate.LEFT);
        }

        /**
         * Callback for rotate right button clicked.
         */
        [GtkCallback]
        public void on_rotate_right_clicked() {
            rotate(Rotate.RIGHT);
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
                             "metadata of '%s': %s", f, e.message);
            }
            disable_ui(Item.SAVE);
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
            enable_ui(Item.SAVE);
        }

        /**
         * Callback for image resized.
         */
        [GtkCallback]
        public void on_image_resize() {
            double w = image.get_allocated_width();
            double h = image.get_allocated_height();
            if (w <= 0.0 || h <= 0.0)
                return;
            double W = photograph.pixbuf.width;
            double H = photograph.pixbuf.height;
            double s1 = w / W;
            double s2 = h / H;
            if (H * s1 <= h)
                photograph.scale(s1);
            else
                photograph.scale(s2);
            
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
                    GLib.warning("Could not get info from '%s': %s",
                                 file.get_path(), e.message);
                    continue;
                }
                var ctype = info.get_content_type();
                if (ctype != "image/jpeg" && ctype != "image/png") {
                    GLib.warning("The file '%s' is not a picture",
                                 file.get_path());
                    continue;
                }
                photographs.add(new Photograph(file));
            }
            photographs.sort();
        }

        /* Initializes the iterators. */
        private void set_iterators() {
            if (photographs.size == 0) {
                disable_ui(Item.ALL);
            } else {
                iterator = photographs.bidir_list_iterator();
                loader = photographs.list_iterator();
                on_next_clicked();
                if (photographs.size == 1)
                    disable_ui(Item.NEXT);
                GLib.Idle.add(autoload_photographs);
            }
            disable_ui(Item.PREVIOUS);
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
                GLib.warning("Could not load '%s': %s",
                             photograph.file.get_path(), e.message);
                loader.remove();
            }
            return true;
        }

        /* Turns on and off UI items. */
        private void items_set_sensitive(Item items, bool s) {
            if ((items & Item.PREVIOUS) != 0)
                previous.sensitive = s;
            if ((items & Item.NEXT) != 0)
                next.sensitive = s;
            if ((items & Item.ROTATE_LEFT) != 0)
                rotate_left.sensitive = s;
            if ((items & Item.ROTATE_RIGHT) != 0)
                rotate_right.sensitive = s;
            if ((items & Item.SAVE) != 0)
                save.sensitive = s;
            if ((items & Item.ALBUM) != 0)
                album.sensitive = s;
            if ((items & Item.CAPTION) != 0)
                caption.sensitive = s;
            if ((items & Item.COMMENT) != 0)
                comment.sensitive = s;
        }

        /* Turns on UI items. */
        private void enable_ui(Item items) {
            items_set_sensitive(items, true);
        }

        /* Turns off UI items. */
        private void disable_ui(Item items) {
            items_set_sensitive(items, false);
        }

        /* Rotates the photograph. */
        private void rotate(Rotate direction) {
            switch (direction) {
            case Rotate.LEFT:
                photograph.rotate_left();
                break;
            case Rotate.RIGHT:
                photograph.rotate_right();
                break;
            }
            image.set_from_pixbuf(photograph.pixbuf);
            enable_ui(Item.SAVE);
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
                GLib.warning("Could not load '%s': %s",
                             photograph.file.get_path(), e.message);
                disable_ui(Item.PICTURE);
                return;
            }
            image.set_from_pixbuf(photograph.pixbuf);
            enable_ui(Item.PICTURE);
        }

        /* Updates the data. */
        private void update_data() {
            var basename = photograph.file.get_basename();
            var markup = "<b>%s</b>".printf(basename);
            label.set_markup(markup);
            header.subtitle = "%d / %d".printf(index, photographs.size);
            album.text = photograph.album;
            caption.text = photograph.caption;
            check_entries_length();
            comment.buffer.text = photograph.comment;
            caption.grab_focus();
            disable_ui(Item.SAVE);
        }

        /* Checks the length of both entries. */
        private bool check_entries_length() {
            if (save == null || !save.sensitive)
                return true;
            check_entry_length(album, ALBUM_LENGTH);
            check_entry_length(caption, CAPTION_LENGTH);
            return true;
        }

        /* Checks the length of an entry. */
        private void check_entry_length(Gtk.Entry entry, int length) {
            if (entry.text.length > length &&
                entry.secondary_icon_name == null) {
                entry.secondary_icon_name = "dialog-warning-symbolic";
                entry.secondary_icon_tooltip_text = "Entry is too long";
                entry.secondary_icon_activatable = false;
            }
            if (entry.text.length <= length &&
                entry.secondary_icon_name != null) {
                entry.secondary_icon_name = null;
                entry.secondary_icon_tooltip_text = null;
                entry.secondary_icon_activatable = false;
            }
        }
    }
}
