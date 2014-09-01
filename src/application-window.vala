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

    public enum UIItemFlags {
        PREVIOUS     = 1 << 0,
        NEXT         = 1 << 1,
        ROTATE_LEFT  = 1 << 2,
        ROTATE_RIGHT = 1 << 3,
        SAVE         = 1 << 4,
        CAPTION      = 1 << 5,
        MASK         = 0x3f
    }

    [GtkTemplate (ui = "/mx/unam/GQPE/gqpe.ui")]
    public class ApplicationWindow : Gtk.ApplicationWindow {

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
        private Gtk.Entry caption;

        private Application app;

        public ApplicationWindow(Gtk.Application application) {
            GLib.Object(application: application);
            app = application as Application;

            Gtk.Window.set_default_icon_name("gqpe");
            var provider = new Gtk.CssProvider();
            try {
                var file = GLib.File.new_for_uri("resource:///mx/unam/GQPE/gqpe.css");
                provider.load_from_file (file);
            } catch (GLib.Error e) {
                GLib.warning ("There was a problem loading 'gqpe.css'");
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
            app.previous();
        }

        [GtkCallback]
        public void on_next_clicked() {
            app.next();
        }

        [GtkCallback]
        public void on_rotate_left_clicked() {
            app.rotate_left();
        }

        [GtkCallback]
        public void on_rotate_right_clicked() {
            app.rotate_right();
        }

        [GtkCallback]
        public void on_save_clicked() {
            app.save();
        }

        [GtkCallback]
        public void on_caption_activate() {
            app.picture_done();
        }

        [GtkCallback]
        public void on_caption_changed() {
            save.sensitive = true;
        }

        [GtkCallback]
        public bool on_window_key_press(Gdk.EventKey e) {
            if (e.keyval == Gdk.Key.bracketleft) {
                app.rotate_left();
                return true;
            }
            if (e.keyval == Gdk.Key.bracketright) {
                app.rotate_right();
                return true;
            }
            if (e.keyval == Gdk.Key.Page_Up) {
                app.previous();
                return true;
            }
            if (e.keyval == Gdk.Key.Page_Down) {
                app.next();
                return true;
            }
            if (e.keyval == Gdk.Key.Escape) {
                app.quit();
                return true;
            }
            return false;
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
            if ((flags & UIItemFlags.CAPTION) != 0)
                caption.sensitive = s;
        }

        public void enable(UIItemFlags flags) {
            items_set_sensitive(flags, true);
        }

        public void disable(UIItemFlags flags) {
            items_set_sensitive(flags, false);
        }

        public void set_filename(string basename, int index, int total) {
            var markup = _("<b>%s (%d of %d)</b>").printf(basename, index, total);
            label.set_markup(markup);
        }

        public void set_pixbuf(Gdk.Pixbuf pixbuf) {
            image.set_from_pixbuf(pixbuf);
        }

        public void set_caption(string caption) {
            this.caption.set_text(caption);
            this.caption.grab_focus();
        }

        public bool saving_allowed() {
            return save.sensitive;
        }
    }
}
