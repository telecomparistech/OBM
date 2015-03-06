BEGIN;

CREATE TYPE recurrence_kind AS ENUM ('none', 'daily', 'weekly', 'monthlybydate', 'monthlybyday', 'yearly', 'yearlybyday');

ALTER TABLE event ADD COLUMN event_repeatkind_enum recurrence_kind;

UPDATE event SET event_repeatkind_enum='none' WHERE event_repeatkind NOT IN ('none', 'daily', 'weekly', 'monthlybydate', 'monthlybyday', 'yearly', 'yearlybyday');

UPDATE event SET event_repeatkind_enum=CAST (event_repeatkind AS recurrence_kind) WHERE event_repeatkind NOT IN ('none', 'daily', 'weekly', 'monthlybydate', 'monthlybyday', 'yearly', 'yearlybyday');

ALTER TABLE event ALTER event_repeatkind_enum SET NOT NULL;

ALTER TABLE event ALTER event_repeatkind_enum SET DEFAULT 'none';

ALTER TABLE event DROP event_repeatkind; 

ALTER TABLE event RENAME event_repeatkind_enum TO event_repeatkind;

COMMIT;
