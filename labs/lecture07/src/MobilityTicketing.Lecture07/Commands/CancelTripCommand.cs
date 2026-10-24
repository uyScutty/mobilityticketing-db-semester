using MobilityTicketing.Lecture07.Contracts;
using MobilityTicketing.Lecture07.Data;

namespace MobilityTicketing.Lecture07.Commands;

public class CancelTripCommand
{
    private readonly string _connection;

    public CancelTripCommand(string connection)
    {
        _connection = connection;
    }

    public Task<CancelResult> ExecuteAsync(
    string tripId,
    CancellationToken ct = default)
{
    DatabaseSession.RequireText(tripId, nameof(tripId));

    return DatabaseSession.WriteAsync(
        _connection,
        $"trip:{tripId}",
        async db =>
        {
            var trip = await DatabaseSession.LockTripAsync(
                db,
                tripId,
                ct);

            if (trip == null)
    return CancelResult.NotFound;

if (trip.Status == "Cancelled")
    return CancelResult.AlreadyCancelled;

trip.Status = "Cancelled";

return CancelResult.Cancelled;    
            // Her kommer vores cancellation-logik
            throw new NotImplementedException();
        },
        ct);
}
}
