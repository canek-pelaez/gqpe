using Gtk;

namespace QuickPhotoEditor {

	public enum Orientation {
		PORTRAIT,
		LANDSCAPE,
		REVERSE_PORTRAIT,
		REVERSE_LANDSCAPE,
	}

	public class QuickPhotoEditor : Object {

		private string UI = GLib.Path.build_filename(Config.PKGDATADIR,
													 "quick-photo-editor.ui");
		private Window window;
		private Label label;
		private Image image;
		private Entry entry;
		private ToolButton prev;
		private ToolButton next;
		private ToolButton rot270;
		private ToolButton rot90;
		private ToolButton save;

		private Gdk.Pixbuf pixbuf;
		private Orientation orientation;

		private GExiv2.Metadata metadata;
		private string current_file;

		private Gee.ArrayList<string> files;
		private int num_files;
		private Gee.ListIterator<string> iterator;
		private int index;

		public QuickPhotoEditor(Gee.ArrayList<string> files) {
			this.files = files;
			num_files = (files as Gee.AbstractCollection).size;
			index = 0;
			var builder = new Builder();
			try {
				builder.add_from_file(UI);
			} catch (Error e) {
				GLib.warning("Could not open UI file %s", UI);
			}
			window = builder.get_object("window") as Window;
			window.title = _("Quick Photo Editor");
			window.window_position = WindowPosition.CENTER_ALWAYS;
			window.destroy.connect(Gtk.main_quit);
			window.key_press_event.connect((k) => { return key_pressed(k); });
			label = builder.get_object("label") as Label;
			image = builder.get_object("image") as Image;

			prev = builder.get_object("prev_toolbutton") as ToolButton;
			prev.clicked.connect(() => { move_to_prev(); });
			next = builder.get_object("next_toolbutton") as ToolButton;
			next.clicked.connect(() => { move_to_next(); });
			rot270 = builder.get_object("rot270_toolbutton") as ToolButton;
			rot270.clicked.connect(() => { rotate_left(); });
			rot90 = builder.get_object("rot90_toolbutton") as ToolButton;
			rot90.clicked.connect(() => { rotate_right(); });
			save = builder.get_object("save_toolbutton") as ToolButton;
			save.clicked.connect(() => { save_metadata(); });
			entry = builder.get_object("entry") as Entry;
			entry.activate.connect(() => { picture_done(); });
			entry.changed.connect(() => { save.sensitive = true; });
		}

		public void start() {
			if (num_files == 0) {
				prev.sensitive = next.sensitive = false;
				rot270.sensitive = rot90.sensitive = false;
				save.sensitive = entry.sensitive = false;
			} else {
				iterator = files.list_iterator();
				move_to_next();
				prev.sensitive = false;
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
				rotate_left();
				return true;
			}
			if (e.keyval == Gdk.Key.Right &&
				(e.state & Gdk.ModifierType.MOD1_MASK) != 0) {
				rotate_right();
				return true;
			}
			if (e.keyval == Gdk.Key.Page_Down) {
				move_to_next();
				return true;
			}
			if (e.keyval == Gdk.Key.Page_Up) {
				move_to_prev();
				return true;
			}
			if (e.keyval == Gdk.Key.Escape) {
				Gtk.main_quit();
				return true;
			}
			return false;
		}

		private void rotate_left() {
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

		private void rotate_right() {
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
				var original = new Gdk.Pixbuf.from_file(file);
				int width = original.width;
				int height = original.height;
				double scale = 500.0 / double.max(width, height);
				pixbuf = original.scale_simple((int)(width*scale),
											   (int)(height*scale),
											   Gdk.InterpType.NEAREST);
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
			label.set_markup(_("<b>%s (%d of %d)</b>").printf(basename, index, num_files));
			set_pixbuf_from_file(file);
			save.sensitive = false;
			entry.grab_focus();
		}

		private void move_to_prev() {
			if (!iterator.has_previous())
					return;
			iterator.previous();
			index--;
			next.sensitive = true;
			if (!iterator.has_previous())
				prev.sensitive = false;
			update_picture();
		}

		private void move_to_next() {
			if (!iterator.has_next())
					return;
			iterator.next();
			index++;
			prev.sensitive = true;
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

		var qpe = new QuickPhotoEditor(files);
		qpe.start();

        Gtk.main();

        return 0;
	}
}
