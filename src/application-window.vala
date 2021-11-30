/*
 * This file is part of gqpe.
 *
 * Copyright © 2013-2021 Canek Peláez Valdés
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
    [GtkTemplate (ui = "/mx/unam/GQPE/application-window.ui")]
    public class ApplicationWindow : Gtk.ApplicationWindow {

        /* UI items. */
        private enum Item {
            PREVIOUS     = 1 << 0,
            NEXT         = 1 << 1,
            ROTATE_LEFT  = 1 << 2,
            ROTATE_RIGHT = 1 << 3,
            PIN_MAP      = 1 << 7,
            SAVE         = 1 << 8,
            ALBUM        = 1 << 9,
            TITLE        = 1 << 10,
            COMMENT      = 1 << 11,
            NAVIGATION   = 0x003,
            PICTURE      = 0xFFC,
            ALL          = 0xFFF;
        }

        /* Rotate direction. */
        private enum Rotate { LEFT, RIGHT; }

        /* CSS Resource. */
        private const string CSS = "resource:///mx/unam/GQPE/gqpe.css";
        /* Maximum length for the album. */
        private const int ALBUM_LENGTH = 50;
        /* Maximum length for the title. */
        private const int TITLE_LENGTH = 40;
        /* Max length. */
        private const int MAX_LENGTH = 500;

        /* The head bar. */
        [GtkChild]
        private unowned Gtk.HeaderBar header;
        /* The previous button. */
        [GtkChild]
        private unowned Gtk.Button previous;
        /* The next button. */
        [GtkChild]
        private unowned Gtk.Button next;
        /* The rotate left button. */
        [GtkChild]
        private unowned Gtk.Button rotate_left;
        /* The rotate right button. */
        [GtkChild]
        private unowned Gtk.Button rotate_right;
        /* The pin map button. */
        [GtkChild]
        private unowned Gtk.Button pin_map;
        /* The save button. */
        [GtkChild]
        private unowned Gtk.Button save;
        /* The image label. */
        [GtkChild]
        private unowned Gtk.Label label;
        /* The image. */
        [GtkChild]
        private unowned Gtk.Image image;
        /* The album entry. */
        [GtkChild]
        private unowned Gtk.Entry album;
        /* The title entry. */
        [GtkChild]
        private unowned Gtk.Entry _title;
        /* The datetime entry. */
        [GtkChild]
        private unowned Gtk.Entry datetime;
        /* The comment text view. */
        [GtkChild]
        private unowned Gtk.TextView comment;
        /* The latitude spin button. */
        [GtkChild]
        private unowned Gtk.SpinButton latitude;
        /* The longitude spin button. */
        [GtkChild]
        private unowned Gtk.SpinButton longitude;
        /* The link button. */
        [GtkChild]
        private unowned Gtk.LinkButton link;
        /* The clutter embed for the map. */
        [GtkChild]
        private unowned GtkClutter.Embed map_embed;
        /* The progress bar. */
        [GtkChild]
        private unowned Gtk.ProgressBar progress_bar;

        /* The current photograph. */
        private Photograph photograph;
        /* Photograph list. */
        private Gee.ArrayList<Photograph> photographs;
        /* Photograp iterator. */
        private Gee.BidirListIterator<Photograph> iterator;
        /* Photographs map. */
        private Gee.SortedMap<string, Photograph> pmap;
        /* Gdk.Pixbufs map */
        private Gee.SortedMap<string, Gdk.Pixbuf> pixbufs;
        /* The index of the current photograph. */
        private int index;
        /* The map view. */
        private Champlain.View view;
        /* The marker layer. */
        private Champlain.MarkerLayer layer;
        /* The marker. */
        private Champlain.Label marker;
        /* Updating flag. */
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

            view = new Champlain.View();
            layer = new Champlain.MarkerLayer();
            view.add_layer(layer);

            view.set_size(600, 400);
            view.animate_zoom = true;

            view.zoom_level = 4;
            view.kinetic_mode = false;
            view.center_on(19.432647, -99.133199);

            var stage = map_embed.get_stage() as Clutter.Stage;
            stage.reactive = true;
            stage.button_release_event.connect(map_button_release);
            stage.add_child(view);

            image.set_size_request(MAX_LENGTH, MAX_LENGTH);
            disable_ui(Item.ALL);
        }

        /* The on key press event callback. */
        [GtkCallback]
        private bool on_key_press_event(Gdk.EventKey event) {
            var ctrl = (event.state & Gdk.ModifierType.CONTROL_MASK) != 0;
            uint event_key;
            Gdk.keyval_convert_case(event.keyval, null, out event_key);
            if (ctrl)
                control_shortcuts(event_key);
            else
                shortcuts(event_key);
            return false;
        }

        /* Control shortcuts. */
        private void control_shortcuts(uint event_key) {
            switch (event_key) {
            case Gdk.Key.bracketleft:
                on_rotate_left_clicked();
                break;
            case Gdk.Key.bracketright:
                on_rotate_right_clicked();
                break;
            case Gdk.Key.S:
                on_data_activated();
                break;
            }
        }

        /* Normal shortcuts. */
        private void shortcuts(uint event_key) {
            switch (event_key) {
            case Gdk.Key.KP_Page_Up:
            case Gdk.Key.Page_Up:
                on_previous_clicked();
                break;
            case Gdk.Key.KP_Page_Down:
            case Gdk.Key.Page_Down:
                on_next_clicked();
                break;
            }
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
         * Callback for pin map button clicked.
         */
        [GtkCallback]
        public void on_pin_map_clicked() {
            view.zoom_level = 16;
            view.center_on(photograph.latitude, photograph.longitude);
        }

        /**
         * Callback for save button clicked.
         */
        [GtkCallback]
        public void on_save_clicked() {
            if (!photograph.modified)
                return;
            try {
                photograph.save_metadata();
            } catch (GLib.Error e) {
                var f = photograph.path;
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
            var t = _title.text.strip();
            if (marker != null)
                marker.text = t;
            photograph.title = t;
            var c = comment.buffer.text.strip();
            photograph.comment = c;
            check_entries_length();
            enable_ui(Item.SAVE);
        }

        /**
         * Callback for the map size changed.
         */
        [GtkCallback]
        public void on_map_size_changed(Gtk.Allocation allocation) {
            int w = allocation.width;
            int h = allocation.height;
            if (w <= 0 || h <= 0)
                return;
            double latitude = view.get_center_latitude();
            double longitude = view.get_center_longitude();
            view.set_size(w, h);
            view.center_on(latitude, longitude);
        }

        /**
         * Opens an array of files.
         * @param files the array of files.
         */
        public void open_files(GLib.File[] files) {
            load_photographs(files);
            set_iterators();
        }

        /* Loads the photograps. */
        private void load_photographs(GLib.File[] files) {
            photographs = new Gee.ArrayList<Photograph>();
            pixbufs = new Gee.TreeMap<string, Gdk.Pixbuf>();
            foreach (var file in files) {
                FileInfo info = null;
                try {
                    info = file.query_info("standard::*",
                                           GLib.FileQueryInfoFlags.NONE);
                    var ctype = info.get_content_type();
                    if (ctype != "image/jpeg" && ctype != "image/png") {
                        GLib.warning("The file '%s' is not a picture",
                                     file.get_path());
                        continue;
                    }
                    photographs.add(new Photograph(file));
                } catch (GLib.Error e) {
                    GLib.warning("Could not get info from '%s': %s",
                                 file.get_path(), e.message);
                    continue;
                }
            }
            photographs.sort();
            pmap = new Gee.TreeMap<string, Photograph>();
            foreach (var photograph in photographs) {
                pmap[photograph.path] = photograph;
            }
            GLib.Idle.add(lazy_load);
        }

        /* Loads the photographs lazily. */
        private bool lazy_load() {
            if (pmap.is_empty) {
                progress_bar.visible = false;
                return GLib.Source.REMOVE;
            }
            var path = pmap.ascending_keys.first();
            var photo = pmap[path];
            if (!pixbufs.has_key(path)) {
                try {
                    pixbufs[path] = Util.load_pixbuf(photo);
                } catch (GLib.Error e) {
                    GLib.warning("Could not load '%s': %s", path, e.message);
                }
            }
            pmap.unset(photo.path);
            double t = photographs.size - pmap.size;
            progress_bar.fraction = t / photographs.size;
            return GLib.Source.CONTINUE;
        }

        /* Initializes the iterators. */
        private void set_iterators() {
            if (photographs.size == 0) {
                disable_ui(Item.ALL);
            } else {
                enable_ui(Item.ALL);
                iterator = photographs.bidir_list_iterator();
                on_next_clicked();
                if (photographs.size == 1)
                    disable_ui(Item.NEXT);
            }
            disable_ui(Item.PREVIOUS);
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
            if ((items & Item.PIN_MAP) != 0)
                pin_map.sensitive = s;
            if ((items & Item.SAVE) != 0)
                save.sensitive = s;
            if ((items & Item.ALBUM) != 0)
                album.sensitive = s;
            if ((items & Item.TITLE) != 0)
                _title.sensitive = s;
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
            var pixbuf = pixbufs[photograph.path];
            switch (direction) {
            case Rotate.LEFT:
                photograph.rotate_left();
                pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.
                                              COUNTERCLOCKWISE);
                break;
            case Rotate.RIGHT:
                photograph.rotate_right();
                pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.
                                              CLOCKWISE);
                break;
            }
            pixbufs[photograph.path] = pixbuf;
            image.set_from_pixbuf(pixbuf);
            enable_ui(Item.SAVE);
        }

        /* Updates the UI. */
        private void update_ui() {
            update_picture();
            update_data();
            update_map();
            if (photograph != null && photograph.modified)
                enable_ui(Item.SAVE);
            else
                disable_ui(Item.SAVE);
        }

        /* Updates the picture. */
        private void update_picture() {
            photograph = iterator.get();
            var path = photograph.path;
            if (!pixbufs.has_key(path)) {
                try {
                    pixbufs[path] = Util.load_pixbuf(photograph);
                } catch (GLib.Error e) {
                    GLib.warning("Could not load '%s': %s", path, e.message);
                    disable_ui(Item.PICTURE);
                    return;
                }
            }
            image.set_from_pixbuf(pixbufs[path]);
            enable_ui(Item.PICTURE);
            if (!photograph.has_geolocation)
                disable_ui(Item.PIN_MAP);
            if (photograph.modified)
                enable_ui(Item.SAVE);
        }

        /* Updates the data. */
        private void update_data() {
            updating = true;
            var basename = photograph.file.get_basename();
            var markup = "<b>%s</b>".printf(basename);
            label.set_markup(markup);
            header.subtitle = "%d / %d".printf(index, photographs.size);
            album.text = photograph.album;
            _title.text = photograph.title;
            datetime.text = photograph.datetime.format("%Y/%m/%d %H:%M:%S [%:z]");
            check_entries_length();
            comment.buffer.text = photograph.comment;
            _title.grab_focus();
            var u  = "https://maps.google.com/maps?q=%2.11f,%2.11f&z=15";
            u = u.printf(photograph.latitude, photograph.longitude);
            link.uri = u;
            updating = false;
        }

        /* Updates the map. */
        private void update_map() {
            if (marker != null) {
                layer.remove_marker(marker);
                marker = null;
            }
            if (photograph.has_geolocation) {
                update_map_location();
                on_pin_map_clicked();
            }
        }

        /* Updates the map location. */
        private void update_map_location() {
            if (marker == null)
                create_marker();
            marker.set_location(photograph.latitude,
                                photograph.longitude);
            latitude.value = photograph.latitude;
            longitude.value = photograph.longitude;
            marker.text = photograph.title;
        }

        /* Creates a new marker. */
        private void create_marker() {
            string photo_title = (photograph.title != "") ?
                photograph.title :
                "(%g,%g)".printf(photograph.latitude, photograph.longitude);
            Clutter.Color green = { 0xb6, 0xff, 0x80, 0xdd };
            Clutter.Color black = { 0x00, 0x00, 0x00, 0xff };
            marker = new Champlain.Label.with_text(photo_title,
                                                   "Serif 10",
                                                   null, null);
            marker.use_markup = true;
            marker.alignment = Pango.Alignment.RIGHT;
            marker.color = green;
            marker.text_color = black;
            if (photograph.has_geolocation)
                marker.set_location(photograph.latitude,
                                    photograph.longitude);
            layer.add_marker(marker);
        }

        /* Map button release callback. */
        private bool map_button_release(Clutter.ButtonEvent event) {
            double latitude  = view.y_to_latitude(event.y);
            double longitude = view.x_to_longitude(event.x);

            if (event.button == 1) {
                photograph.set_coordinates(latitude, longitude);
                update_map_location();
                enable_ui(Item.PIN_MAP|Item.SAVE);
            } else if (event.button == 2) {
                view.center_on(latitude, longitude);
            }

            return true;
        }

        /* Checks the length of both entries. */
        private void check_entries_length() {
            check_entry_length(album, ALBUM_LENGTH);
            check_entry_length(_title, TITLE_LENGTH);
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
