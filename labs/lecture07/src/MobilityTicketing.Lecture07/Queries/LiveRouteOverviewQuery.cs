using MobilityTicketing.Lecture07.Contracts;
using MobilityTicketing.Lecture07.Data;
using Microsoft.EntityFrameworkCore;

namespace MobilityTicketing.Lecture07.Queries;

public class LiveRouteOverviewQuery
{
    private readonly LectureDbContext _context;

    public LiveRouteOverviewQuery(LectureDbContext context)
    {
        _context = context;
    }
    
public async Task<List<RouteOverviewDto>> ExecuteAsync(
    TimeWindow window,
    CancellationToken ct = default)
{
    // Kontrollér tidsvinduet
    window.Validate();

    // Sortér Routes, før vi laver projection til DTO
    var query = _context.Routes
        .AsNoTracking()
        .OrderBy(r => r.Id)
        .Select(r => new RouteOverviewDto(
            r.Id,
            r.Name,

            // Antal planlagte afgange i tidsvinduet
            r.Trips.Count(t =>
                t.Status == "Scheduled" &&
                t.DepartureUtc >= window.FromUtc &&
                t.DepartureUtc < window.ToUtc),

            // Tidspunktet for næste planlagte afgang
            r.Trips
                .Where(t =>
                    t.Status == "Scheduled" &&
                    t.DepartureUtc >= window.FromUtc &&
                    t.DepartureUtc < window.ToUtc)
                .Min(t => (DateTime?)t.DepartureUtc)
        ));

    return await query.ToListAsync(ct);
}

}