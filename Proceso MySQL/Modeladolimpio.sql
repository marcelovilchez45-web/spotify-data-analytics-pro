-- Dimensión Artista (Corregida sin artist_id)
DROP TABLE IF EXISTS dim_artist;
CREATE TABLE dim_artist (
    artist_key INT AUTO_INCREMENT PRIMARY KEY,
    artist_name VARCHAR(255) NOT NULL,
    artist_genres TEXT,
    UNIQUE KEY (artist_name)
);

-- Dimensión Álbum
DROP TABLE IF EXISTS dim_album;
CREATE TABLE dim_album (
    album_key INT AUTO_INCREMENT PRIMARY KEY,
    album_id VARCHAR(50) UNIQUE,
    album_name VARCHAR(255),
    album_release_date DATE,
    album_type VARCHAR(50)
);

-- Dimensión Track
DROP TABLE IF EXISTS dim_track;
CREATE TABLE dim_track (
    track_key INT AUTO_INCREMENT PRIMARY KEY,
    track_id VARCHAR(50) UNIQUE,
    track_name VARCHAR(255),
    track_number INT,
    explicit TINYINT(1)
);

-- Tabla de Hechos (Métricas + Claves Foráneas)
DROP TABLE IF EXISTS fact_tracks;
CREATE TABLE fact_tracks (
    track_key INT,
    album_key INT,
    artist_key INT,
    track_popularity INT,
    artist_popularity INT,
    artist_followers BIGINT,
    album_total_tracks INT,
    track_duration_min DECIMAL(10,4),
    -- Relaciones
    FOREIGN KEY (track_key) REFERENCES dim_track(track_key),
    FOREIGN KEY (album_key) REFERENCES dim_album(album_key),
    FOREIGN KEY (artist_key) REFERENCES dim_artist(artist_key)
);


-- 1. Desactivar validación de llaves foráneas
SET FOREIGN_KEY_CHECKS = 0;

-- 2. Borrar tablas en cualquier orden (ahora sí te dejará)
DROP TABLE IF EXISTS fact_tracks;
DROP TABLE IF EXISTS dim_track;
DROP TABLE IF EXISTS dim_album;
DROP TABLE IF EXISTS dim_artist;

-- 3. Volver a activar la validación
SET FOREIGN_KEY_CHECKS = 1;

-- Poblar Artistas (Vínculo por nombre)
INSERT IGNORE INTO dim_artist (artist_name, artist_genres)
SELECT DISTINCT artist_name, artist_genres 
FROM staging_spotify 
WHERE artist_name IS NOT NULL;

-- Poblar Álbumes (Vínculo por album_id)
INSERT IGNORE INTO dim_album (album_id, album_name, album_release_date, album_type)
SELECT DISTINCT album_id, album_name, album_release_date, album_type 
FROM staging_spotify;

-- Poblar Tracks (Vínculo por track_id)
INSERT IGNORE INTO dim_track (track_id, track_name, track_number, explicit)
SELECT DISTINCT track_id, track_name, track_number, explicit 
FROM staging_spotify;

INSERT INTO fact_tracks (
    track_key, 
    album_key, 
    artist_key, 
    track_popularity, 
    artist_popularity, 
    artist_followers, 
    album_total_tracks, 
    track_duration_min
)
SELECT 
    t.track_key,
    al.album_key,
    ar.artist_key,
    s.track_popularity,
    s.artist_popularity,
    s.artist_followers,
    s.album_total_tracks,
    s.track_duration_min
FROM staging_spotify s
INNER JOIN dim_track t  ON s.track_id = t.track_id
INNER JOIN dim_album al ON s.album_id = al.album_id
INNER JOIN dim_artist ar ON s.artist_name = ar.artist_name;

-- Auditoria
SELECT 
    (SELECT COUNT(*) FROM staging_spotify) AS origen,
    (SELECT COUNT(*) FROM fact_tracks) AS destino;
    
    
SELECT COUNT(*) FROM fact_tracks 
WHERE track_key IS NULL OR album_key IS NULL OR artist_key IS NULL;    

SELECT s.track_id, s.track_name, s.artist_name, s.album_name
FROM staging_spotify s
LEFT JOIN fact_tracks f ON s.track_id = (SELECT d.track_id FROM dim_track d WHERE d.track_key = f.track_key)
WHERE f.track_key IS NULL;