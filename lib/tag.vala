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
     * Constants for the used tags.
     */
    public enum Tag {

        /**
         * Title tag.
         */
        TITLE,

        /**
         * Album tag.
         */
        ALBUM,

        /**
         * Description tag.
         */
        DESCRIPTION,

        /**
         * Date and time tag.
         */
        DATETIME,

        /**
         * The timezone offset
         */
        TIMEZONE_OFFSET,

        /**
         * Orientation tag.
         */
        ORIENTATION,

        /**
         * Thumbnail orientation tag.
         */
        THUMB_ORIENTATION,

        /**
         * Latitude tag.
         */
        LATITUDE,

        /**
         * Longitude tag.
         */
        LONGITUDE,

        /**
         * Latitude reference tag.
         */
        LATITUDE_REF,

        /**
         * Longitude reference tag.
         */
        LONGITUDE_REF,

        /**
         * GPS tag tag.
         */
        GPS_TAG,

        /**
         * GPS version tag.
         */
        GPS_VERSION,

        /**
         * GPS datum tag.
         */
        GPS_DATUM,

        /**
         * GPS date tag.
         */
        GPS_DATE,

        /**
         * GPS time tag.
         */
        GPS_TIME;

        /**
         * Returns the tag.
         * @return the tag.
         */
        public string tag() {
            switch (this) {
            case TITLE:             return "Iptc.Application2.Caption";
            case ALBUM:             return "Xmp.dc.subject";
            case DESCRIPTION:       return "Exif.Image.ImageDescription";
            case DATETIME:          return "Exif.Photo.DateTimeOriginal";
            case TIMEZONE_OFFSET:   return "Exif.Image.TimeZoneOffset";
            case ORIENTATION:       return "Exif.Image.Orientation";
            case THUMB_ORIENTATION: return "Exif.Thumbnail.Orientation";
            case LATITUDE:          return "Exif.GPSInfo.GPSLatitude";
            case LONGITUDE:         return "Exif.GPSInfo.GPSLongitude";
            case LATITUDE_REF:      return "Exif.GPSInfo.GPSLatitudeRef";
            case LONGITUDE_REF:     return "Exif.GPSInfo.GPSLongitudeRef";
            case GPS_TAG:           return "Exif.Image.GPSTag";
            case GPS_VERSION:       return "Exif.GPSInfo.GPSVersionID";
            case GPS_DATUM:         return "Exif.GPSInfo.GPSMapDatum";
            case GPS_DATE:          return "Exif.GPSInfo.GPSDateStamp";
            case GPS_TIME:          return "Exif.GPSInfo.GPSTimeStamp";
            }
            return "Invalid.Tag";
        }
    }
}
