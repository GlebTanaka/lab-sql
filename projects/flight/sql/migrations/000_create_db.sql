-- Create a role for the project
CREATE ROLE skyhub_owner LOGIN PASSWORD 'change_me';

-- Create the project database and assign ownership
CREATE DATABASE skyhub_db OWNER skyhub_owner;