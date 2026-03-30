
-- 1 Crear la base de datos limpia

DROP DATABASE IF EXISTS spotify_db;
CREATE DATABASE spotify_db;
USE spotify_db;

-- 2 Crear la Tabla Limpia

CREATE TABLE staging_spotify (
    track_id VARCHAR(50),
    track_name TEXT,
    track_number INT,
    track_popularity INT,
    explicit TINYINT,
    artist_name VARCHAR(255),
    artist_popularity INT,
    artist_followers BIGINT,
    artist_genres TEXT,
    album_id VARCHAR(50),
    album_name TEXT,
    album_release_date DATE,
    album_total_tracks INT,
    album_type VARCHAR(50),
    track_duration_min DECIMAL(5,2)
);

-- 3. Carga Limpia... 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/spotify_data_clean.csv'
IGNORE INTO TABLE staging_spotify -- La palabra IGNORE aquí es la clave
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(track_id, track_name, track_number, track_popularity, @explicit_val, artist_name, @artist_pop_temp, @artist_foll_temp, @genres_val, album_id, album_name, @release_date_val, album_total_tracks, album_type, track_duration_min)
SET 
    explicit = IF(@explicit_val = 'TRUE', 1, 0),
    artist_genres = NULLIF(@genres_val, 'N/A'),
    album_release_date = @release_date_val,
    artist_popularity = CAST(NULLIF(TRIM(@artist_pop_temp), '') AS UNSIGNED),
    artist_followers = CAST(NULLIF(TRIM(@artist_foll_temp), '') AS UNSIGNED);
    
    -- Cuenta total de registros cargados
SELECT COUNT(*) AS total_registros FROM staging_spotify;





-- Revisa los últimos warnings generados por el LOAD DATA
SHOW WARNINGS;