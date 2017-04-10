/* geolocation-window.vala
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
     * Class for the geolocation window.
     */
    [GtkTemplate (ui = "/mx/unam/GQPE/geolocation.ui")]
    public class GeolocationWindow : Gtk.ApplicationWindow {

        /* The head bar. */
        [GtkChild]
        private Gtk.HeaderBar header;
        /* The latitude spinbutton. */
        [GtkChild]
        private Gtk.SpinButton latitude_spin;
        /* The longitude spinbutton. */
        [GtkChild]
        private Gtk.SpinButton longitude_spin;
        /* The geolocation embed. */
        [GtkChild]
        private GtkClutter.Embed geolocation_embed;

        public Champlain.View view { get; set; }

        public Gtk.HeaderBar get_header() {
            return header;
        }

        public GtkClutter.Embed get_geolocation_embed() {
            return geolocation_embed;
        }

        /**
         * The latitude.
         */
        public double latitude {
            get { return latitude_spin.value; }
            set { latitude_spin.value = value; }
        }

        /**
         * The longitude.
         */
        public double longitude {
            get { return longitude_spin.value; }
            set { longitude_spin.value = value; }
        }

        /**
         * Constructs a new geolocation window.
         */
        public GeolocationWindow(Gtk.Application application) {
            GLib.Object(application: application);
        }

        /**
         * Callback for window deletion.
         */
        [GtkCallback]
        public bool on_window_delete() {
            this.visible = false;
            return true;
        }

        /**
         * Callback for zoom in clicked.
         */
        [GtkCallback]
        public void on_zoom_in_clicked() {
            view.zoom_level++;
        }

        /**
         * Callback for zoom out clicked.
         */
        [GtkCallback]
        public void on_zoom_out_clicked() {
            view.zoom_level--;
        }

        /**
         * Callback for zoom fit clicked.
         */
        [GtkCallback]
        public void on_zoom_fit_clicked() {
            view.center_on(latitude, longitude);
            view.zoom_level = 14;
        }

        /**
         * Callback for geolocation size changed.
         */
        [GtkCallback]
        public void on_geolocation_size_changed(Gtk.Allocation allocation) {
            int w = allocation.width;
            int h = allocation.height;
            if (w <= 0 || h <= 0)
                return;
            double latitude = view.get_center_latitude();
            double longitude = view.get_center_longitude();
            view.set_size(w, h);
            view.center_on(latitude, longitude);
        }
    }
}
