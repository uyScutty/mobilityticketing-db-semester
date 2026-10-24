using MobilityTicketing.Lecture07.Contracts;
using MobilityTicketing.Lecture07.Data;
using MobilityTicketing.Lecture07.Diagnostics;
using MobilityTicketing.Lecture07.Queries;
using MobilityTicketing.Lecture07.Commands;

namespace MobilityTicketing.Lecture07;

public sealed class StudentApplication(string connection, TimeProvider? clock = null,
    ApplicationHooks? hooks = null, RunMeasurement? measurement = null) : ILectureApplication
{
    public string Connection { get; } = connection;
    public TimeProvider Clock { get; } = clock ?? TimeProvider.System;
    public ApplicationHooks Hooks { get; } = hooks ?? new();
    public RunMeasurement Measurement { get; } = measurement ?? new();
    public LectureDbContext CreateContext() => LectureDbContext.Create(Connection, measurement: Measurement);

    // Connect your command and query classes here.
    public async Task<List<RouteOverviewDto>> ReadOverviewAsync(
    TimeWindow window,
    CancellationToken ct = default)
{
    await using var context = CreateContext();

    var query = new LiveRouteOverviewQuery(context);

    return await query.ExecuteAsync(window, ct);
}
    public Task<CancelResult> CancelTripAsync(
    string tripId,
    CancellationToken ct = default)
{
    var command = new CancelTripCommand(Connection);

    return command.ExecuteAsync(tripId, ct);
}
    public Task<RenameResult> RenameRouteAsync(
    string routeId,
    string name,
    CancellationToken ct = default)
{
    var command = new RenameRouteCommand(Connection);

    return command.ExecuteAsync(routeId, name, ct);
}
    public Task<BookingResult> BookTripAsync(
    string tripId,
    string requestId,
    CancellationToken ct = default)
{
    var command = new BookTripCommand(Connection, Clock);

    return command.ExecuteAsync(tripId, requestId, ct);
}
    public Task<PublishResult> PublishSnapshotAsync(
    string snapshotId,
    TimeWindow window,
    CancellationToken ct = default)
{
    var command = new PublishSnapshotCommand(
        Connection,
        Clock,
        Hooks);

    return command.ExecuteAsync(snapshotId, window, ct);
}

    public async Task<PublishedSnapshot> ReadSnapshotAsync(
    string snapshotId,
    CancellationToken ct = default)
{
    await using var db = CreateContext();

    var query = new ReadSnapshotQuery(db);

    return await query.ExecuteAsync(snapshotId, ct);
}

}
