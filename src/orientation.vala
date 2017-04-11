/* orientation.vala
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
     * Enumeration for orientations.
     *
     * //[[http://www.exif.org/Exif2-2.PDF#page=24|Exif Version 2.2, page 18]].//
     */
    public enum Orientation {

        /**
         * 0° clockwise orientation.
         */
        LANDSCAPE         = 1,

        /**
         * 180° orientation.
         */
        REVERSE_LANDSCAPE = 3,

        /**
         * 90° orientation.
         */
        PORTRAIT          = 6,

        /**
         * 270° orientation.
         */
        REVERSE_PORTRAIT  = 8
    }
}
