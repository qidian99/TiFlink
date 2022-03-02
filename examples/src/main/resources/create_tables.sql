CREATE TABLE IF NOT EXISTS `authors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(50),
  `last_name` varchar(50),
  `email` varchar(100),
  `birthdate` date,
  `added` timestamp DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `posts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `author_id` int(11),
  `title` varchar(255),
  `description` varchar(500),
  `content` text,
  `date` date,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `author_posts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `first_name` varchar(50),
  `last_name` varchar(50),
  `email` varchar(100),
  `posts` bigint(32),
  PRIMARY KEY (`id`)
);

select id, first_name, last_name, email, (select count(*) from posts where author_id = authors.id) as posts from authors;



create table if not exists worker (
    id int(11) NOT NULL AUTO_INCREMENT,
    name varchar(30),
    PRIMARY KEY (`id`)
);


create table if not exists currency (
    id int(11) NOT NULL AUTO_INCREMENT,
    name varchar(30),
    ratio double,
    PRIMARY KEY (`id`)
);


create table if not exists holding (
    id int(11) NOT NULL AUTO_INCREMENT,
    w_id int,
    c_id int,
    amount double,
    PRIMARY KEY (`id`)
);

insert into worker values (1, 'Q'), (2, 'R'), (3, 'S');
insert into currency values (1, 'US', 6.0), (2, 'RU', 5.0);
insert into holding values (1, 1, 1, 60),(2, 1, 2, 50),(3, 1, 2, 90), (4, 2, 1, 88);

select w.name as name, sum(c.ratio * h.amount) as richness from worker w inner join holding h on w.id = h.w_id inner join currency c on h.c_id = c.id group by w.name;


create table money (w varchar(255), richness double);
