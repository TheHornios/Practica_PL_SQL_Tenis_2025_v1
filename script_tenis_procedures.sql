/*5.1 */
CREATE OR REPLACE PROCEDURE pAnularReserva(
    p_socio VARCHAR,
    p_fecha DATE,
    p_hora INTEGER,
    p_pista INTEGER
) IS
BEGIN
    DELETE FROM reservas
    WHERE trunc(fecha) = trunc(p_fecha)
      AND pista = p_pista
      AND hora = p_hora
      AND socio = p_socio;

    IF SQL%ROWCOUNT = 0 THEN
        raise_application_error(-20000, 'Reserva inexistente');
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE; -- Re-lanza la excepción original
END;
/

CREATE OR REPLACE PROCEDURE pReservarPista(
    p_socio VARCHAR,
    p_fecha DATE,
    p_hora INTEGER
) IS
    CURSOR vPistasLibres IS
        SELECT nro
        FROM pistas
        WHERE nro NOT IN (
            SELECT pista
            FROM reservas
            WHERE trunc(fecha) = trunc(p_fecha)
              AND hora = p_hora
        )
        ORDER BY nro;

    vPista INTEGER;
BEGIN
    OPEN vPistasLibres;
    FETCH vPistasLibres INTO vPista;

    IF vPistasLibres%NOTFOUND THEN
        CLOSE vPistasLibres;
        raise_application_error(-20001, 'No quedan pistas libres en esa fecha y hora');
    END IF;

    INSERT INTO reservas VALUES (vPista, p_fecha, p_hora, p_socio);
    CLOSE vPistasLibres;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        IF vPistasLibres%ISOPEN THEN
            CLOSE vPistasLibres;
        END IF;
        ROLLBACK;
        RAISE;
END;
/

/* PASO 5.2*/

CREATE OR REPLACE PROCEDURE TEST_PROCEDURES_TENIS
IS
BEGIN
    -- Pruebas de pReservarPista
    BEGIN
        pReservarPista('Socio 1', CURRENT_DATE, 12);
        DBMS_OUTPUT.PUT_LINE('Reserva 1: OK');
        pReservarPista('Socio 2', CURRENT_DATE, 12);
        DBMS_OUTPUT.PUT_LINE('Reserva 2: OK');
        pReservarPista('Socio 3', CURRENT_DATE, 12);
        DBMS_OUTPUT.PUT_LINE('Reserva 3: OK');
        pReservarPista('Socio 4', CURRENT_DATE, 12); -- Debería lanzar excepción
        DBMS_OUTPUT.PUT_LINE('Reserva 4: ERROR (No debería haberse reservado)');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Reserva 4: OK (No había hueco)');
    END;

    -- Pruebas de pAnularReserva
    BEGIN
        pAnularReserva('Socio 1', CURRENT_DATE, 12, 1);
        DBMS_OUTPUT.PUT_LINE('Anulación 1: OK (Reserva eliminada)');
        pAnularReserva('Socio 1', DATE '1920-1-1', 12, 1); -- Debería lanzar excepción
        DBMS_OUTPUT.PUT_LINE('Anulación 2: ERROR (No debería haberse eliminado)');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Anulación 2: OK (Reserva no existía)');
    END;

    -- Consulta final para verificar resultados
    EXECUTE IMMEDIATE 'SELECT * FROM reservas ORDER BY fecha, hora, pista';
END;
/

SET SERVEROUTPUT ON;
EXECUTE TEST_PROCEDURES_TENIS;


/*
    Paso 6: Discusión sobre transacciones concurrentes

    Problema:
    Si dos transacciones intentan reservar la última pista libre al mismo tiempo,
    ambas podrían pasar la verificación inicial de pistas libres, pero solo una
    debería poder completar la reserva. Esto se debe a que la verificación de pistas
    libres y la inserción de la reserva no son atómicas.

    Solución:
    Se puede utilizar la cláusula "FOR UPDATE" en el cursor vPistasLibres para bloquear
    las filas seleccionadas. Esto asegura que solo una transacción pueda obtener
    la última pista libre, evitando el problema de la reserva duplicada.
*/

CREATE OR REPLACE PROCEDURE pReservarPista(
    p_socio VARCHAR,
    p_fecha DATE,
    p_hora INTEGER
) IS
    CURSOR vPistasLibres IS
        SELECT nro
        FROM pistas
        WHERE nro NOT IN (
            SELECT pista
            FROM reservas
            WHERE trunc(fecha) = trunc(p_fecha)
              AND hora = p_hora
        )
        ORDER BY nro FOR UPDATE; -- Bloquea las filas seleccionadas

    vPista INTEGER;
BEGIN
    OPEN vPistasLibres;
    FETCH vPistasLibres INTO vPista;

    IF vPistasLibres%NOTFOUND THEN
        CLOSE vPistasLibres;
        raise_application_error(-20001, 'No quedan pistas libres en esa fecha y hora');
    END IF;

    INSERT INTO reservas VALUES (vPista, p_fecha, p_hora, p_socio);
    CLOSE vPistasLibres;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        IF vPistasLibres%ISOPEN THEN
            CLOSE vPistasLibres;
        END IF;
        ROLLBACK;
        RAISE;
END;
/