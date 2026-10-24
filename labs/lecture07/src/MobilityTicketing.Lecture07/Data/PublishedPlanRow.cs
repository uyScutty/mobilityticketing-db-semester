namespace MobilityTicketing.Lecture07.Data;

public class PublishedPlanRow
{
    public string PlanId { get; set; } = "";
    public string RouteId { get; set; } = "";
    public string RouteName { get; set; } = "";
    public int ScheduledTripCount { get; set; }
    public DateTime? NextDepartureUtc { get; set; }

    // Navigation property tilbage til planen
    public virtual PublishedPlan Plan { get; set; } = null!;
}