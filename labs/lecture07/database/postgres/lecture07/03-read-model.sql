-- Design persistent storage for published dispatch plans in lab07.
-- Include the plan identity, time window, publication time and displayed values.
-- The contract defines behavior; the table layout is your choice.
CREATE TABLE lab07.published_plans (
    id TEXT PRIMARY KEY,
    from_utc TIMESTAMPTZ NOT NULL,
    to_utc TIMESTAMPTZ NOT NULL,
    published_at_utc TIMESTAMPTZ NOT NULL,
    CONSTRAINT valid_window CHECK (to_utc > from_utc)
);

CREATE TABLE lab07.published_plan_rows (
    plan_id TEXT NOT NULL,
    route_id TEXT NOT NULL,
    route_name TEXT NOT NULL,
    scheduled_trip_count INTEGER NOT NULL,
    next_departure_utc TIMESTAMPTZ,

    PRIMARY KEY (plan_id, route_id),

    FOREIGN KEY (plan_id)
        REFERENCES lab07.published_plans(id),

    CHECK (scheduled_trip_count >= 0)
);