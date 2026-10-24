using Microsoft.EntityFrameworkCore;

namespace MobilityTicketing.Lecture07.Data;

public static class DatabaseSession
{
    // A failed callback or hook rolls back the whole write. Keys serialize retries.
   
public static async Task<T> WriteAsync<T>(
    string connection,                 // Connection string til PostgreSQL
    string key,                        // Nøgle til advisory lock
    Func<LectureDbContext, Task<T>> work, // Funktion med vores Command-logik
    CancellationToken ct = default,   // Gør det muligt at afbryde operationen
    Action? beforeCommit = null)      // Valgfri handling inden COMMIT
{
    // 1. Validerer connection string
    LabDatabase.Validate(connection);

    // 2. Opretter en ny DbContext
    // await using sørger for automatisk oprydning
    await using var db = LectureDbContext.Create(connection);

    // 3. Starter en databasetransaktion
    await using var tx =
        await db.Database.BeginTransactionAsync(ct);

    // 4. Opretter en PostgreSQL advisory lock
    // Requests med samme key skal vente på hinanden
    // Låsen frigives automatisk ved COMMIT/ROLLBACK
    await db.Database.ExecuteSqlInterpolatedAsync(
        $"select pg_advisory_xact_lock(hashtextextended({key}, 0))", ct);

    // 5. Udfører den Command-logik, vi har sendt ind
    // db gives videre til fx CancelTripCommand
    var result = await work(db);

    // 6. Gemmer ændringer registreret af Change Tracker
    await db.SaveChangesAsync(ct);

    // 7. Udfører en eventuel callback inden COMMIT
    beforeCommit?.Invoke();

    // 8. Bekræfter alle ændringer i transaktionen
    await tx.CommitAsync(ct);

    // 9. Returnerer resultatet fra vores Command
    return result;
}

// Booking og cancellation låser den samme Trip-række
public static Task<Trip?> LockTripAsync(
    LectureDbContext db,
    string id,
    CancellationToken ct = default) =>

    // SELECT ... FOR UPDATE låser Trip-rækken
    // indtil transaktionen afsluttes
    // Returnerer Trip eller null, hvis den ikke findes
    db.Trips
        .FromSqlInterpolated(
            $"select * from lab07.trips where id={id} for update")
        .SingleOrDefaultAsync(ct);

// Fælles validering af tekstparametre
public static void RequireText(string value, string name)
{
    // Afviser null, tom tekst og kun mellemrum
    if (string.IsNullOrWhiteSpace(value))
        throw new ArgumentException($"{name} must not be empty.");
}

}
