namespace MobilityTicketing.Lecture07.Data;

public class PublishedPlan
{
    public string Id { get; set; } = "";
    public DateTime FromUtc { get; set; }
    public DateTime ToUtc { get; set; }
    public DateTime PublishedAtUtc { get; set; }

    // Navigation property: Én plan har mange rækker
    public virtual List<PublishedPlanRow> Rows { get; set; } = new();
}