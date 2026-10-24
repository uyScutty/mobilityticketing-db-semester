
using Microsoft.EntityFrameworkCore;
using MobilityTicketing.Lecture07.Contracts;
using MobilityTicketing.Lecture07.Data;

namespace MobilityTicketing.Lecture07.Queries;

public class ReadSnapshotQuery
{
    private readonly LectureDbContext _context;

    public ReadSnapshotQuery(LectureDbContext context)
    {
        _context = context;
    }

    public async Task<PublishedSnapshot> ExecuteAsync(
        string snapshotId,
        CancellationToken ct = default)
    {
        // 1. Valider ID før databaseadgang
        DatabaseSession.RequireText(
            snapshotId, nameof(snapshotId));

        // 2. Hent snapshot-header og rækker med én query
        // Vi vælger kun de kolonner, vi har brug for
        var rows = await (
            from plan in _context.PublishedPlans.AsNoTracking()

            // LEFT JOIN: også snapshots uden ruter skal kunne læses
            from route in plan.Rows.DefaultIfEmpty()

            where plan.Id == snapshotId

            select new
            {
                plan.Id,
                plan.FromUtc,
                plan.ToUtc,
                plan.PublishedAtUtc,

                RouteId = route == null ? null : route.RouteId,
                RouteName = route == null ? null : route.RouteName,
                Count = route == null
                    ? 0
                    : route.ScheduledTripCount,
                NextDepartureUtc = route == null
                    ? null
                    : route.NextDepartureUtc
            }
        ).ToListAsync(ct);

        // 3. Ingen rækker betyder, at snapshot-ID ikke findes
        if (rows.Count == 0)
        {
            throw new SnapshotNotFoundException(snapshotId);
        }

        // 4. Header-oplysningerne er ens på alle rækker
        var first = rows[0];

        var window = new TimeWindow(
            first.FromUtc,
            first.ToUtc);

        // 5. Byg listen af DTO'er i C# fra de hentede værdier
        // Dette udfører IKKE en ny databaseforespørgsel
        var routes = rows
            .Where(r => r.RouteId != null)
            .OrderBy(r => r.RouteId)
            .Select(r => new RouteOverviewDto(
                r.RouteId!,
                r.RouteName!,
                r.Count,
                r.NextDepartureUtc))
            .ToList();

        // 6. Returnér hele snapshot-resultatet
        return new PublishedSnapshot(
            first.Id,
            window,
            first.PublishedAtUtc,
            routes);
    }
}
