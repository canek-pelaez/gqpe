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
     * Galería application.
     */
    public class Galeria {

        /* List of albums. */
        private static bool list_albums;
        /* List of photographs. */
        private static bool list_photos;
        /* Random photograph. */
        private static bool random_photo;
        /* Get covers. */
        private static bool get_covers;
        /* Upload photographs. */
        private static bool upload_photos;
        /* Delete item. */
        private static bool delete_item;
        /* Reset covers. */
        private static bool reset_covers;
        /* Set covers. */
        private static bool set_covers;

        /* Page of list of albums. */
        private static int albums_page;
        /* Page of list of photographs. */
        private static int photos_page;
        /* Random photo black list. */
        private static string blacklist;
        /* Covers output file. */
        private static string output;
        /* Upload directory. */
        private static string directory;
        /* Delete path. */
        private static string delete_path;
        /* Reset path. */
        private static string reset_path;
        /* JSON covers. */
        private static string covers;

        /* Galería URL. */
        private static string url;
        /* Galería token. */
        private static string token;

        /* The settings. */
        private static GLib.Settings settings;
        /* The session. */
        private static Soup.Session session;
        /* The secret schema. */
        private static Secret.Schema schema;

        /* List albums URL path. */
        private const string LIST_ALBUMS   = "/rest/list-albums";
        /* List photos URL path. */
        private const string LIST_PHOTOS   = "/rest/list-photos";
        /* Random photo URL path. */
        private const string RANDOM_PHOTO  = "/rest/random-photo";
        /* Get covers URL path. */
        private const string GET_COVERS    = "/rest/get-covers";
        /* Uplod photos URL path. */
        private const string UPLOAD_PHOTOS = "/rest/upload-photos";
        /* Delete item URL path. */
        private const string DELETE_ITEM   = "/rest/delete-item";
        /* Reset covers URL path. */
        private const string RESET_COVERS  = "/rest/reset-covers";
        /* Set covers URL path. */
        private const string SET_COVERS    = "/rest/set-covers";

        /* Number of options. */
        private static int n_options;
        /* Number of arguments. */
        private static int n_arguments;

        /* The option context. */
        private const string CONTEXT = _(" - Execute Galería REST API method.");

        /* Returns the general options. */
        private static GLib.OptionEntry[] get_general_options() {
            GLib.OptionEntry[] options = {
                { "url", 'u', 0, GLib.OptionArg.STRING,
                  &url, _("Set the Galería site URL"), "URL" },
                { "token", 't', 0, GLib.OptionArg.STRING,
                  &token, _("Set the Galería site token"), "TOKEN" },
                { null }
            };
            return options;
        }

        /* Returns the list-albums options. */
        private static GLib.OptionEntry[] get_list_albums_options() {
            GLib.OptionEntry[] options = {
                { "albums-page", '\0', 0, GLib.OptionArg.INT, &albums_page,
                  _("The page of albums to get"), "PAGE" },
                { null }
            };
            return options;
        }

        /* Returns the list-photos options. */
        private static GLib.OptionEntry[] get_list_photos_options() {
            GLib.OptionEntry[] options = {
                { "photos-page", '\0', 0, GLib.OptionArg.INT, &photos_page,
                  _("The page of photographs to get"), "PAGE" },
                { null }
            };
            return options;
        }

        /* Returns the list-photos options. */
        private static GLib.OptionEntry[] get_random_photo_options() {
            GLib.OptionEntry[] options = {
                { "blacklist", 'b', 0, GLib.OptionArg.STRING, &blacklist,
                  _("Blacklisted terms"), "TERMS" },
                { null }
            };
            return options;
        }

        /* Returns the get-covers options. */
        private static GLib.OptionEntry[] get_get_covers_options() {
            GLib.OptionEntry[] options = {
                { "output", 'o', 0, GLib.OptionArg.FILENAME, &output,
                  _("Send covers to an output file"), "FILENAME" },
                { null }
            };
            return options;
        }

        /* Returns the upload-photos options. */
        private static GLib.OptionEntry[] get_upload_photos_options() {
            GLib.OptionEntry[] options = {
                { "directory", 'd', 0, GLib.OptionArg.FILENAME,
                  &directory, _("The directory to upload"),
                  "DIRECTORY" },
                { null }
            };
            return options;
        }

        /* Returns the delete-item options. */
        private static GLib.OptionEntry[] get_delete_item_options() {
            GLib.OptionEntry[] options = {
                { "delete-path", '\0', 0, GLib.OptionArg.STRING,
                  &delete_path, _("The path to delete"), "PATH" },
                { null }
            };
            return options;
        }

        /* Returns the reset-covers options. */
        private static GLib.OptionEntry[] get_reset_covers_options() {
            GLib.OptionEntry[] options = {
                { "reset-path", '\0', 0, GLib.OptionArg.STRING,
                  &reset_path, _("The path to reset"), "PATH" },
                { null }
            };
            return options;
        }

        /* Returns the set-covers options. */
        private static GLib.OptionEntry[] get_set_covers_options() {
            GLib.OptionEntry[] options = {
                { "covers", 'c', 0, GLib.OptionArg.FILENAME,
                  &covers, _("The JSON file with the covers"), "JSON" },
                { null }
            };
            return options;
        }

        /* Returns the main options. */
        private static GLib.OptionEntry[] get_main_options() {
            GLib.OptionEntry[] options = {
                { "list-albums", '\0', 0, GLib.OptionArg.NONE, &list_albums,
                  _("Get a list of the albums"), null },
                { "list-photos", '\0', 0, GLib.OptionArg.NONE, &list_photos,
                  _("Get a list of the photos"), null },
                { "random-photo", '\0', 0, GLib.OptionArg.NONE, &random_photo,
                  _("Get a random photograph"), null },
                { "upload-photos", '\0', 0, GLib.OptionArg.NONE, &upload_photos,
                  _("Upload photographs"), null },
                { "delete-item", '\0', 0, GLib.OptionArg.NONE, &delete_item,
                  _("Delete photographs or albums"), null },
                { "reset-covers", '\0', 0, GLib.OptionArg.NONE,
                  &reset_covers, _("Resets the album covers"), null },
                { "get-covers", '\0', 0, GLib.OptionArg.NONE,
                  &get_covers, _("Get the album covers"), null },
                { "set-covers", '\0', 0, GLib.OptionArg.NONE,
                  &set_covers, _("Set the album covers"), null },
                { null }
            };
            return options;
        }

        /* Parse response. */
        private static void parse_response(Soup.Message message) {
            var parser = new Json.Parser();
            try {
                parser.load_from_data((string)message.response_body.data);
            } catch (GLib.Error e) {
                stderr.printf(_("Invalid response from server"));
                return;
            }
            var root = parser.get_root().get_object();
            if (!root.has_member("response") || !root.has_member("message")) {
                stderr.printf(_("Problem getting response from server"));
                return;
            }
            var response = root.get_string_member("response");
            if (response == "success")
                return;
            var m = root.get_string_member("message");
            stderr.printf(_("Operation failed: %s\n"), m);
        }

        /* Outputs response. */
        private static void output_response(Soup.Message message) {
            if (output == null) {
                stdout.printf("%s\n", (string)message.response_body.data);
            } else {
                try {
                    var file = GLib.File.new_for_path(output);
                    var ios = file.create_readwrite(GLib.FileCreateFlags.NONE);
                    var o = ios.output_stream as FileOutputStream;
                    o.write(message.response_body.data);
                } catch (GLib.Error e) {
                    Util.error(_("Error writing output file: %s"), output);
                }
            }
        }

        /* Loading progress callback. */
        private static void loading_progress(ProgressState state, int number) {
            switch (state) {
            case INIT:
                stdout.printf(_("Loading photographs…\n"));
                break;
            case ADVANCE:
                stdout.printf(_("Loaded %d photographs…%s"), number, "\r\b");
                stdout.flush();
                break;
            case END:
                stdout.printf(_("Loaded %d photographs.\n"), number);
                break;
            }
        }

        /* HTTP GET method. */
        private static void get_method(string method,
                                       string error_message,
                                       string? p_name = null,
                                       string? p_value = null) {
            var u = url + method;
            if (p_name != null && p_value != null)
                u += "?%s=%s".printf(p_name, p_value);
            var message = new Soup.Message("GET", u);
            if (token != null)
                message.request_headers.append("Authorization",
                                               "Token " + token);
            session.send_message(message);
            if (message.status_code != Soup.Status.OK)
                Util.error(error_message);
            output_response(message);
        }

        /* HTTP POST upload photo method. */
        private static void upload_photo(Photograph photo) {
            uint8[] data = Util.load_file_data(photo.file);
            if (data == null) {
                stderr.printf(_("Error loading %s, skipping…\n"), photo.path);
                return;
            }
            var u = url + UPLOAD_PHOTOS;
            var multipart = new Soup.Multipart(Soup.FORM_MIME_TYPE_MULTIPART);
            var buffer = new Soup.Buffer.take(data);
            multipart.append_form_file("files", photo.file.get_basename(),
                                       "application/jpeg", buffer);
            var message = Soup.Form.request_new_from_multipart(u, multipart);
            message.request_headers.append("Authorization", "Token " + token);
            session.send_message(message);
            if (message.status_code != Soup.Status.OK)
                Util.error(_("Error uploading %s"), photo.path);
            parse_response(message);
        }

        /* List albums. */
        private static void do_list_albums(string[] args) {
            if (args.length > 1)
                Util.use("Invalid argument: %s", args[1]);
            if ((albums_page == int.MIN && n_arguments > 0) ||
                (albums_page != int.MIN && n_arguments > 1))
                Util.use(_("Only --albums-page is valid for --list-albums"));
            var page = albums_page != int.MIN ? "%d".printf(albums_page) : null;
            get_method(LIST_ALBUMS, _("Error calling list-albums"),
                       "page", page);
        }

        /* List photos. */
        private static void do_list_photos(string[] args) {
            if (args.length > 1)
                Util.use("Invalid argument: %s", args[1]);
            if ((photos_page == int.MIN && n_arguments > 0) ||
                (photos_page != int.MIN && n_arguments > 1))
                Util.use(_("Only --photos-page is valid for --list-photos"));
            var page = photos_page != int.MIN ? "%d".printf(photos_page) : null;
            get_method(LIST_PHOTOS, _("Error calling list-photos"),
                       "page", page);
        }

        /* Random photo. */
        private static void do_random_photo(string[] args) {
            if (args.length > 1)
                Util.use("Invalid argument: %s", args[1]);
            if ((blacklist == null && n_arguments > 0) ||
                (blacklist != null && n_arguments > 1))
                Util.use(_("Only --blacklist is valid for --random-photo"));
            get_method(RANDOM_PHOTO, _("Error calling random-photo"),
                       "blacklist", blacklist);
        }

        /* Get covers. */
        private static void do_get_covers(string[] args) {
            if (args.length > 1)
                Util.use("Invalid argument: %s", args[1]);
            if (n_arguments > 0)
                Util.use(_("Option --get-covers has no arguments"));
            get_method(GET_COVERS, _("Error calling get-covers"));
        }

        /* Upload photos. */
        private static void do_upload_photos(string[] args) {
            if (directory == null && args.length < 2)
                Util.use(_("Missing files or directory"));
            if ((directory == null && n_arguments > 0) ||
                (directory != null && n_arguments > 1))
                Util.use(_("Only --directory is valid for --upload-photos"));
            Gee.SortedSet<Photograph> photos = null;
            try {
                if (directory != null) {
                    if (!GLib.FileUtils.test(directory, GLib.FileTest.IS_DIR))
                        Util.use(_("%s is not a directory"), directory);
                    photos = Util.load_photos_dir(directory, loading_progress);
                } else {
                    photos = Util.load_photos_array(args, 1, loading_progress);
                }
            } catch (GLib.Error e) {
                var m = _("Error loading photos, trying to continue: %s\n");
                stderr.printf(m, e.message);
            }
            int c = 0;
            foreach (var photo in photos) {
                stdout.printf(_("Uploading %d of %d: %s…\n"), ++c, photos.size,
                              photo.path);
                upload_photo(photo);
            }
        }

        /* Delete item. */
        private static void do_delete_item(string[] args) {
            if (args.length > 1)
                Util.use("Invalid argument: %s", args[1]);
            if (delete_path == null)
                Util.use(_("Missing path to delete"));
            if (n_arguments > 1)
                Util.use(_("Only --delete-path is valid for --delete-items"));
            get_method(DELETE_ITEM, _("Error calling delete-item"),
                       "path", delete_path);
        }

        /* Reset covers. */
        private static void do_reset_covers(string[] args) {
            if (args.length > 1)
                Util.use("Invalid argument: %s", args[1]);
            if ((reset_path == null && n_arguments > 0) ||
                (reset_path != null && n_arguments > 1))
                Util.use(_("Only --reset-path is valid for --reset-covers"));
            get_method(RESET_COVERS, _("Error calling reset-covers"),
                       "path", reset_path);
        }

        /* Set covers. */
        private static void do_set_covers(string[] args) {
            if (args.length > 1)
                Util.use("Invalid argument: %s", args[1]);
            if (covers == null)
                Util.use(_("Missing covers JSON"));
            if (n_arguments > 1)
                Util.use(_("Only --covers-json is valid for --set-covers"));
            var file = GLib.File.new_for_path(covers);
            uint8[] data = Util.load_file_data(file);
            if (data == null) {
                stderr.printf(_("Error loading %s, skipping…\n"), covers);
                return;
            }
            var u = url + SET_COVERS;
            var message = new Soup.Message("POST", u);
            message.set_request("application/json", Soup.MemoryUse.COPY, data);
            message.request_headers.append("Authorization", "Token " + token);
            session.send_message(message);
            if (message.status_code != Soup.Status.OK)
                Util.error(_("Error setting covers"));
            output_response(message);
        }

        /* Checks the Galería URL availability. */
        private static void check_galeria_url() {
            if (url == null || url == "")
                url = GLib.Environment.get_variable("GQPE_GALERIA_URL");
            if (url == null || url == "")
                url = settings.get_string("url");
            if (url == null || url == "")
                Util.error(_("Galería URL is undefined"));
            if (url.has_suffix("/")) {
                int n = url.length;
                url = url.substring(0, n-1);
            }
        }

        /* Checks the Galería token availability. */
        private static void check_galeria_token() {
            if (token == null || token == "")
                token = GLib.Environment.get_variable("GQPE_GALERIA_TOKEN");
            if (token == null || token == "")
                lookup_token();
            if (token == null || token == "")
                Util.error(_("Galería token is undefined"));
        }

        /* Get the number of options. */
        private static int get_n_options() {
            int r = 0;
            r += list_albums   ? 1 : 0;
            r += list_photos   ? 1 : 0;
            r += random_photo  ? 1 : 0;
            r += upload_photos ? 1 : 0;
            r += delete_item   ? 1 : 0;
            r += reset_covers  ? 1 : 0;
            r += get_covers    ? 1 : 0;
            r += set_covers    ? 1 : 0;
            return r;
        }

        /* Get the number of arguments. */
        private static int get_n_arguments() {
            int r = 0;
            r += albums_page != int.MIN ? 1 : 0;
            r += photos_page != int.MIN ? 1 : 0;
            r += blacklist != null      ? 1 : 0;
            r += output != null         ? 1 : 0;
            r += directory != null      ? 1 : 0;
            r += delete_path != null    ? 1 : 0;
            r += reset_path != null     ? 1 : 0;
            r += covers != null         ? 1 : 0;
            return r;
        }

        /* Inits the program state. */
        private static string[] init_program(string[] args) {
            list_albums = list_photos = random_photo = upload_photos =
                delete_item = reset_covers = get_covers = set_covers = false;
            albums_page = photos_page = int.MIN;
            try {
                var context = new GLib.OptionContext(CONTEXT);
                context.set_help_enabled(true);

                var g = new GLib.OptionGroup("general",
                                             _("General options"),
                                             _("Show general options"),
                                             null, null);
                g.add_entries(get_general_options());
                context.add_group(g);

                var la = new GLib.OptionGroup("list-albums",
                                              _("List albums options"),
                                              _("Show list-albums options"),
                                              null, null);
                la.add_entries(get_list_albums_options());
                context.add_group(la);

                var lp = new GLib.OptionGroup("list-photos",
                                              _("List photos options"),
                                              _("Show list-photos options"),
                                              null, null);
                lp.add_entries(get_list_photos_options());
                context.add_group(lp);

                var rp = new GLib.OptionGroup("random-photo",
                                              _("Random photo options"),
                                              _("Show random-photo options"),
                                              null, null);
                rp.add_entries(get_random_photo_options());
                context.add_group(rp);

                var gc = new GLib.OptionGroup("get-covers",
                                              _("Get covers options"),
                                              _("Show get-covers options"));
                gc.add_entries(get_get_covers_options());
                context.add_group(gc);

                var up = new GLib.OptionGroup("upload-photos",
                                              _("Upload photos options"),
                                              _("Show upload-photos options"),
                                              null, null);
                up.add_entries(get_upload_photos_options());
                context.add_group(up);

                var di = new GLib.OptionGroup("delete-item",
                                              _("Delete item options"),
                                              _("Show delete-item options"),
                                              null, null);
                di.add_entries(get_delete_item_options());
                context.add_group(di);

                var rc = new GLib.OptionGroup("reset-covers",
                                              _("Reset covers options"),
                                              _("Show reset-covers options"));
                rc.add_entries(get_reset_covers_options());
                context.add_group(rc);

                var sc = new GLib.OptionGroup("set-covers",
                                              _("Set covers options"),
                                              _("Show set-covers options"));
                sc.add_entries(get_set_covers_options());
                context.add_group(sc);

                context.add_main_entries(get_main_options(), null);
                context.parse(ref args);
            } catch (GLib.Error e) {
                Util.use(e.message);
            }

            settings = new GLib.Settings("mx.unam.GQPE");
            check_galeria_url();

            n_options = get_n_options();
            if (n_options != 1)
                Util.use(_("Exactly one option is necessary"));
            n_arguments = get_n_arguments();

            session = new Soup.Session();
            schema = new Secret.Schema ("mx.unam.GQPE",
                                            Secret.SchemaFlags.NONE,
                                            "gqpe-galeria-token",
                                            Secret.SchemaAttributeType.STRING);
            return args;
        }

        /* Looks up the token in the Secrets. */
        private static void lookup_token() {
            var cancellable = new GLib.Cancellable();
            try {
                token = Secret.password_lookup_sync(schema, cancellable,
                                                    "gqpe-galeria-token",
                                                    "token");
            } catch (GLib.Error e) {
                GLib.warning(_("Unable to retrieve the Galería token: %s"),
                             e.message);
            }
        }

        /* Stores the token in the Secrets. */
        private static void store_token() {
            var label = _("GQPE Galería token");
            try {
                Secret.password_store_sync(schema,
                                           Secret.COLLECTION_DEFAULT,
                                           label, token, null,
                                           "gqpe-galeria-token", "token");
            } catch (GLib.Error e) {
                GLib.warning(_("Unable to store the Galería token: %s"),
                             e.message);
            }
        }

        public static int main(string[] args) {
            GLib.Intl.setlocale(LocaleCategory.ALL, "");
            var p_args = init_program(args);

            if (list_albums) {
                do_list_albums(p_args);
            } else if (list_photos) {
                do_list_photos(p_args);
            } else if (random_photo) {
                do_random_photo(p_args);
            } else if (get_covers) {
                do_get_covers(p_args);
            } else {
                check_galeria_token();
            }

            if (upload_photos) {
                do_upload_photos(p_args);
            } else if (delete_item) {
                do_delete_item(p_args);
            } else if (reset_covers) {
                do_reset_covers(p_args);
            } else if (set_covers) {
                do_set_covers(p_args);
            }

            settings.set_string("url", url);
            if (token != null)
                store_token();
            return 0;
        }
    }
}