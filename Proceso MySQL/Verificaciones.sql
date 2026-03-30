
-- 1. Identificar cuántos artistas tienen nombres que parecen IDs (ej: 22 caracteres)
SELECT artist_name, COUNT(*) 
FROM dim_artist 
WHERE CHAR_LENGTH(artist_name) > 15 AND artist_name NOT LIKE '% %' -- Nombres largos sin espacios suelen ser IDs
GROUP BY artist_name;

-- 1. Desactivar modo seguro para esta sesión
SET SQL_SAFE_UPDATES = 0;

-- 2. Borrar de la tabla de hechos (fact_tracks) las canciones que apuntan a esos artistas basura
-- Esto evita que Power BI cree filas vacías o errores de relación
DELETE FROM fact_tracks 
WHERE artist_key IN (
    SELECT artist_key 
    FROM dim_artist 
    WHERE artist_name REGEXP '^[a-zA-Z0-9]{20,}$'
);

-- 3. Ahora sí, borrar los artistas con nombres de ID en la dimensión
DELETE FROM dim_artist 
WHERE artist_name REGEXP '^[a-zA-Z0-9]{20,}$';

-- 4. Reactivar modo seguro
SET SQL_SAFE_UPDATES = 1;

-- 5. Verificación final: ¿Llegamos a los 2,548?
SELECT COUNT(*) AS total_artistas_limpios FROM dim_artist;