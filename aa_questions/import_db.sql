DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;

PRAGMA foreign_keys = ON;


CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
);


CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    author_id INTEGER NOT NULL,

    FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    reply_id INTEGER,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (reply_id) REFERENCES replies(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);


CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO 
    users(fname, lname)
VALUES
    ('first1', 'last1'),
    ('name2first', 'name2last'),
    ('name3first', 'name3last');


INSERT INTO 
    questions (title, body, author_id)
VALUES 
    ('question 1', 'testing1', 1),
    ('question2', 'does this work?', 1),
    ('question3', 'no it doesn''t', 2);

INSERT INTO 
    question_follows
    (question_id, user_id)
VALUES
    (1, 1),
    (1, 2),
    (2, 1);


INSERT INTO 
    replies
    (question_id, reply_id, user_id)
VALUES
    (1, NULL, 1),
    (1, 1, 1),
    (2, NULL, 2),
    (2, 3, 1);

INSERT INTO 
    question_likes
    (question_id, user_id)
VALUES
    (1, 1),
    (1, 2),
    (2, 1);



