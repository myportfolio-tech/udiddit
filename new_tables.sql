
-- USERS ---
CREATE TABLE "users" (
    "id" SERIAL PRIMARY KEY,
    "username" VARCHAR(25) UNIQUE NOT NULL,
    "created_date" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    "last_login" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    -- the username must be 3 characters or longer --
    CONSTRAINT "username_length" CHECK (
        LENGTH(TRIM("username")) >= 3)
);

-- TOPICS ---
CREATE TABLE "topics" (
    "id" SERIAL PRIMARY KEY,
    "topic_name" VARCHAR(30) UNIQUE NOT NULL,
    "description" VARCHAR(500) DEFAULT NULL,
    "created_date" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    -- the topic_name must be 3 characters long --
    CONSTRAINT "topic_name_length" CHECK (
        LENGTH(TRIM("topic_name")) >= 3)
);


-- POSTS ---
CREATE TABLE "posts" (
    "id" SERIAL PRIMARY KEY,
    "post_title" VARCHAR(100) NOT NULL,
    "url" VARCHAR(500) DEFAULT NULL,
    "text_content" TEXT DEFAULT NULL,
    "created_date" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    "user_id" INTEGER,
    "topic_id" INTEGER,
    CONSTRAINT "url_or_text" CHECK (
        "url" IS NULL 
        OR 
        "text_content" IS NULL),
    FOREIGN KEY  ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE,
    FOREIGN KEY  ("topic_id") REFERENCES "topics" ("id") ON DELETE CASCADE,
    -- the post_title must be 3 characters or longer --
    CONSTRAINT "post_title_length" CHECK (
        LENGTH(TRIM("post_title")) > 3)
);



-- COMMENTS ---
CREATE TABLE "comments" (
    "id" SERIAL PRIMARY KEY,
    "text" VARCHAR(100) NOT NULL,
    "parent_comment_id" INTEGER DEFAULT NULL,
    "created_date" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    "user_id" INTEGER,
    "post_id" INTEGER,
    FOREIGN KEY  ("parent_comment_id") REFERENCES "comments" ("id") ON DELETE CASCADE,
    FOREIGN KEY  ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE,
    FOREIGN KEY  ("post_id") REFERENCES "posts" ("id") ON DELETE CASCADE,
    -- comments must be 1 characters or longer - no spaces for comments --
    CONSTRAINT "post_title_length" CHECK (
        LENGTH(TRIM("text")) > 1)
);


-- VOTES ---
CREATE TABLE "votes" (
    "id" SERIAL PRIMARY KEY,
    "value" SMALLINT,
    "created_date" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    "user_id" INTEGER,
    "post_id" INTEGER,
    FOREIGN KEY  ("user_id") REFERENCES "users" ("id") ON DELETE SET NULL,
    FOREIGN KEY  ("post_id") REFERENCES "posts" ("id") ON DELETE SET NULL,
    CONSTRAINT "votes_value" CHECK (
        ABS("value") = 1),
    CONSTRAINT "vote_once" UNIQUE ("id", "user_id" , "post_id")
);

--- CREATE INDEXES ---

CREATE INDEX "lower_username" 
    ON "users" (LOWER("username"));

CREATE INDEX "lower_topic" 
    ON "topics" (LOWER("topic_name"));

CREATE INDEX "search_topics_descriptions" 
ON "topics" ("description" VARCHAR_PATTERN_OPS);

CREATE INDEX "url_search" 
    ON "posts" (LOWER("url"));

CREATE INDEX "search_posts_text" 
ON "posts" ("text_content" VARCHAR_PATTERN_OPS);

CREATE INDEX "top_level_comments" 
    ON "comments" ("id",  "parent_comment_id");

CREATE INDEX "search_comments_text" 
    ON "comments" ("text" VARCHAR_PATTERN_OPS);

CREATE INDEX "votes_post_id_value"
    ON "votes"( "post_id", "value");
