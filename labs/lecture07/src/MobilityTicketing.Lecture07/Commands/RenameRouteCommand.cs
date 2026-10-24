
using Microsoft.EntityFrameworkCore;
using MobilityTicketing.Lecture07.Contracts;
using MobilityTicketing.Lecture07.Data;

namespace MobilityTicketing.Lecture07.Commands;

public class RenameRouteCommand
{
    private readonly string _connection;

    public RenameRouteCommand(string connection)
    {
        _connection = connection;
    }

    public Task<RenameResult> ExecuteAsync(
        string routeId,
        string name,
        CancellationToken ct = default)
    {
        DatabaseSession.RequireText(routeId, nameof(routeId));
        DatabaseSession.RequireText(name, nameof(name));
        
        var trimmedName = name.Trim();

        DatabaseSession.RequireText(trimmedName, nameof(name));

        return DatabaseSession.WriteAsync(
            _connection,
            $"route:{routeId}",
            async db =>
            {
                var route = await db.Routes
                    .SingleOrDefaultAsync(r => r.Id == routeId, ct);

                if (route == null)
                    return RenameResult.NotFound;

                route.Name = name.Trim();

                return RenameResult.Renamed;
            },
            ct);
    }
}
