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
     * Export photos to Shotwell.
     */
    public class Shotwell {

        private enum PhotoColumn {
            ID,
            FILENAME,
            WIDTH,
            HEIGHT,
            FILESIZE,
            TIMESTAMP,
            EXPOSURE_TIME,
            ORIENTATION,
            ORIGINAL_ORIENTATION,
            IMPORT_ID,
            EVENT_ID,
            TRANSFORMATIONS,
            MD5,
            THUMBNAIL_MD5,
            EXIF_MD5,
            TIME_CREATED,
            FLAGS,
            RATING,
            FILE_FORMAT,
            TITLE,
            BACKLINKS,
            TIME_REIMPORTED,
            EDITABLE_ID,
            METADATA_DIRTY,
            DEVELOPER,
            DEVELOP_SHOTWELL_ID,
            DEVELOP_CAMERA_ID,
            DEVELOP_EMBEDDED_ID,
            COMMENT;

            public int arg() {
                return ((int)this) + 1;
            }
        }

        private enum EventColumn {
            ID,
            NAME,
            PRIMARY_PHOTO_ID,
            TIME_CREATED,
            PRIMARY_SOURCE_ID,
            COMMENT;

            public int arg() {
                return ((int)this) + 1;
            }
        }

        private enum TagColumn {
            ID,
            NAME,
            PHOTO_ID_LIST,
            TIME_CREATED;

            public int arg() {
                return ((int)this) + 1;
            }
        }

        private class Event : GLib.Object {
            public int id { get; private set; }
            private int year;
            private int month;
            private string name;
            public string key { get; private set; }

            public Event(int id, int year, int month, string name) {
                this.id = id;
                this.year = year;
                this.month = month;
                this.name = name;
                key = Event.event_key(year, month, name);
            }

            public Event.from_photo(int id, Photograph photo) {
                this.id = id;
                this.year = photo.datetime.get_year();
                this.month = photo.datetime.get_month();
                this.name = photo.album;
                key = Event.event_key(year, month, name);
            }

            public static string event_key(int year, int month, string name) {
                return "%04d/%02d/%s".printf(year, month, name);
            }

            public static string event_key_from_photo(Photograph photo) {
                return "%04d/%02d/%s".printf(photo.datetime.get_year(),
                                             photo.datetime.get_month(),
                                             photo.album);
            }
        }

        private const string DEVELOPER = "SHOTWELL";
        private const string SELECT_PHOTO_PATH_QUERY =
            "SELECT * FROM PhotoTable WHERE filename = ?;";
        private const string SELECT_PHOTO_PATH_LIKE_QUERY =
            "SELECT * FROM PhotoTable WHERE filename LIKE ?;";
        private const string SELECT_PHOTO_EVENT_QUERY =
            "SELECT * FROM PhotoTable WHERE event_id = ?;";
        private const string SELECT_MAX_PHOTO_ID_QUERY =
            "SELECT MAX(id) FROM PhotoTable;";
        private const string SELECT_EVENT_NAME_QUERY =
            "SELECT * FROM EventTable WHERE name = ?;";
        private const string SELECT_EVENT_ID_QUERY =
            "SELECT * FROM EventTable WHERE id = ?;";
        private const string SELECT_MAX_EVENT_ID_QUERY =
            "SELECT MAX(id) FROM EventTable;";
        private const string SELECT_TAG_NAME_QUERY =
            "SELECT * FROM TagTable WHERE name = ?;";
        private const string SELECT_TAG_ID_QUERY =
            "SELECT * FROM TagTable WHERE ID = ?;";
        private const string SELECT_MAX_TAG_ID_QUERY =
            "SELECT MAX(id) FROM TagTable;";
        private const string SELECT_TAG_PHOTOS_QUERY =
            "SELECT photo_id_list FROM TagTable WHERE id = ?;";
        private const string INSERT_PHOTO_QUERY =
            "INSERT INTO PhotoTable VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
        private const string INSERT_EVENT_QUERY =
            "INSERT INTO EventTable VALUES (?, ?, ?, ?, ?, ?);";
        private const string INSERT_TAG_QUERY =
            "INSERT INTO TagTable VALUES (?, ?, ?, ?);";
        private const string UPDATE_EVENT_QUERY =
            "UPDATE EventTable SET primary_source_id = ? WHERE id = ?";
        private const string UPDATE_TAG_QUERY =
            "UPDATE TagTable SET photo_id_list = ? WHERE id = ?";

        private const int GTHUMB_LENGTH = 256;
        private const int T128_LENGTH = 128;
        private const int T360_LENGTH = 360;

        /* Wheter to use a list of files. */
        private static bool files;
        /* The covers JSON file name. */
        private static string covers;
        /* Wheter to be verbose. */
        private static bool verbose;
         /* The database connection. */
        private static Sqlite.Database db;

        private static int64 export_id;

        private static Gee.TreeMap<string, Event> events;

        /* The option context. */
        private const string CONTEXT =
            _("[DIRNAME] [FILENAME…] - Export to Shotwell.");

        /* Returns the options. */
        private static GLib.OptionEntry[] get_options() {
            GLib.OptionEntry[] options = {
                { "files", 'f', 0, GLib.OptionArg.NONE, &files,
                  _("Use a file list instead of a directory"), null },
                { "covers", 'c', 0, GLib.OptionArg.STRING, &covers,
                  _("Use a Galería JSON to set the primary photos"), null },
                { "verbose", 'v', 0, GLib.OptionArg.NONE, &verbose,
                  _("Be verbose"), null },
                { null }
            };
            return options;
        }

        private static void progress(ProgressState state, int number) {
            switch (state) {
            case INIT:
                stdout.printf(_("Loading photographs…\n"));
                break;
            case ADVANCE:
                if (!verbose) {
                    stdout.printf(_("Loaded %d photographs…%s"),
                                  number, "\r\b");
                    stdout.flush();
                }
                break;
            case END:
                stdout.printf(_("Loaded %d photographs.\n"), number);
                break;
            }
        }

        private static bool photo_in_db(Photograph photo) {
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(SELECT_PHOTO_PATH_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return true;
            }
            stmt.bind_text(1, photo.path);
            return stmt.step() == Sqlite.ROW;
        }

        private static bool photo_in_event(Photograph photo, int event_id) {
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(SELECT_PHOTO_EVENT_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return false;
            }
            stmt.bind_int(1, event_id);
            if (stmt.step() == Sqlite.ROW) {
                var path = stmt.column_text(PhotoColumn.FILENAME);
                try {
                    var file = GLib.File.new_for_path(path);
                    var p = new Photograph(file);
                    if (photo.datetime.get_year() == p.datetime.get_year() &&
                        photo.datetime.get_month() == p.datetime.get_month())
                        return true;
                } catch (GLib.Error e) {
                    return false;
                }
            }
            return false;
        }

        private static int get_new_event_id() {
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(SELECT_MAX_EVENT_ID_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return -1;
            }
            if (stmt.step() == Sqlite.ROW)
                return stmt.column_int(0)+1;
            /* Empty table. */
            return 1;
        }

        private static int create_new_event(Photograph photo) {
            int event_id = get_new_event_id();
            if (event_id < 0)
                return -1;
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(INSERT_EVENT_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return -1;
            }
            stmt.bind_int(EventColumn.ID.arg(), event_id);
            stmt.bind_text(EventColumn.NAME.arg(), photo.album);
            stmt.bind_null(EventColumn.PRIMARY_PHOTO_ID.arg());
            stmt.bind_int64(EventColumn.TIME_CREATED.arg(), Util.now());
            stmt.bind_null(EventColumn.PRIMARY_SOURCE_ID.arg());
            stmt.bind_null(EventColumn.COMMENT.arg());
            if ((rc = stmt.step()) != Sqlite.DONE) {
                stderr.printf(_("Error inserting: %d, %s\n"), rc, db.errmsg());
                return -1;
            }
            var _event = new Event.from_photo(event_id, photo);
            events[_event.key] = _event;
            return event_id;
        }

        private static int get_event_by_name(Photograph photo) {
            var key = Event.event_key_from_photo(photo);
            if (events.has_key(key))
                return events[key].id;
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(SELECT_EVENT_NAME_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return -1;
            }
            stmt.bind_text(1, photo.album);
            if (stmt.step() == Sqlite.ROW) {
                int event_id = stmt.column_int(EventColumn.ID);
                if (photo_in_event(photo, event_id)) {
                    var _event = new Event.from_photo(event_id, photo);
                    events[_event.key] = _event;
                    return event_id;
                }
            }
            return create_new_event(photo);
        }

        private static int get_new_tag_id() {
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(SELECT_MAX_TAG_ID_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return -1;
            }
            if (stmt.step() == Sqlite.ROW)
                return stmt.column_int(0)+1;
            /* Empty table. */
            return 1;
        }

        private static int create_new_tag(Photograph photo) {
            int tag_id = get_new_tag_id();
            if (tag_id < 0)
                return -1;
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(INSERT_TAG_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return -1;
            }
            stmt.bind_int(TagColumn.ID.arg(), tag_id);
            stmt.bind_text(TagColumn.NAME.arg(), photo.album);
            stmt.bind_null(TagColumn.PHOTO_ID_LIST.arg());
            stmt.bind_int64(TagColumn.TIME_CREATED.arg(), Util.now());
            if ((rc = stmt.step()) != Sqlite.DONE) {
                stderr.printf(_("Error inserting: %d, %s\n"), rc, db.errmsg());
                return -1;
            }
            return tag_id;
        }

        private static int get_tag_by_name(Photograph photo) {
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(SELECT_TAG_NAME_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return -1;
            }
            stmt.bind_text(1, photo.album);
            if (stmt.step() == Sqlite.ROW)
                return stmt.column_int(TagColumn.ID);
            return create_new_tag(photo);
        }

        private static int get_new_photo_id() {
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(SELECT_MAX_PHOTO_ID_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return -1;
            }
            if (stmt.step() == Sqlite.ROW)
                return stmt.column_int(0) + 1;
            /* Empty table. */
            return 1;
        }

        private static string get_photo_md5(Photograph photo)
            throws GLib.Error {
            var data = new uint8[photo.size];
            var file = photo.file.read();
            size_t size;
            file.read_all(data, out size);
            if (photo.size != size)
                throw new GLib.Error(GLib.Quark.from_string("gqpe"), 0,
                                     _("Cannot read file: %s"), photo.path);
            var md5 = GLib.Checksum.compute_for_data(GLib.ChecksumType.MD5,
                                                     data);
            return md5;
        }

        private static int insert_photo(Photograph photo,
                                        int event_id,
                                        int tag_id) throws GLib.Error {
            int photo_id = get_new_photo_id();
            if (photo_id < 0) {
                stderr.printf(_("Error getting photo id for: %s\n"),
                              photo.path);
                return -1;
            }
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(INSERT_PHOTO_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return -1;
            }
            stmt.bind_int(PhotoColumn.ID.arg(), photo_id);
            stmt.bind_text(PhotoColumn.FILENAME.arg(), photo.path);
            stmt.bind_int(PhotoColumn.WIDTH.arg(), photo.width);
            stmt.bind_int(PhotoColumn.HEIGHT.arg(), photo.height);
            stmt.bind_int(PhotoColumn.FILESIZE.arg(), photo.size);
            stmt.bind_int64(PhotoColumn.TIMESTAMP.arg(),
                            photo.file_datetime.to_unix());
            stmt.bind_int64(PhotoColumn.EXPOSURE_TIME.arg(),
                            photo.file_datetime.to_unix());
            stmt.bind_int(PhotoColumn.ORIENTATION.arg(), photo.orientation);
            stmt.bind_int(PhotoColumn.ORIGINAL_ORIENTATION.arg(),
                          photo.orientation);
            stmt.bind_int64(PhotoColumn.IMPORT_ID.arg(), export_id);
            stmt.bind_int(PhotoColumn.EVENT_ID.arg(), event_id);
            stmt.bind_null(PhotoColumn.TRANSFORMATIONS.arg());
            stmt.bind_text(PhotoColumn.MD5.arg(), get_photo_md5(photo));
            stmt.bind_null(PhotoColumn.THUMBNAIL_MD5.arg());
            stmt.bind_null(PhotoColumn.EXIF_MD5.arg());
            stmt.bind_int64(PhotoColumn.TIME_CREATED.arg(), Util.now());
            stmt.bind_int(PhotoColumn.FLAGS.arg(), 0);
            stmt.bind_int(PhotoColumn.RATING.arg(), 0);
            stmt.bind_int(PhotoColumn.FILE_FORMAT.arg(), 0);
            stmt.bind_text(PhotoColumn.TITLE.arg(), photo.title);
            stmt.bind_null(PhotoColumn.BACKLINKS.arg());
            stmt.bind_null(PhotoColumn.TIME_REIMPORTED.arg());
            stmt.bind_int(PhotoColumn.EDITABLE_ID.arg(), -1);
            stmt.bind_int(PhotoColumn.METADATA_DIRTY.arg(), 0);
            stmt.bind_text(PhotoColumn.DEVELOPER.arg(), DEVELOPER);
            stmt.bind_int(PhotoColumn.DEVELOP_SHOTWELL_ID.arg(), -1);
            stmt.bind_int(PhotoColumn.DEVELOP_CAMERA_ID.arg(), -1);
            stmt.bind_int(PhotoColumn.DEVELOP_EMBEDDED_ID.arg(), -1);
            if (photo.comment != null && photo.comment != "")
                stmt.bind_text(PhotoColumn.COMMENT.arg(), photo.comment);
            else
                stmt.bind_null(PhotoColumn.COMMENT.arg());
            if ((rc = stmt.step()) != Sqlite.DONE) {
                stderr.printf(_("Error inserting: %d, %s\n"), rc, db.errmsg());
                return -1;
            }
            return photo_id;
        }

        private static bool
        do_create_thumbnail(Gdk.Pixbuf pb, string path,
                            string format, int length) throws GLib.Error {
            var t = Util.scale_pixbuf(pb, length);
            var r = t.save(path, format);
            GLib.FileUtils.chmod(path, 6*(8*8) + 0*8 + 0);
            return r;
        }

        private static bool create_thumbnail(int photo_id, Photograph photo)
            throws GLib.Error {
            var md5 = GLib.ChecksumType.MD5;
            var uri = photo.file.get_uri();
            var png = GLib.Checksum.compute_for_string(md5, uri) + ".png";
            var g_path = string.join(GLib.Path.DIR_SEPARATOR_S,
                                     GLib.Environment.get_user_cache_dir(),
                                     "thumbnails", "large", png);
            var jpg = source_id(photo_id) + ".jpg";
            var t128_path = string.join(GLib.Path.DIR_SEPARATOR_S,
                                        GLib.Environment.get_user_cache_dir(),
                                        "shotwell", "thumbs", "thumbs128", jpg);
            var t360_path = string.join(GLib.Path.DIR_SEPARATOR_S,
                                        GLib.Environment.get_user_cache_dir(),
                                        "shotwell", "thumbs", "thumbs360", jpg);
            bool r = true;
            var pb = Util.load_pixbuf(photo);
            if (!FileUtils.test(g_path, FileTest.EXISTS)) {
                if (verbose)
                    stderr.printf(_("Generating GNOME thumb: %s\n"), g_path);
                r &= do_create_thumbnail(pb, g_path, "png", GTHUMB_LENGTH);
            }
            if (!FileUtils.test(t128_path, FileTest.EXISTS)) {
                if (verbose)
                    stderr.printf(_("Generating Shotwell 128px thumb: %s\n"),
                                  t128_path);
                r &= do_create_thumbnail(pb, t128_path, "jpeg", T128_LENGTH);
            }
            if (!FileUtils.test(t360_path, FileTest.EXISTS)) {
                if (verbose)
                    stderr.printf(_("Generating Shotwell 360px thumb: %s\n"),
                                  t360_path);
                r &= do_create_thumbnail(pb, t360_path, "jpeg", T360_LENGTH);
            }
            return r;
        }

        private static string source_id(int photo_id) {
            return "thumb%016x".printf(photo_id);
        }

        private static bool event_has_primary_photo(int event_id) {
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(SELECT_EVENT_ID_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return true;
            }
            stmt.bind_int(1, event_id);
            if (stmt.step() == Sqlite.ROW) {
                var ps = stmt.column_text(EventColumn.PRIMARY_SOURCE_ID);
                return ps != null;
            }
            return false;
        }

        private static bool do_update_event(int event_id, int photo_id) {
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(UPDATE_EVENT_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return false;
            }
            var sid = source_id(photo_id);
            stmt.bind_text(1, sid);
            stmt.bind_int(2, event_id);
            return stmt.step() == Sqlite.DONE;
        }

        private static bool update_event(int event_id, int photo_id) {
            if (event_has_primary_photo(event_id))
                return true;
            return do_update_event(event_id, photo_id);
        }

        private static Gee.SortedSet<string> get_tag_photos(int tag_id) {
            var tag_photos = new Gee.TreeSet<string>();
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(SELECT_TAG_PHOTOS_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return tag_photos;
            }
            stmt.bind_int(1, tag_id);
            if (stmt.step() == Sqlite.ROW) {
                var ps = stmt.column_text(0);
                if (ps == null)
                    return tag_photos;
                var ids = ps.split(",");
                foreach (string id in ids) {
                    if (id != "")
                        tag_photos.add(id);
                }
            }
            return tag_photos;
        }

        private static bool update_tag(int tag_id, int photo_id) {
            var tag_photos = get_tag_photos(tag_id);
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(UPDATE_TAG_QUERY, -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return false;
            }
            tag_photos.add(source_id(photo_id));
            var ids = "";
            foreach (string id in tag_photos)
                ids += (id + ",");
            stmt.bind_text(1, ids);
            stmt.bind_int(2, tag_id);
            return stmt.step() == Sqlite.DONE;
        }

        private static bool export_photo(Photograph photo) throws GLib.Error {
            if (verbose)
                stdout.printf(_("Exporting: %s\n"), photo.path);
            if (photo_in_db(photo)) {
                stderr.printf(_("Already in database: %s, skipping.\n"),
                              photo.path);
                return false;
            }
            if (photo.title == null || photo.title == "") {
                stderr.printf(_("Missing title: %s, skipping.\n"), photo.path);
                return false;
            }
            if (photo.album == null || photo.album == "") {
                stderr.printf(_("Missing album: %s, skipping.\n"), photo.path);
                return false;
            }
            int event_id = get_event_by_name(photo);
            if (event_id < 0) {
                stderr.printf(_("Error getting event for: %s, skipping.\n"),
                              photo.path);
                return false;
            }
            int tag_id = get_tag_by_name(photo);
            if (tag_id < 0) {
                stderr.printf(_("Error getting tag for: %s, skipping.\n"),
                              photo.path);
                return false;
            }
            int photo_id = insert_photo(photo, event_id, tag_id);
            if (photo_id < 0) {
                stderr.printf(_("Error inserting photograph: %s, skipping.\n"),
                              photo.path);
                return false;
            }
            if (!create_thumbnail(photo_id, photo)) {
                stderr.printf(_("Error making thumbnail for: %s, skipping.\n"),
                              photo.path);
                return false;
            }
            if (!update_event(event_id, photo_id)) {
                stderr.printf(_("Error updating event for: %s, skipping.\n"),
                              photo.path);
                return false;
            }
            if (!update_tag(tag_id, photo_id)) {
                stderr.printf(_("Error updating tag for: %s, skipping.\n"),
                              photo.path);
                return false;
            }
            return true;
        }

        /* Exports the photos. */
        private static int
        export_photos(Gee.SortedSet<Photograph> photos) throws GLib.Error {
            int c = 0;
            export_id = Util.now();
            foreach (var photo in photos) {
                if (export_photo(photo)) {
                    c++;
                    if (!verbose) {
                        stdout.printf(_("%d photographs exported…%s"),
                                      c, "\r\b");
                        stdout.flush();
                    }
                }
            }
            return c;
        }

        private static bool open_database() {
            var path = string.join(GLib.Path.DIR_SEPARATOR_S,
                                   GLib.Environment.get_user_data_dir(),
                                   "shotwell", "data", "photo.db");
            if (Sqlite.Database.open(path, out db) != Sqlite.OK) {
                stderr.printf(_("Cannot open database: %s\n"), db.errmsg());
                db = null;
                return false;
            }
            return true;
        }

        private static void do_exporting(string[] args) {
            if (!open_database())
                return;
            if (db.exec("BEGIN TRANSACTION") != Sqlite.OK) {
                stderr.printf(_("Cannot begin transaction: %s\n"), db.errmsg());
                db = null;
                return;
            }
            try {
                events = new Gee.TreeMap<string, Event>();
                var photos = !files ?
                    Util.load_photos_dir(args[1], progress) :
                    Util.load_photos_array(args, 1, progress);
                stdout.printf(_("Exporting %d photographs…\n"), photos.size);
                int c = export_photos(photos);
                stdout.printf(_("%d photographs exported.\n"), c);
            } catch (GLib.Error e) {
                if (db.exec("ROLLBACK") != Sqlite.OK) {
                    stderr.printf(_("Cannot rollback transaction: %s\n"),
                                  db.errmsg());
                }
                db = null;
                Util.error(_("Error while exporting: %s"), e.message);
            }
            if (db.exec("COMMIT") != Sqlite.OK)
                stderr.printf(_("Cannot commit transaction: %s\n"),
                              db.errmsg());
            db = null;
        }

        private static int search_cover(string year, string month,
                                         string _event, string hl)
            throws GLib.Error {
            int y = int.parse(year);
            int m = int.parse(month);
            var s_path = string.join(GLib.Path.DIR_SEPARATOR_S,
                                     year, month, _event, hl);
            int rc;
            Sqlite.Statement stmt;
            rc = db.prepare_v2(SELECT_PHOTO_PATH_LIKE_QUERY,
                               -1, out stmt, null);
            if (rc != Sqlite.OK) {
                stderr.printf(_("SQL error: %d, %s\n"), rc, db.errmsg());
                return 0;
            }
            stmt.bind_text(1, "%" + s_path + "%");
            while (stmt.step() == Sqlite.ROW) {
                var photo_id = stmt.column_int(PhotoColumn.ID);
                var event_id = stmt.column_int(PhotoColumn.EVENT_ID);
                var filename = stmt.column_text(PhotoColumn.FILENAME);
                var file = GLib.File.new_for_path(filename);
                var photo = new Photograph(file);
                if (y == photo.datetime.get_year() &&
                    m == photo.datetime.get_month()) {
                    if (verbose)
                        stdout.printf(_("Updating cover for %s…\n"), s_path);
                    if (do_update_event(event_id, photo_id))
                        return 1;
                    return 0;
                }
            }
            return 0;
        }

        private static int parse_covers(Json.Object root) throws GLib.Error {
            int c = 0;
            var years = root.get_members();
            foreach (string year in years) {
                var y = root.get_object_member(year);
                if (!y.has_member("months"))
                    continue;
                var ms = y.get_object_member("months");
                var months = ms.get_members();
                foreach (string month in months) {
                    var m = ms.get_object_member(month);
                    if (!m.has_member("events"))
                        continue;
                    var es = m.get_object_member("events");
                    var events = es.get_members();
                    foreach (var _event in events) {
                        var e = es.get_object_member(_event);
                        if (!e.has_member("highlight"))
                            continue;
                        var hl = e.get_string_member("highlight");
                        c += search_cover(year, month, _event, hl);
                        if (!verbose)
                            stdout.printf(_("%d covers set.%s"), c, "\r\b");
                        stdout.flush();
                    }
                }
            }
            return c;
        }

        private static void do_covers() {
            if (!open_database())
                return;
            if (db.exec("BEGIN TRANSACTION") != Sqlite.OK) {
                stderr.printf(_("Cannot begin transaction: %s\n"), db.errmsg());
                db = null;
                return;
            }
            try {
                stdout.printf(_("Setting covers…\n"));
                var parser = new Json.Parser();
                parser.load_from_file(covers);
                var root = parser.get_root().get_object();
                int c = parse_covers(root);
                stdout.printf(_("%d covers set.\n"), c);
            } catch (GLib.Error e) {
                if (db.exec("ROLLBACK") != Sqlite.OK) {
                    stderr.printf(_("Cannot rollback transaction: %s\n"),
                                  db.errmsg());
                }
                db = null;
                Util.error(_("Error while setting primary photos: %s"),
                           e.message);
            }
            if (db.exec("COMMIT") != Sqlite.OK)
                stderr.printf(_("Cannot commit transaction: %s\n"),
                              db.errmsg());
            db = null;
        }

        public static int main(string[] args) {
            GLib.Intl.setlocale(LocaleCategory.ALL, "");
            files = verbose = false;
            covers = null;
            try {
                var opt = new GLib.OptionContext(CONTEXT);
                opt.set_help_enabled(true);
                opt.add_main_entries(get_options(), null);
                opt.parse(ref args);
            } catch (GLib.Error e) {
                stderr.printf("%s\n", e.message);
                Util.error(_("Run ‘%s --help’ for a list of options"), args[0]);
            }

            if (files && covers != null)
                Util.error(_("You cannot mix -c and -f"));

            if (covers != null) {
                if (args.length > 1)
                    Util.error(_("The -c option only needs one file"));
                do_covers();
                return 0;
            }

            if (args.length < 2) {
                Util.error(_("Missing files or directory"));
            } else if (!files) {
                if (!GLib.FileUtils.test(args[1], GLib.FileTest.IS_DIR) ||
                    args.length != 2)
                    Util.error(_("%s is not a directory"), args[1]);
            } else if (files) {
                for (int i = 1; i < args.length; i++) {
                    if (!GLib.FileUtils.test(args[i], GLib.FileTest.IS_REGULAR))
                        Util.error(_("%s is not a file"), args[i]);
                }
            }
            do_exporting(args);

            return 0;
        }
    }
}
