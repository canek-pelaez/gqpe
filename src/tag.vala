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
         * Date and time tag.
         */
        public const string DATE_TIME = "Exif.Photo.DateTimeOriginal";

        /**
         * Orientation tag.
         */
        public const string ORIENTATION = "Exif.Image.Orientation";

        /**
         * Thumbnail orientation tag.
         */
        public const string THUMB_ORIENTATION = "Exif.Thumbnail.Orientation";

        /**
         * Subject tag.
         */
        public const string SUBJECT = "Xmp.dc.subject";

        /**
         * Caption tag.
         */
        public const string CAPTION = "Iptc.Application2.Caption";

        /**
         * Description tag.
         */
        public const string DESCRIPTION = "Exif.Image.ImageDescription";

        /**
         * Latitude tag.
         */
        public const string LATITUDE = "Exif.GPSInfo.GPSLatitude";

        /**
         * Longitude tag.
         */
        public const string LONGITUDE = "Exif.GPSInfo.GPSLongitude";

        /**
         * Latitude reference tag.
         */
        public const string LATITUDE_REF = "Exif.GPSInfo.GPSLatitudeRef";

        /**
         * Longitude reference tag.
         */
        public const string LONGITUDE_REF = "Exif.GPSInfo.GPSLongitudeRef";

        /**
         * GPS tag tag.
         */
        public const string GPS_TAG = "Exif.Image.GPSTag";

        /**
         * GPS version tag.
         */
        public const string GPS_VERSION = "Exif.GPSInfo.GPSVersionID";

        /**
         * GPS datum tag.
         */
        public const string GPS_DATUM = "Exif.GPSInfo.GPSMapDatum";

        /**
         * GPS date tag.
         */
        public const string GPS_DATE = "Exif.GPSInfo.GPSDateStamp";

        /**
         * GPS time tag.
         */
        public const string GPS_TIME = "Exif.GPSInfo.GPSTimeStamp";
    }
}
