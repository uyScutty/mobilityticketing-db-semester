const m = db.getSiblingDB("mobility");

function search(cityId, fromStopId, toStopId, start, end) {

  // Stop ugyldigt input før vi spørger databasen
  if (!cityId || !fromStopId || !toStopId || end <= start) {
    return [];
  }

  // Søg direkte i documents
  // Vi har ikke længere departures[] array
  return m.journey_search_by_trip
    .find({
      cityId: cityId,
      fromStopId: fromStopId,
      toStopId: toStopId,
      status: "Scheduled",

      departureUtc: {
        $gte: start,
        $lt: end
      }
    })
    .sort({
      departureUtc: 1
    })
    .toArray();
}


// TEST

const start = ISODate("2026-10-02T06:00:00Z");
const end = ISODate("2026-10-02T07:00:00Z");

printjson(
  search(
    "CPH",
    "STOP-NORREPORT",
    "STOP-AIRPORT",
    start,
    end
  )
);