

-- A. Vista Granular (El "Tablón Maestro")
CREATE OR REPLACE VIEW vw_spotify_master_detail AS
SELECT 
    f.track_key,
    t.track_name,
    t.track_number,
    t.explicit,
    ar.artist_name,
    ar.artist_genres,
    al.album_name,
    al.album_release_date,
    al.album_type,
    f.track_popularity,
    f.artist_popularity,
    f.artist_followers,
    f.track_duration_min
FROM fact_tracks f
INNER JOIN dim_track t  ON f.track_key = t.track_key
INNER JOIN dim_album al ON f.album_key = al.album_key
INNER JOIN dim_artist ar ON f.artist_key = ar.artist_key;


-- B. Vista Agregada (Rendimiento por Álbum)

CREATE OR REPLACE VIEW vw_album_performance AS
SELECT 
    al.album_name,
    al.album_type,
    COUNT(f.track_key) AS total_tracks_in_db,
    AVG(f.track_popularity) AS avg_track_popularity,
    SUM(f.track_duration_min) AS total_album_duration_min
FROM fact_tracks f
JOIN dim_album al ON f.album_key = al.album_key
GROUP BY al.album_name, al.album_type;

-- C. Vista de Segmentación (Ranking de Artistas)

CREATE OR REPLACE VIEW vw_artist_segmentation AS
SELECT 
    ar.artist_name,
    ar.artist_genres,
    MAX(f.artist_popularity) AS popularity_score,
    MAX(f.artist_followers) AS total_followers,
    COUNT(f.track_key) AS total_songs_catalog
FROM fact_tracks f
JOIN dim_artist ar ON f.artist_key = ar.artist_key
GROUP BY ar.artist_name, ar.artist_genres;

-- 1. Validación de Conteo: El total de la vista maestra debe ser igual a la Fact Table
SELECT 
    (SELECT COUNT(*) FROM fact_tracks) AS fact_count,
    (SELECT COUNT(*) FROM vw_spotify_master_detail) AS view_count;

-- 2. Validación de Duplicados en la Vista:
-- Si el resultado es > 0, hay un problema de granularidad.
SELECT track_name, artist_name, COUNT(*) 
FROM vw_spotify_master_detail
GROUP BY track_name, artist_name
HAVING COUNT(*) > 1;

-- 1. Cambiar la base de datos completa
ALTER DATABASE tu_nombre_de_bd CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 2. Cambiar cada una de tus tablas (Hazlo para las 4 dimensiones y la fact table)
ALTER TABLE dim_artist CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE dim_album CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE dim_track CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE fact_tracks CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE staging_spotify CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 1. Desactivar modo seguro y modo estricto de fechas
SET SQL_SAFE_UPDATES = 0;
SET sql_mode = '';

-- 2. Limpiar las fechas inválidas (Fila 1576 y similares)
UPDATE dim_album 
SET album_release_date = NULL 
WHERE album_release_date = '0000-00-00' OR album_release_date IS NULL;

-- 3. Ahora sí, aplicar el cambio de Charset para Power BI
ALTER TABLE dim_album CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 4. Restaurar la seguridad (Buena práctica)
SET SQL_SAFE_UPDATES = 1;
SET sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';


ALTER TABLE dim_album CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;