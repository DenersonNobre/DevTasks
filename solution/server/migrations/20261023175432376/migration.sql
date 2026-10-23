BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "devtasks_session" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "tokenHash" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "revokedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "devtasks_session_token_hash_idx" ON "devtasks_session" USING btree ("tokenHash");


--
-- MIGRATION VERSION FOR devtasks
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('devtasks', '20261023175432376', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261023175432376', "timestamp" = now();

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
