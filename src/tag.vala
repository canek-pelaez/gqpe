/* tag.vala
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
     * Constants for the used tags.
     */
    public class Tag {

        /**
         * Orientation tag.
         */
        public static const string ORIENTATION =
            "Exif.Image.Orientation";

        /**
         * Thumbnail orientation tag.
         */
        public static const string THUMB_ORIENTATION =
            "Exif.Thumbnail.Orientation";

        /**
         * Subject tag.
         */
        public static const string SUBJECT =
            "Xmp.dc.subject";

        /**
         * Caption tag.
         */
        public static const string CAPTION =
            "Iptc.Application2.Caption";

        /**
         * Description tag.
         */
        public static const string DESCRIPTION =
            "Exif.Image.ImageDescription";

        /**
         * Latitude tag.
         */
        public static const string LATITUDE =
            "Exif.GPSInfo.GPSLatitude";

        /**
         * Longitude tag.
         */
        public static const string LONGITUDE =
            "Exif.GPSInfo.GPSLongitude";

        /**
         * Latitude reference tag.
         */
        public static const string LATITUDE_REF =
            "Exif.GPSInfo.GPSLatitudeRef";

        /**
         * Longitude reference tag.
         */
        public static const string LONGITUDE_REF =
            "Exif.GPSInfo.GPSLongitudeRef";
    }
}
