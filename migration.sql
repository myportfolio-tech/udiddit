-- NORMALIZED "bad_posts" -- 
        -- USERS MIGRATIONS --      
CREATE TABLE "normalized_bad_posts" (
    "id" SERIAL,
    "topic" VARCHAR(50),
    "username" VARCHAR(50),
    "title" VARCHAR(150),
    "url" VARCHAR(4000),
    "text_content" TEXT,
    "upvote" TEXT,
    "downvotes" TEXT
);

INSERT INTO "normalized_bad_posts" ("id",
    "topic",
    "username",
    "title",
    "url",
    "text_content",
    "upvote",
    "downvotes")

    SELECT 
        "id", 
        "topic", 
        "username", 
        "title", 
        "url", 
        "text_content",
        REGEXP_SPLIT_TO_TABLE("upvotes", ','),
        REGEXP_SPLIT_TO_TABLE("downvotes", ',')
    FROM "bad_posts";



 -- USERS MIGRATIONS --
-- TEMP TABLE -- 
CREATE TABLE "temp_users" (
    "id" SERIAL PRIMARY KEY,
    "username" VARCHAR
);




-- INSERT Users from "posts" AND  "comments"
INSERT INTO "temp_users" ("username")
    SELECT DISTINCT "username" FROM "bad_comments";

INSERT INTO "temp_users" ("username")
    SELECT DISTINCT "username" FROM "bad_posts";

INSERT INTO "users" ("username")
    SELECT DISTINCT "username" FROM "temp_users";

DROP TABLE "temp_users"


        -- TOPICS MIGRATION -- 
-- Test "topics" Constraint
SELECT DISTINCT "topic" FROM "bad_posts" WHERE LENGTH("topic") < 3;
-- not topics with less than 3 characters

-- MIGRATE "topics" == 
INSERT INTO "topics" ("topic_name")
    SELECT DISTINCT "topic" FROM "normalized_bad_posts";




-- MIGRATE POSTS  --

INSERT INTO "posts" ("user_id", "topic_id", "post_title", "url", "text_content")
   (SELECT DISTINCT u.id "user_id",
   			tp.id "topic_id",
   			nbd."title",
   			nbd."url",
			nbd."text_content"
   FROM "normalized_bad_posts" nbd
	JOIN "users" u
		ON u."username" = nbd."username"
	JOIN "topics" tp
		ON tp."topic_name" = nbd."topic");

-- ERROR ERROR:  value too long for type character varying(100)
-- SQL state: 22001
-- We need to take the first 100 characters from the title

INSERT INTO "posts" ("id", "user_id", "topic_id", "post_title", "url", "text_content")
   (SELECT DISTINCT 
            nbd."id",
            u.id "user_id",
   			tp.id "topic_id",
   			LEFT(nbd."title", 100),
   			nbd."url",
			nbd."text_content"
   FROM "normalized_bad_posts" nbd
	JOIN "users" u
		ON u."username" = nbd."username"
	JOIN "topics" tp
		ON tp."topic_name" = nbd."topic");


-- MIGRATE COMMENTS  --
INSERT INTO "comments" ("user_id", "post_id", "text")
   (SELECT  u.id "user_id",
		"post_id",
        LEFT("text_content", 100)
    FROM bad_comments bd
    JOIN "users" u
		ON u."username" = bd."username");

-- ERROR:  insert or update on table "comments" violates foreign key constraint "comments_post_id_fkey"
-- DETAIL:  Key (post_id)=(6044) is not present in table "posts".
-- SQL state: 23503
-- Some comments do not have topics


INSERT INTO "comments" ("user_id", "post_id", "text")
   (SELECT  u.id "user_id",
		"post_id",
        LEFT(bd."text_content", 100)
    FROM bad_comments bd
    JOIN "users" u
		ON u."username" = bd."username"
	JOIN "posts" pt
		ON pt.id = "post_id");
    


-- MIGRATE VOTES ---

SELECT * FROM "normalized_bad_posts"
WHERE "upvote" IS NOT NULL
LIMIT 100;

-- TEMP TABLES -- 
CREATE TABLE "upvotes" (
    "user_id" INTEGER,
    "post_id" INTEGER,
    "value" SMALLINT DEFAULT 1);

CREATE TABLE "downvotes" (
    "user_id" INTEGER,
    "post_id" INTEGER,
    "value" SMALLINT DEFAULT -1);



-- INSERT INTO TEMP TABLES 
INSERT INTO "upvotes" ("post_id", "user_id") 
    (
    SELECT nbp.id,
		    u.id
    FROM "normalized_bad_posts" nbp
	JOIN "users" u
		ON u."username" = nbp."upvote"
	JOIN "posts" pt
		ON pt.id = nbp.id		
    WHERE "upvote" IS NOT NULL
    );


INSERT INTO "downvotes" ("post_id", "user_id") 
    (
    SELECT nbp.id,
		    u.id
    FROM "normalized_bad_posts" nbp
	JOIN "users" u
		ON u."username" = nbp."downvotes"
    JOIN "posts" pt
		ON pt.id = nbp.id
    WHERE "downvotes" IS NOT NULL
    );

-- MOVE DATA FROM TEMP TABLES TO PERM TABLE 


INSERT INTO "votes" ( "user_id", "post_id", "value")
    (
        SELECT "user_id", "post_id","value"
        FROM "upvotes"
    );

INSERT INTO "votes" ( "user_id", "post_id", "value")
    (
        SELECT "user_id", "post_id","value"
        FROM "downvotes"
    );

DROP TABLE "upvotes";
DROP TABLE "downvotes";
