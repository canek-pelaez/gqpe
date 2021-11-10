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
    }
}
