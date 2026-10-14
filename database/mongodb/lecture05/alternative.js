const m = db.getSiblingDB("mobility");

// Ryd den alternative collection,
// så scriptet kan køres igen uden duplicate _id-fejl.
m.journey_search_by_trip.deleteMany({});

// Hent de eksisterende journey-search documents.
const journeys = m.journey_search
  .find({ _id: /^LAB05:/ })
  .toArray();

// Gå igennem hvert journey-document.
for (const journey of journeys) {

  // Gå derefter igennem hver departure i departures[].
  for (const departure of journey.departures) {

    // Lav ét nyt document pr. departure.
    const doc = {

      // Sammensat/deterministisk ID.
      _id:
        `${journey.cityId}:` +
        `${journey.routeId}:` +
        `${journey.fromStopId}:` +
        `${journey.toStopId}:` +
        `${departure.tripId}`,

      cityId: journey.cityId,
      routeId: journey.routeId,

      fromStopId: journey.fromStopId,
      toStopId: journey.toStopId,

      tripId: departure.tripId,

      departureUtc: departure.departureUtc,
      arrivalUtc: departure.arrivalUtc,

      status: departure.status,
      availableSeats: departure.availableSeats,

      price: journey.price,
      currency: journey.currency,

      schemaVersion: 1
    };

    // Gem det nye document.
    m.journey_search_by_trip.insertOne(doc);
  }
}

// Vis hvor mange documents vi endte med.
printjson({
  documents:
    m.journey_search_by_trip.countDocuments({})
});