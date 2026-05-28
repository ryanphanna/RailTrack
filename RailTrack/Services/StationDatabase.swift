import Foundation

/// A bundled, searchable list of key stations for VIA Rail, Amtrak, and GO Transit.
/// Used by AddTripView for station autocomplete.
struct StationDatabase {

    static let shared = StationDatabase()
    private init() {}

    let stations: [Station] = [

        // MARK: VIA Rail
        Station(id: "VIA-TRTO", name: "Toronto Union Station",    shortName: "Toronto",   code: "TOR",
                coordinate: Coordinate(latitude: 43.6453, longitude: -79.3806),
                timezone: "America/Toronto", railOperator: "VIA", city: "Toronto", country: "CA"),

        Station(id: "VIA-OTTW", name: "Ottawa Station",           shortName: "Ottawa",    code: "OTT",
                coordinate: Coordinate(latitude: 45.4168, longitude: -75.6561),
                timezone: "America/Toronto", railOperator: "VIA", city: "Ottawa", country: "CA"),

        Station(id: "VIA-MTRL", name: "Montréal Central Station", shortName: "Montréal",  code: "MTL",
                coordinate: Coordinate(latitude: 45.4994, longitude: -73.5686),
                timezone: "America/Toronto", railOperator: "VIA", city: "Montréal", country: "CA"),

        Station(id: "VIA-KGON", name: "Kingston Station",         shortName: "Kingston",  code: "KGN",
                coordinate: Coordinate(latitude: 44.2312, longitude: -76.5010),
                timezone: "America/Toronto", railOperator: "VIA", city: "Kingston", country: "CA"),

        Station(id: "VIA-OSHW", name: "Oshawa Station",           shortName: "Oshawa",    code: "OSH",
                coordinate: Coordinate(latitude: 43.8975, longitude: -78.8658),
                timezone: "America/Toronto", railOperator: "VIA", city: "Oshawa", country: "CA"),

        Station(id: "VIA-COBG", name: "Cobourg Station",          shortName: "Cobourg",   code: "COB",
                coordinate: Coordinate(latitude: 43.9591, longitude: -78.1649),
                timezone: "America/Toronto", railOperator: "VIA", city: "Cobourg", country: "CA"),

        Station(id: "VIA-BVLE", name: "Belleville Station",       shortName: "Belleville",code: "BEL",
                coordinate: Coordinate(latitude: 44.1608, longitude: -77.3832),
                timezone: "America/Toronto", railOperator: "VIA", city: "Belleville", country: "CA"),

        Station(id: "VIA-BRCK", name: "Brockville Station",       shortName: "Brockville",code: "BRO",
                coordinate: Coordinate(latitude: 44.5897, longitude: -75.6893),
                timezone: "America/Toronto", railOperator: "VIA", city: "Brockville", country: "CA"),

        Station(id: "VIA-CORN", name: "Cornwall Station",         shortName: "Cornwall",  code: "CNW",
                coordinate: Coordinate(latitude: 45.0234, longitude: -74.7399),
                timezone: "America/Toronto", railOperator: "VIA", city: "Cornwall", country: "CA"),

        Station(id: "VIA-LNDN", name: "London Station",           shortName: "London",    code: "LON",
                coordinate: Coordinate(latitude: 42.9843, longitude: -81.2453),
                timezone: "America/Toronto", railOperator: "VIA", city: "London", country: "CA"),

        Station(id: "VIA-WNDS", name: "Windsor Station",          shortName: "Windsor",   code: "WIN",
                coordinate: Coordinate(latitude: 42.3145, longitude: -83.0364),
                timezone: "America/Toronto", railOperator: "VIA", city: "Windsor", country: "CA"),

        Station(id: "VIA-QUBC", name: "Québec City Station",      shortName: "Québec",    code: "QUE",
                coordinate: Coordinate(latitude: 46.8139, longitude: -71.2082),
                timezone: "America/Toronto", railOperator: "VIA", city: "Québec City", country: "CA"),

        Station(id: "VIA-VCVR", name: "Vancouver Pacific Central",shortName: "Vancouver", code: "VAN",
                coordinate: Coordinate(latitude: 49.2734, longitude: -123.0994),
                timezone: "America/Vancouver", railOperator: "VIA", city: "Vancouver", country: "CA"),

        Station(id: "VIA-EDMT", name: "Edmonton Station",         shortName: "Edmonton",  code: "EDM",
                coordinate: Coordinate(latitude: 53.5444, longitude: -113.4909),
                timezone: "America/Edmonton", railOperator: "VIA", city: "Edmonton", country: "CA"),

        Station(id: "VIA-WPEG", name: "Winnipeg Station",         shortName: "Winnipeg",  code: "WPG",
                coordinate: Coordinate(latitude: 49.8955, longitude: -97.1384),
                timezone: "America/Winnipeg", railOperator: "VIA", city: "Winnipeg", country: "CA"),

        // MARK: Amtrak
        Station(id: "AMT-NYP",  name: "New York Penn Station",    shortName: "New York",  code: "NYP",
                coordinate: Coordinate(latitude: 40.7506, longitude: -73.9971),
                timezone: "America/New_York", railOperator: "Amtrak", city: "New York", country: "US"),

        Station(id: "AMT-WAS",  name: "Washington Union Station", shortName: "Washington",code: "WAS",
                coordinate: Coordinate(latitude: 38.8977, longitude: -77.0063),
                timezone: "America/New_York", railOperator: "Amtrak", city: "Washington", country: "US"),

        Station(id: "AMT-BOS",  name: "Boston South Station",     shortName: "Boston",    code: "BOS",
                coordinate: Coordinate(latitude: 42.3519, longitude: -71.0551),
                timezone: "America/New_York", railOperator: "Amtrak", city: "Boston", country: "US"),

        Station(id: "AMT-PHL",  name: "Philadelphia 30th St",     shortName: "Philadelphia",code: "PHL",
                coordinate: Coordinate(latitude: 39.9566, longitude: -75.1820),
                timezone: "America/New_York", railOperator: "Amtrak", city: "Philadelphia", country: "US"),

        Station(id: "AMT-CHI",  name: "Chicago Union Station",    shortName: "Chicago",   code: "CHI",
                coordinate: Coordinate(latitude: 41.8786, longitude: -87.6400),
                timezone: "America/Chicago", railOperator: "Amtrak", city: "Chicago", country: "US"),

        Station(id: "AMT-ALB",  name: "Albany-Rensselaer",        shortName: "Albany",    code: "ALB",
                coordinate: Coordinate(latitude: 42.6451, longitude: -73.7474),
                timezone: "America/New_York", railOperator: "Amtrak", city: "Albany", country: "US"),

        Station(id: "AMT-BUF",  name: "Buffalo-Depew Station",    shortName: "Buffalo",   code: "BUF",
                coordinate: Coordinate(latitude: 42.8967, longitude: -78.7183),
                timezone: "America/New_York", railOperator: "Amtrak", city: "Buffalo", country: "US"),

        Station(id: "AMT-NHV",  name: "New Haven Station",        shortName: "New Haven", code: "NHV",
                coordinate: Coordinate(latitude: 41.2987, longitude: -72.9257),
                timezone: "America/New_York", railOperator: "Amtrak", city: "New Haven", country: "US"),

        // MARK: GO Transit
        Station(id: "GO-HMLTN", name: "Hamilton GO Centre",       shortName: "Hamilton",  code: "HAM",
                coordinate: Coordinate(latitude: 43.2557, longitude: -79.8711),
                timezone: "America/Toronto", railOperator: "GO", city: "Hamilton", country: "CA"),

        Station(id: "GO-OAKVL", name: "Oakville GO Station",      shortName: "Oakville",  code: "OAK",
                coordinate: Coordinate(latitude: 43.4502, longitude: -79.6828),
                timezone: "America/Toronto", railOperator: "GO", city: "Oakville", country: "CA"),

        Station(id: "GO-MSSGA", name: "Mississauga GO Station",   shortName: "Mississauga",code: "MIS",
                coordinate: Coordinate(latitude: 43.5931, longitude: -79.6445),
                timezone: "America/Toronto", railOperator: "GO", city: "Mississauga", country: "CA"),

        Station(id: "GO-BRLNG", name: "Burlington GO Station",    shortName: "Burlington", code: "BUR",
                coordinate: Coordinate(latitude: 43.3255, longitude: -79.7990),
                timezone: "America/Toronto", railOperator: "GO", city: "Burlington", country: "CA"),
    ]

    /// Filter stations by name, short name, or code.
    func search(_ query: String) -> [Station] {
        guard !query.isEmpty else { return stations }
        let q = query.lowercased()
        return stations.filter {
            $0.name.lowercased().contains(q) ||
            $0.shortName.lowercased().contains(q) ||
            $0.code.lowercased().contains(q) ||
            $0.city.lowercased().contains(q)
        }
    }

    /// Lookup a single station by text (returns first match or a generic station).
    func station(for query: String, operator op: String) -> Station {
        if let match = search(query).first { return match }
        // Fallback: create a minimal station from the typed text
        let name = query.trimmingCharacters(in: .whitespaces)
        let code = String(name.prefix(3)).uppercased()
        return Station(
            id: "\(op)-\(code)", name: name, shortName: name, code: code,
            coordinate: Coordinate(latitude: 0, longitude: 0),
            timezone: "America/Toronto", railOperator: op, city: name, country: "CA"
        )
    }
}
