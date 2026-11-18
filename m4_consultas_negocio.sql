USE ventas_tech_db
GO

--LLAMAR ARCHIVO  m4_consultas_negocio --

--Consulta 1. Resumen Ejecutivo Mensual -- 
	-- Total facturado, cantidad de pedidos y ticket promedio, todo agrupado por mes.

SELECT 
	SUM(cantidad * precio_unitario) AS Total_facturado,
	COUNT(id_venta) AS Cantidad_pedidos, --USAR id_venta en vez de COUNT(*) para que no tome NULLs en el caso de que existan.
	CAST(AVG(cantidad * precio_unitario) AS DECIMAL(10,2)) 
		AS Ticket_promedio,-- LIMITO CON DECIMAL.RESUELVO EL CALCULO DE AVG CON LAS COLUMNAS Y NO CON EL ALIAS.
	MONTH(fecha_venta) AS Mes,
	YEAR(fecha_venta) AS Año --AUNQUE ES SOLO 2024, SIRVE PARA EL FUTURO YA TENERLO DIFERENCIADO POR AÑOS.
FROM ventas
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY Año, Mes; --A FUTURO HACE QUE SE VEA EN ORDEN


-- Consulta 2. Ranking de productos --

SELECT TOP 5 id_producto, -- Pide el top 5
		SUM(cantidad * precio_unitario) AS total_facturado, --estas columnas las uso para crear el total facturado
		SUM(cantidad) AS unidades_vendidas -- este calculo es para las unidades vendidas
FROM ventas
GROUP BY id_producto -- pide agrupar por id_producto
ORDER BY total_facturado DESC; -- lo ordeno por el total facturado de mayor a menor.

--Consulta 3. Clientes Recurrentes --
SELECT	id_cliente,
		COUNT(id_venta) AS cantidad_pedidos, --Muestra la cantidad de pedidos
		SUM(cantidad * precio_unitario) AS total_gastado -- muestra el total gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(id_venta) > 1 -- filtra por mas de 1 pedido por cliente
ORDER BY cantidad_pedidos DESC; --ordena por cantidad de pedidos de mayor a menor

-- Consulta 4. Productos por encima/por debajo del promedio --
-- Agrupamos por id_producto porque la consigna pide el rendimiento del catálogo.

WITH ventas_por_producto AS (
    SELECT 
        id_producto, 
        SUM(cantidad * precio_unitario) AS total_producto
    FROM ventas
    WHERE id_producto IS NOT NULL
    GROUP BY id_producto
) -- cuenta auiliar: calcula la facturación total acumulada de cada producto, no se genera una tabal en la BD.

SELECT 
    id_producto,
    total_producto,
    CASE
        WHEN total_producto >= (SELECT AVG(total_producto) FROM ventas_por_producto) --aca esta calculando sobre la tabla auxiliar
            THEN 'Por encima' 
        ELSE 'Por debajo'
    END AS comparacion_promedio
FROM ventas_por_producto
ORDER BY total_producto DESC;

-- BLOQUE DE CIERRE: 3 HALLAZGOS DE NEGOCIO (RetailPro)
--1. Concentración de ventas: El ranking de productos muestra que el Top 5 de productos concentra 
--una porción significativa de la facturación total del mes. 
--2. Fidelización: Se detectaron clientes recurrentes con más de una compra, lo que representa una base inicial 
-- de fidelización para campañas comerciales.
--3. Rendimiento del catálogo: La consulta 4 segmenta claramente qué artículos superan el promedio de facturación, 
--identificando los productos estrella frente a los que requieren rotación o revisión de precio.
