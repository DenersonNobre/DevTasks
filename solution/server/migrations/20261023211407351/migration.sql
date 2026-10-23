BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "devtasks_workspace" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "devtasks_workspace_member" (
    "id" bigserial PRIMARY KEY,
    "workspaceId" bigint NOT NULL,
    "userId" text NOT NULL,
    "role" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "devtasks_workspace_member_unique_idx" ON "devtasks_workspace_member" USING btree ("workspaceId", "userId");


--
-- MIGRATION VERSION FOR devtasks
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('devtasks', '20261023211407351', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261023211407351', "timestamp" = now();

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
