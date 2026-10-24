
using Microsoft.EntityFrameworkCore;

namespace MobilityTicketing.Lecture07.Data;

public partial class LectureDbContext
{
    partial void ConfigureReadModels(ModelBuilder b)
    {
        // Mapping af PublishedPlan
        b.Entity<PublishedPlan>(e =>
        {
            e.ToTable("published_plans");

            e.HasKey(x => x.Id);

            e.Property(x => x.Id)
                .HasColumnName("id");

            e.Property(x => x.FromUtc)
                .HasColumnName("from_utc");

            e.Property(x => x.ToUtc)
                .HasColumnName("to_utc");

            e.Property(x => x.PublishedAtUtc)
                .HasColumnName("published_at_utc");
        });

        // Mapping af PublishedPlanRow
        b.Entity<PublishedPlanRow>(e =>
        {
            e.ToTable("published_plan_rows");

            e.HasKey(x => new { x.PlanId, x.RouteId });

            e.Property(x => x.PlanId)
                .HasColumnName("plan_id");

            e.Property(x => x.RouteId)
                .HasColumnName("route_id");

            e.Property(x => x.RouteName)
                .HasColumnName("route_name");

            e.Property(x => x.ScheduledTripCount)
                .HasColumnName("scheduled_trip_count");

            e.Property(x => x.NextDepartureUtc)
                .HasColumnName("next_departure_utc");

            // Én PublishedPlan har mange PublishedPlanRows
            e.HasOne(x => x.Plan)
                .WithMany(x => x.Rows)
                .HasForeignKey(x => x.PlanId);
        });
    }
}
