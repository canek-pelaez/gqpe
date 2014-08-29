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

    public enum Orientation {
        PORTRAIT,
        LANDSCAPE,
        REVERSE_PORTRAIT,
        REVERSE_LANDSCAPE
    }

    public class Main {

        private Gtk.Window window;
        private Gtk.Frame frame;
        private Gtk.Button previous;
        private Gtk.Button next;
        private Gtk.Button rotate_left;
        private Gtk.Button rotate_right;
        private Gtk.Button save;
        private Gtk.Image image;
        private Gtk.Entry entry;

        private Gdk.Pixbuf pixbuf;
        private Orientation orientation;

        private GExiv2.Metadata metadata;
        private string current_file;

        private Gee.ArrayList<string> files;
        private int num_files;
        private Gee.BidirListIterator<string> iterator;
        private int index;

        public Main(Gee.ArrayList<string> files) {
            this.files = files;
            num_files = files.size;
            index = 0;

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

            image = new Gtk.Image();
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
            rotate_left.clicked.connect(() => { rotate_image_left(); });
            box.pack_start(rotate_left);
            rotate_right = new Gtk.Button.from_icon_name("object-rotate-right-symbolic",
                                                         Gtk.IconSize.SMALL_TOOLBAR);
            rotate_right.clicked.connect(() => { rotate_image_right(); });
            box.pack_start(rotate_right);

            save = new Gtk.Button.from_icon_name("document-save-symbolic",
                                                 Gtk.IconSize.SMALL_TOOLBAR);
            save.clicked.connect(() => { save_metadata(); });
            header.pack_end(save);

            return header;
        }

        public void start() {
            previous.sensitive = false;
            if (num_files == 0) {
                next.sensitive = false;
                rotate_left.sensitive = rotate_right.sensitive = false;
                save.sensitive = entry.sensitive = false;
            } else {
                iterator = files.bidir_list_iterator();
                move_to_next();
                if (num_files == 1)
                    next.sensitive = false;
            }
            window.show_all();
        }

        private bool key_pressed(Gdk.EventKey e) {
            if (num_files == 0)
                return false;
            if (e.keyval == Gdk.Key.Left &&
                (e.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                rotate_image_left();
                return true;
            }
            if (e.keyval == Gdk.Key.Right &&
                (e.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                rotate_image_right();
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

        private void rotate_image_left() {
            switch (orientation) {
            case Orientation.PORTRAIT:
                orientation = Orientation.LANDSCAPE;
                break;
            case Orientation.LANDSCAPE:
                orientation = Orientation.REVERSE_PORTRAIT;
                break;
            case Orientation.REVERSE_PORTRAIT:
                orientation = Orientation.REVERSE_LANDSCAPE;
                break;
            case Orientation.REVERSE_LANDSCAPE:
                orientation = Orientation.PORTRAIT;
                break;
            }
            pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.COUNTERCLOCKWISE);
            image.set_from_pixbuf(pixbuf);
            save.sensitive = true;
            entry.grab_focus();
        }

        private void rotate_image_right() {
            switch (orientation) {
            case Orientation.PORTRAIT:
                orientation = Orientation.REVERSE_LANDSCAPE;
                break;
            case Orientation.REVERSE_LANDSCAPE:
                orientation = Orientation.REVERSE_PORTRAIT;
                break;
            case Orientation.REVERSE_PORTRAIT:
                orientation = Orientation.LANDSCAPE;
                break;
            case Orientation.LANDSCAPE:
                orientation = Orientation.PORTRAIT;
                break;
            }
            pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.CLOCKWISE);
            image.set_from_pixbuf(pixbuf);
            save.sensitive = true;
            entry.grab_focus();
        }

        private void set_pixbuf_from_file(string file) {
            try {
                metadata = new GExiv2.Metadata();
                metadata.open_path(file);
                pixbuf = new Gdk.Pixbuf.from_file(file);
                if (metadata.has_tag("Exif.Image.Orientation")) {
                    switch (metadata.get_tag_long("Exif.Image.Orientation")) {
                    case 1:
                        orientation = Orientation.LANDSCAPE;
                        break;
                    case 3:
                        pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.UPSIDEDOWN);
                        orientation = Orientation.REVERSE_LANDSCAPE;
                        break;
                    case 6:
                        pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.CLOCKWISE);
                        orientation = Orientation.PORTRAIT;
                        break;
                    case 8:
                        pixbuf = pixbuf.rotate_simple(Gdk.PixbufRotation.COUNTERCLOCKWISE);
                        orientation = Orientation.REVERSE_PORTRAIT;
                        break;
                    }
                }
                double scale = 1.0;
                if (pixbuf.width > pixbuf.height)
                    scale = 500.0 / pixbuf.width;
                else
                    scale = 375.0 / pixbuf.height;
                pixbuf = pixbuf.scale_simple((int)(pixbuf.width*scale),
                                             (int)(pixbuf.height*scale),
                                               Gdk.InterpType.BILINEAR);
                image.set_from_pixbuf(pixbuf);
                current_file = file;
                if (metadata.has_tag("Iptc.Application2.Caption")) {
                    string title = metadata.get_tag_string("Iptc.Application2.Caption");
                    entry.set_text(title);
                } else {
                    entry.set_text("");
                }
            } catch (GLib.Error e) {
                GLib.warning("Cannot load file '%s'", file);
            }
        }
        
        private void update_picture() {
            string file = iterator.get();
            string basename = File.new_for_path(file).get_basename();
            var label = (Gtk.Label)frame.label_widget;
            label.set_markup(_("<b>%s (%d of %d)</b>").printf(basename, index, num_files));
            set_pixbuf_from_file(file);
            save.sensitive = false;
            entry.grab_focus();
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

        private void save_metadata() {
            metadata.set_tag_string("Iptc.Application2.Caption", entry.get_text());
            int otag = 1;
            switch (orientation) {
            case Orientation.PORTRAIT:          otag = 6; break;
            case Orientation.LANDSCAPE:         otag = 1; break;
            case Orientation.REVERSE_PORTRAIT:  otag = 8; break;
            case Orientation.REVERSE_LANDSCAPE: otag = 3; break;
            }
            metadata.set_tag_long("Exif.Image.Orientation", otag);
            if (metadata.has_tag("Exif.Thumbnail.Orientation"))
                metadata.set_tag_long("Exif.Thumbnail.Orientation", otag);
            try {
                metadata.save_file(current_file);
            } catch (GLib.Error e) {
                GLib.warning("Could not update metadata for %s", current_file);
            }
            save.sensitive = false;
        }

        private void picture_done() {
            if (!save.sensitive)
                return;
            save_metadata();
            move_to_next();
        }
    }

    int main(string[] args) {
        Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain(Config.GETTEXT_PACKAGE);

        Gtk.init(ref args);

        Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;

        var files = new Gee.ArrayList<string>();
        foreach (var arg in args[1:args.length])
            files.add(arg);
        files.sort();

        var gqpe = new Main(files);
        gqpe.start();

        Gtk.main();

        return 0;
    }
}
