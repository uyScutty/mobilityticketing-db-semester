 
using Microsoft.EntityFrameworkCore;
using MobilityTicketing.Lecture07.Contracts;
using MobilityTicketing.Lecture07.Data;
using MobilityTicketing.Lecture07.Queries;

namespace MobilityTicketing.Lecture07.Commands;

public class PublishSnapshotCommand
{
    private readonly string _connection;
    private readonly TimeProvider _clock;
    private readonly ApplicationHooks _hooks;

    // Constructor: modtager databaseforbindelse, ur og hooks
    public PublishSnapshotCommand(
        string connection,
        TimeProvider clock,
        ApplicationHooks hooks)
    {
        _connection = connection;
        _clock = clock;
        _hooks = hooks;
    }

    public Task<PublishResult> ExecuteAsync(
        string snapshotId,
        TimeWindow window,
        CancellationToken ct = default)
    {
        // 1. Valider input, før vi åbner databasen
        DatabaseSession.RequireText(snapshotId, nameof(snapshotId));
        window.Validate();

        // 2. Start en transaktion med advisory lock på snapshot-ID
        return DatabaseSession.WriteAsync(
            _connection,
            $"snapshot:{snapshotId}",
            async db =>
            {
                // 3. Undersøg om snapshot allerede findes
                var existing = await db.PublishedPlans
                    .AsNoTracking()
                    .SingleOrDefaultAsync(
                        p => p.Id == snapshotId, ct);

                if (existing != null)
                {
                    // Samme ID, men forskelligt tidsvindue
                    if (existing.FromUtc != window.FromUtc ||
                        existing.ToUtc != window.ToUtc)
                    {
                        throw new SnapshotConflictException(snapshotId);
                    }

                    // Samme ID og tidsvindue:
                    // Gem ikke noget nyt (idempotency)
                    return PublishResult.AlreadyPublished;
                }

                // 4. Hent den aktuelle oversigt over alle ruter
                // Vi genbruger samme DbContext og transaktion
                var overviewQuery = new LiveRouteOverviewQuery(db);

                var routes = await overviewQuery.ExecuteAsync(
                    window, ct);

                // 5. Opret snapshot-headeren
                // PostgreSQL gemmer mikrosekunder, ikke 100 ns ticks.
                // Derfor afrunder vi kun det genererede tidspunkt ned.
                var now = _clock.GetUtcNow().UtcDateTime;

                var publishedAt = new DateTime(
                    now.Ticks - now.Ticks % TimeSpan.TicksPerMicrosecond,
                    DateTimeKind.Utc);

                var plan = new PublishedPlan
                {
                    Id = snapshotId,
                    FromUtc = window.FromUtc,
                    ToUtc = window.ToUtc,
                    PublishedAtUtc = publishedAt
                };

                // 6. Kopiér DTO-værdier til snapshot-rækker
                // De bliver uafhængige af senere ændringer
                // i Routes og Trips
                foreach (var route in routes)
                {
                    plan.Rows.Add(new PublishedPlanRow
                    {
                        PlanId = snapshotId,
                        RouteId = route.RouteId,
                        RouteName = route.RouteName,
                        ScheduledTripCount = route.ScheduledTripCount,
                        NextDepartureUtc = route.NextDepartureUtc
                    });
                }

                // 7. Fortæl EF Core at planen skal indsættes
                // De tilknyttede Rows indsættes også
                db.PublishedPlans.Add(plan);

                // 8. Returnér resultatet
                // WriteAsync udfører SaveChanges og COMMIT bagefter
                return PublishResult.Published;
            },
            ct,
            _hooks.BeforePublishCommit);
    }
}

    

