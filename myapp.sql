DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id SERIAL NOT NULL PRIMARY KEY ,
  name VARCHAR( 30 ) NOT NULL ,
  email VARCHAR( 255 ) NOT NULL ,
  profile_img VARCHAR( 255 ) ,
  password VARCHAR( 255 ) NOT NULL ,
  UNIQUE (email)
);

CREATE TABLE posts (
  id SERIAL NOT NULL PRIMARY KEY ,
  user_id INTEGER NOT NULL,
  title VARCHAR( 20 ) NOT NULL ,
  content VARCHAR( 255 ) NOT NULL ,
  post_img VARCHAR( 255 ) ,
  FOREIGN KEY(user_id)
  REFERENCES users(id)
);
