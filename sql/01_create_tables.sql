-- Recreate table 'state'
DROP TABLE if exists state cascade;
CREATE TABLE state (
    state_id INT NOT NULL,
    state_name varchar(100) NOT NULL,
    timestamp timestamp default current_timestamp,
    PRIMARY KEY (state_id)
);

-- Recreate table 'department'
DROP TABLE if exists department cascade;
CREATE TABLE IF NOT EXISTS department (
    department_id INT NOT NULL,
    department_name varchar(450) NOT NULL,
    state_id INT NOT NULL,
    timestamp timestamp default current_timestamp,
    PRIMARY KEY (department_id),
    CONSTRAINT fk_state FOREIGN KEY(state_id) REFERENCES state(state_id)
);
