/*
 * This file is part of gqpe.
 *
 * Copyright © 2017-2021 Canek Peláez Valdés
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
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *    Canek Peláez Valdés <canek@ciencias.unam.mx>
 */

namespace GQPE {

    /**
     * Class for cities.
     */
    public class City : GLib.Object {

        /**
         * The city identifier.
         */
        public int id { public get; private set; }

        /**
         * The city name.
         */
        public string name { public get; private set; }

        /**
         * The city country.
         */
        public string country { public get; private set; }

        /**
         * The city population.
         */
        public int population { public get; private set; }

        /**
         * The city latitude.
         */
        public double latitude { public get; private set; }

        /**
         * The city longitude.
         */
        public double longitude { public get; private set; }

        /**
         * Creates a new city with the required data.
         * @param id the city identifier.
         * @param name the city name.
         * @param name the city country.
         * @param name the city population.
         * @param name the city latitude.
         * @param name the city longitude.
         */
        public City(int id, string name,
                    string country, int population,
                    double latitude, double longitude) {
            this.id = id;
            this.name = name;
            this.country = country;
            this.population = population;
            this.latitude = latitude;
            this.longitude = longitude;
        }
    }
}
