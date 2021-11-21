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
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *    Canek Peláez Valdés <canek@ciencias.unam.mx>
 */

namespace GQPE {

    /**
     * Class for utility functions.
     */
    public class Util {

        /* Whether the get_colorize() function has been called. */
        private static bool get_colorize_called = false;
        /* Whether to colorize. */
        private static bool colorize = true;
        /* The don't colorize environment variable. */
        private const string GQPE_DONT_COLORIZE = "GQPE_DONT_COLORIZE";

        /**
         * Returns a colorized message.
         * @param message the message.
         * @param color the color.
         * @return a colorized message.
         */
        public static string color(string message, Color color) {
            if (!get_colorize() || color == Color.NONE)
                return message;
            return "\033[1m\033[9%dm%s\033[0m".printf(color, message);
        }

        /**
         * Whether to colorize or not.
         * @return ''true'' if we should colorize; ''false'' otherwise.
         */
        private static bool get_colorize() {
            if (get_colorize_called)
                return colorize;
            get_colorize_called = true;
            colorize = GLib.Environment.get_variable(GQPE_DONT_COLORIZE) != "1";
            return colorize;
        }


        /**
         * Returns the modification time of a file.
         * @param filename the file name.
         * @return the modification time of a file.
         */
        public static GLib.DateTime get_file_datetime(string filename) {
            try {
                var file = GLib.File.new_for_path(filename);
                var info = file.query_info("time::modified",
                                           GLib.FileQueryInfoFlags.NONE);
                return info.get_modification_date_time();
            } catch (GLib.Error e) {
                GLib.warning("There was an error reading from ‘%s’.\n", filename);
            }
            return new GLib.DateTime.now_local();
        }

        /**
         * Sets the modification time of a file.
         * @param filename the file name.
         * @param time the modification time.
         */
        public static void set_file_datetime(string filename,
                                             GLib.DateTime time) {
            try {
                var file = GLib.File.new_for_path(filename);
                var info = new GLib.FileInfo();
                info.set_modification_date_time(time);
                file.set_attributes_from_info(info, GLib.FileQueryInfoFlags.NONE);
            } catch (GLib.Error e) {
                GLib.warning("There was an error writing to ‘%s’.\n", filename);
            }
        }

        /**
         * Returns the NFKD normalization and ASCII conversion of a string.
         * @param str the string.
         * @return the NFKD normalization and ASCII conversion of the string.
         */
        public static string normalize(string str) {
            var s = str.normalize(-1, GLib.NormalizeMode.NFKD);
            try {
                uint8[] outbuf = new uint8[s.length + 1]; // '\0' at end.
                size_t read = s.length;
                size_t written = 0;

                var conv = new GLib.CharsetConverter("ASCII//IGNORE", "UTF-8");
                var r = conv.convert(s.data, outbuf, ConverterFlags.NONE,
                                     out read, out written);
                string t = (string)outbuf;

                if (r == GLib.ConverterResult.ERROR)
                    return "";

                t = t.down();
                var regex = new GLib.Regex("[ /-]");
                t = regex.replace(t, t.length, 0, "_");
                regex = new GLib.Regex("[^A-Za-z0-9_-]");
                t = regex.replace(t, t.length, 0, "");
                return t;
            } catch (GLib.Error e) {
                GLib.warning("%s", e.message);
            }
            return "";
        }

        public static string normalize_basename(string basename) {
            var n = Util.normalize(Util.get_name(basename));
            var e = Util.normalize(Util.get_extension(basename));
            return "%s.%s".printf(n, e);
        }

        public static string get_name(string path) {
            int i = path.last_index_of(".");
            if (i == 0 || i == -1)
                return "";
            return path[:i];
        }

        public static string get_extension(string path) {
            int i = path.last_index_of(".");
            if (i == 0 || i == -1)
                return "";
            return path[i+1:];
        }
    }
}
