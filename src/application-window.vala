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
            ZOOM_IN      = 1 << 4,
            ZOOM_OUT     = 1 << 5,
            ZOOM_FIT     = 1 << 6,
            GEOLOCATION  = 1 << 7,
            SAVE         = 1 << 8,
            ALBUM        = 1 << 9,
            CAPTION      = 1 << 10,
            COMMENT      = 1 << 11,
            NAVIGATION   = 0x003,
            PICTURE      = 0xFFC,
            ALL          = 0xFFF;
        }

        /* Rotate direction. */
        private enum Rotate { LEFT, RIGHT; }

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
        /* The zoom in button. */
        [GtkChild]
        private Gtk.Button zoom_in;
        /* The zoom out button. */
        [GtkChild]
        private Gtk.Button zoom_out;
        /* The zoom fit button. */
        [GtkChild]
        private Gtk.Button zoom_fit;
        /* The geolocation button. */
        [GtkChild]
        private Gtk.ToggleButton geolocation;
        /* The save button. */
        [GtkChild]
        private Gtk.Button save;
        /* The image scroll. */
        [GtkChild]
        private Gtk.ScrolledWindow image_scroll;
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
        /* The progress bar. */
        [GtkChild]
        private Gtk.ProgressBar progress;

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
        /* Geolocation window. */
        private GeolocationWindow geolocation_win;
        /* The map view. */
        private Champlain.View view;
        /* The marker layer. */
        private Champlain.MarkerLayer layer;
        /* The marker. */
        private Champlain.Label marker;

        private int counter;
        private bool updating;

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

            geolocation_win = new GeolocationWindow(application);
            geolocation_win.set_transient_for(this);
            geolocation.bind_property("active", geolocation_win, "visible",
                                      GLib.BindingFlags.BIDIRECTIONAL);

            view = new Champlain.View();
            layer = new Champlain.MarkerLayer();
            view.add_layer(layer);

            view.set_size(600, 400);
            view.animate_zoom = true;

            view.zoom_level = 4;
            view.kinetic_mode = false;
            view.center_on(19.432647, -99.133199);

            var geolocation_embed = geolocation_win.get_geolocation_embed();
            var stage = geolocation_embed.get_stage() as Clutter.Stage;
            stage.reactive = true;
            stage.button_release_event.connect(map_button_release);
            stage.add_child(view);

            geolocation_win.view = view;

            disable_ui(Item.ALL);
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
            if (!previous.sensitive || !iterator.has_previous())
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
            if (!next.sensitive || !iterator.has_next())
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
            if (rotate_left.sensitive)
                rotate(Rotate.LEFT);
        }

        /**
         * Callback for rotate right button clicked.
         */
        [GtkCallback]
        public void on_rotate_right_clicked() {
            if (rotate_right.sensitive)
                rotate(Rotate.RIGHT);
        }

        /**
         * Callback for zoom in.
         */
        [GtkCallback]
        public void on_zoom_in_clicked() {
            if (!zoom_in.sensitive)
                return;
            photograph.scale_by_factor(1.1);
            image.set_from_pixbuf(photograph.pixbuf);
        }

        /**
         * Callback for zoom out.
         */
        [GtkCallback]
        public void on_zoom_out_clicked() {
            if (!zoom_out.sensitive)
                return;
            photograph.scale_by_factor(0.9);
            image.set_from_pixbuf(photograph.pixbuf);
        }

        /**
         * Callback for zoom fit.
         */
        [GtkCallback]
        public void on_zoom_fit_clicked() {
            if (!zoom_fit.sensitive)
                return;
            double w = image_scroll.get_allocated_width();
            double h = image_scroll.get_allocated_height();
            if (w <= 0.0 || h <= 0.0)
                return;
            photograph.resize(w, h);
            image.set_from_pixbuf(photograph.pixbuf);
        }

        /**
         * Callback for save button clicked.
         */
        [GtkCallback]
        public void on_save_clicked() {
            if (!save.sensitive)
                return;
            try {
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
        public void on_data_activated() {
            if (save.sensitive)
                on_save_clicked();
            on_next_clicked();
        }

        /**
         * Callback for any data changed.
         */
        [GtkCallback]
        public void on_data_changed() {
            if (updating)
                return;
            var a = album.text.strip();
            photograph.album = a;
            var t = caption.text.strip();
            if (marker != null)
                marker.text = t;
            photograph.caption = t;
            var c = comment.buffer.text.strip();
            photograph.comment = c;
            enable_ui(Item.SAVE);
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
         * Toggle geolocation.
         */
        public void toggle_geolocation() {
            if (!geolocation.sensitive)
                return;
            geolocation.active = !geolocation.active;
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
                enable_ui(Item.ALL);
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
            if (!loader.has_next()) {
                //progress.visible = false;
                return false;
            }
            loader.next();
            var photograph = loader.get();
            try {
                photograph.load();
                counter++;
                progress.fraction = (1.0 * counter) / photographs.size;
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
            if ((items & Item.ZOOM_IN) != 0)
                zoom_in.sensitive = s;
            if ((items & Item.ZOOM_OUT) != 0)
                zoom_out.sensitive = s;
            if ((items & Item.ZOOM_FIT) != 0)
                zoom_fit.sensitive = s;
            if ((items & Item.GEOLOCATION) != 0)
                geolocation.sensitive = s;
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
            update_map();
            disable_ui(Item.SAVE);
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
            updating = true;
            var basename = photograph.file.get_basename();
            var markup = "<b>%s</b>".printf(basename);
            label.set_markup(markup);
            header.subtitle = "%d / %d".printf(index, photographs.size);
            album.text = photograph.album;
            caption.text = photograph.caption;
            check_entries_length();
            comment.buffer.text = photograph.comment;
            caption.grab_focus();
            updating = false;
        }

        /* Updates the map. */
        private void update_map() {
            var header = geolocation_win.get_header();
            header.subtitle = photograph.file.get_basename();
            if (photograph.has_geolocation) {
                update_location(photograph.latitude, photograph.longitude);
                geolocation_win.on_zoom_fit_clicked();
            }
            marker.text = photograph.caption;
        }

        private void update_location(double latitude,
                                     double longitude) {
            if (marker != null) {
                layer.remove_marker(marker);
                marker = null;
            }
            marker = create_marker(latitude, longitude);
            layer.add_marker(marker);
            geolocation_win.latitude = latitude;
            geolocation_win.longitude = longitude;
        }

        private Champlain.Label create_marker(double latitude,
                                              double longitude) {
            string photo_caption = (photograph != null &&
                                    photograph.caption != "") ?
                photograph.caption : "(%g,%g)".printf(latitude, longitude);
            Clutter.Color green = { 0xb6, 0xff, 0x80, 0xdd };
            Clutter.Color black = { 0x00, 0x00, 0x00, 0xff };
            var marker = new Champlain.Label.with_text(photo_caption,
                                                       "Serif 10",
                                                       null, null);
            marker.use_markup = true;
            marker.alignment = Pango.Alignment.RIGHT;
            marker.color = green;
            marker.text_color = black;
            marker.set_location(latitude, longitude);
            return marker;
        }

        private bool map_button_release(Clutter.ButtonEvent event) {
            double latitude  = view.y_to_latitude(event.y);
            double longitude = view.x_to_longitude(event.x);

            if (event.button == 1) {
                update_location(latitude, longitude);
                photograph.latitude = geolocation_win.latitude;
                photograph.longitude = geolocation_win.longitude;
            } else if (event.button == 2) {
                view.center_on(latitude, longitude);
            }

            return true;
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
