using Microsoft.EntityFrameworkCore;
using MobilityTicketing.Lecture07.Contracts;
using MobilityTicketing.Lecture07.Data;

namespace MobilityTicketing.Lecture07.Commands;

public class BookTripCommand
{
    private readonly string _connection;
    private readonly TimeProvider _clock;

    // Constructor injection:
    // Modtager databaseforbindelsen og applikationens clock.
    public BookTripCommand(
        string connection,
        TimeProvider clock)
    {
        _connection = connection;
        _clock = clock;
    }

    public Task<BookingResult> ExecuteAsync(
        string tripId,
        string requestId,
        CancellationToken ct = default)
    {
        // 1. Valider input, inden vi tilgår databasen.
        DatabaseSession.RequireText(tripId, nameof(tripId));
        DatabaseSession.RequireText(requestId, nameof(requestId));

        // 2. Start en beskyttet databaseoperation.
        // Advisory lock sikrer, at requests med samme
        // requestId behandles efter hinanden.
        return DatabaseSession.WriteAsync(
            _connection,
            $"booking:{requestId}",
            async db =>
            {
                // 3. Undersøg om requestId allerede findes.
                // Read-only query: ingen Change Tracking.
                var existingBooking = await db.Bookings
                    .AsNoTracking()
                    .SingleOrDefaultAsync(
                        b => b.RequestId == requestId,
                        ct);

                // 4. Samme requestId må ikke bruges
                // til en anden afgang.
                if (existingBooking != null &&
                    existingBooking.TripId != tripId)
                {
                    return new BookingResult(
                        BookingStatus.RequestConflict);
                }

                // 5. Retry af en tidligere gennemført booking.
                // Returnér den oprindelige kvittering.
                if (existingBooking != null)
                {
                    var existingReceipt = new BookingReceipt(
                        existingBooking.RequestId,
                        existingBooking.TripId,
                        existingBooking.BookedAtUtc);

                    return new BookingResult(
                        BookingStatus.AlreadyBooked,
                        existingReceipt);
                }

                // 6. Lås Trip-rækken med SELECT FOR UPDATE.
                // Beskytter statuskontrollen mod en
                // samtidig cancellation.
                var trip = await DatabaseSession.LockTripAsync(
                    db, tripId, ct);

                // 7. Trip findes ikke.
                if (trip == null)
                {
                    return new BookingResult(
                        BookingStatus.NotFound);
                }

                // 8. Kun Scheduled trips må bookes.
                if (trip.Status != "Scheduled")
                {
                    return new BookingResult(
                        BookingStatus.Cancelled);
                }

                // 9. Hent tidspunkt fra den fælles clock.
                // PostgreSQL gemmer mikrosekundpræcision,
                // derfor tilpasses tidspunktet hertil.
                var now = _clock.GetUtcNow().UtcDateTime;
                var bookedAt = new DateTime(
                    now.Ticks - now.Ticks %
                        TimeSpan.TicksPerMicrosecond,
                    DateTimeKind.Utc);

                // 10. Opret den nye Booking-entity.
                var booking = new Booking
                {
                    RequestId = requestId,
                    TripId = tripId,
                    BookedAtUtc = bookedAt
                };

                // 11. Registrér bookingen i EF Core.
                // Den får state = Added i Change Tracker.
                // SQL INSERT udføres senere af WriteAsync.
                db.Bookings.Add(booking);

                // 12. Opret kvittering med samme værdier.
                var receipt = new BookingReceipt(
                    booking.RequestId,
                    booking.TripId,
                    booking.BookedAtUtc);

                // 13. Returnér resultatet til WriteAsync.
                // Helperen kalder derefter SaveChangesAsync
                // og CommitAsync, før resultatet leveres
                // tilbage til den kaldende kode.
                return new BookingResult(
                    BookingStatus.Booked,
                    receipt);
            },
            ct);
    }
}

    
