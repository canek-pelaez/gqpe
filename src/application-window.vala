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

    [GtkTemplate (ui = "/mx/unam/GQPE/gqpe.ui")]
    public class ApplicationWindow : Gtk.ApplicationWindow {

        [GtkChild (name = "previous")]
        private Gtk.Button _previous;
        public Gtk.Button previous { get { return _previous; } }

        [GtkChild (name = "next")]
        private Gtk.Button _next;
        public Gtk.Button next { get { return _next; } }

        [GtkChild (name = "rotate_left")]
        private Gtk.Button _rotate_left;
        public Gtk.Button rotate_left { get { return _rotate_left; } }

        [GtkChild (name = "rotate_right")]
        private Gtk.Button _rotate_right;
        public Gtk.Button rotate_right { get { return _rotate_right; } }

        [GtkChild (name = "save")]
        private Gtk.Button _save;
        public Gtk.Button save { get { return _save; } }

        [GtkChild (name = "frame")]
        private Gtk.Frame _frame;
        public Gtk.Frame frame { get { return _frame; } }

        [GtkChild (name = "label")]
        private Gtk.Label _label;
        public Gtk.Label label { get { return _label; } }

        [GtkChild (name = "image")]
        private Gtk.Image _image;
        public Gtk.Image image { get { return _image; } }

        [GtkChild (name = "entry")]
        private Gtk.Entry _entry;
        public Gtk.Entry entry { get { return _entry; } }

        private Application app;

        public ApplicationWindow(Gtk.Application application) {
            GLib.Object(application: application);
            app = application as Application;
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
        public void on_entry_activate() {
        }

        [GtkCallback]
        public void on_entry_changed() {
            entry.sensitive = true;
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
    }
}
