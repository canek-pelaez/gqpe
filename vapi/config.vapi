/* config.vapi
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

[CCode (lower_case_cprefix = "", cheader_filename = "config.h")]
namespace Config {

    /**
     * Package name.
     */
    public const string PACKAGE_NAME;

    /**
     * Package string.
     */
    public const string PACKAGE_STRING;

    /**
     * Package version.
     */
    public const string PACKAGE_VERSION;

    /**
     * Gettext package.
     */
    public const string GETTEXT_PACKAGE;

    /**
     * Locale dir.
     */
    public const string LOCALEDIR;

    /**
     * Package data dir.
     */
    public const string PKGDATADIR;

    /**
     * Package library dir.
     */
    public const string PKGLIBDIR;
}
