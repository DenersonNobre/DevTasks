BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "devtasks_project" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "name" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);


--
-- MIGRATION VERSION FOR devtasks
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('devtasks', '20261024110300219', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261024110300219', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth', '20260129181059877', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181059877', "timestamp" = now();


COMMIT;
