const m = db.getSiblingDB("mobility");

const start = ISODate("2026-10-02T06:00:00Z");
const end = ISODate("2026-10-02T07:00:00Z");

const query = {
  cityId: "CPH",
  fromStopId: "STOP-NORREPORT",
  toStopId: "STOP-AIRPORT",

  "departures.status": "Scheduled",

  "departures.departureUtc": {
    $gte: start,
    $lt: end
  }
};

printjson(
  m.journey_search.find(query).toArray()
);

const m2 = db.getSiblingDB("mobility");

const start2 = ISODate("2026-10-02T06:00:00Z");
const end2 = ISODate("2026-10-02T07:00:00Z");

const query2 = {
  cityId: "CPH",
  fromStopId: "STOP-NORREPORT",
  toStopId: "STOP-AIRPORT",

  departures: {
    $elemMatch: {
      status: "Scheduled",
      departureUtc: {
        $gte: start,
        $lt: end
      }
    }
  }
};