const m = db.getSiblingDB("mobility");

function search(cityId, fromStopId, toStopId, start, end) {

    if (!cityId || !fromStopId || !toStopId || end <= start) {
        return [];
    }

    return m.journey_search
        .aggregate([
            {
                $match: {
                    cityId: cityId,
                    fromStopId: fromStopId,
                    toStopId: toStopId
                }
            },

            {
                $unwind: "$departures"
            },

            {
                $match: {
                    "departures.status": "Scheduled",
                    "departures.departureUtc": {
                        $gte: start,
                        $lt: end
                    }
                }
            },

            {
                $project: {
                    _id: 0,
                    cityId: 1,
                    routeId: 1,
                    fromStopId: 1,
                    toStopId: 1,

                    tripId: "$departures.tripId",
                    departureUtc: "$departures.departureUtc",
                    arrivalUtc: "$departures.arrivalUtc",
                    availableSeats: "$departures.availableSeats",
                    price: "$price",
                    currency: "$currency"
                }
            },

            {
                $sort: {
                    departureUtc: 1
                }
            }
        ])
        .toArray();
}

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

const start2 = ISODate("2026-10-02T06:00:00Z");
const end2 = ISODate("2026-10-02T06:20:00Z");

printjson(
  search(
    "CPH",
    "STOP-NORREPORT",
    "STOP-AIRPORT",
    start,
    end
  )
);
const start3 = ISODate("2026-10-02T06:00:00Z");
const end3 = ISODate("2026-10-02T07:00:00Z");

printjson(
  search(
    "CPH",
    "STOP-AIRPORT",
    "STOP-NORREPORT",
    start3,
    end3
  )
);

const start5 = ISODate("2026-10-02T06:00:00Z");
const end5 = ISODate("2026-10-02T07:00:00Z");

printjson(
  search(
    "CPH",
    "STOP-NORREPORT",
    "STOP-NO-MATCH",
    start5,
    end5
  )
);

const start6 = ISODate("2026-10-02T07:00:00Z");
const end6 = ISODate("2026-10-02T06:00:00Z");

printjson(
  search(
    "CPH",
    "STOP-NORREPORT",
    "STOP-AIRPORT",
    start6,
    end6
  )
);

const startA = ISODate("2026-10-02T06:00:00Z");
const endA = ISODate("2026-10-02T07:00:00Z");

print("Nørreport -> Airport");
printjson(
  search(
    "CPH",
    "STOP-NORREPORT",
    "STOP-AIRPORT",
    startA,
    endA
  )
);

print("Nørreport -> Central");
printjson(
  search(
    "CPH",
    "STOP-NORREPORT",
    "STOP-CENTRAL",
    startA,
    endA
  )
);
